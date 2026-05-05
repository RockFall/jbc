import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:typed_data';

import 'package:mime/mime.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../core/notifications/jbc_notification_module.dart';
import '../../core/notifications/jbc_notification_types.dart';
import '../../core/piaditas/inside_joke_body.dart';
import '../../core/moment_emotion/moment_sticker_catalog.dart';
import '../../core/notifications/moment_emotion_notification_coalescer.dart';
import '../../core/notifications/timeline_edit_notification_coalescer.dart';
import '../../core/continhas/continhas_balance.dart';
import '../../core/continhas/continhas_money.dart';
import '../../core/continhas/continhas_netting.dart';
import '../../core/continhas/continhas_participant_key.dart';
import '../../core/profile/jbc_profile.dart';
import '../models/availability.dart';
import '../models/conchinha_acceptance.dart';
import '../models/conchinha_address.dart';
import '../models/conchinha_match_models.dart';
import '../models/conchinha_request.dart';
import '../models/continhas_expense.dart';
import '../models/continhas_guest.dart';
import '../models/continhas_hangout_state.dart';
import '../models/hangout.dart';
import '../models/inside_joke.dart';
import '../models/jbc_cash_ledger_entry.dart';
import '../models/idea.dart';
import '../models/jbc_app_notification.dart';
import '../models/moment_emotion.dart';
import '../models/timeline_event.dart';
import '../models/timeline_event_comment.dart';
import '../models/timeline_event_reaction.dart';
import 'jbc_repository.dart';
import 'timeline_storage_paths.dart';

class SupabaseRepository implements JbcRepository {
  SupabaseRepository(this._client);

  final SupabaseClient _client;
  final _uuid = const Uuid();

  late final TimelineEditNotificationCoalescer _timelineEditCoalescer =
      TimelineEditNotificationCoalescer(
    onFlush: (timelineEventId, actor, delta) => _flushTimelineEditNotification(
      timelineEventId: timelineEventId,
      actor: actor,
      delta: delta,
    ),
  );

  late final MomentEmotionNotificationCoalescer _momentEmotionCoalescer =
      MomentEmotionNotificationCoalescer(
    onFlush: (actor) => _flushMomentEmotionNotification(actor),
  );

  @override
  Stream<List<TimelineEvent>> watchTimelineEvents() {
    return _client
        .from('timeline_events')
        .stream(primaryKey: ['id'])
        .map((rows) {
          final list = rows.map(TimelineEvent.fromRow).toList()
            ..sort((a, b) => a.occurredAt.compareTo(b.occurredAt));
          return list;
        });
  }

  @override
  Stream<List<TimelineEventComment>> watchTimelineEventComments(
    String timelineEventId,
  ) {
    return _client
        .from('timeline_event_comments')
        .stream(primaryKey: ['id'])
        .map((rows) {
          final list = rows
              .where((r) => r['timeline_event_id'] == timelineEventId)
              .map(TimelineEventComment.fromRow)
              .toList()
            ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
          return list;
        });
  }

  @override
  Stream<List<TimelineEventReaction>> watchTimelineEventReactions(String timelineEventId) {
    return _client.from('timeline_event_reactions').stream(primaryKey: ['id']).map((rows) {
      final list = rows
          .where((r) => r['timeline_event_id'] == timelineEventId)
          .map(TimelineEventReaction.fromRow)
          .toList()
        ..sort((a, b) => a.profile.compareTo(b.profile));
      return list;
    });
  }

  @override
  Future<void> upsertTimelineEventReaction({
    required String timelineEventId,
    required JbcProfile profile,
    required String emoji,
  }) async {
    final trimmed = emoji.trim();
    if (trimmed.isEmpty) return;
    final now = DateTime.now().toUtc();
    await _client.from('timeline_event_reactions').upsert(
      {
        'timeline_event_id': timelineEventId,
        'profile': profile.storageKey,
        'emoji': trimmed,
        'updated_at': now.toIso8601String(),
      },
      onConflict: 'timeline_event_id,profile',
    );
  }

  @override
  Future<void> addTimelineEventComment({
    required String timelineEventId,
    required JbcProfile author,
    required String body,
  }) async {
    final trimmed = body.trim();
    if (trimmed.isEmpty) return;
    final now = DateTime.now().toUtc();
    await _client.from('timeline_event_comments').insert({
      'id': _uuid.v4(),
      'timeline_event_id': timelineEventId,
      'author': author.storageKey,
      'body': trimmed,
      'created_at': now.toIso8601String(),
    });
    await emitAppNotification(
      module: JbcNotificationModule.timeline,
      actor: author,
      eventType: JbcNotificationTypes.timelineComment,
      title: '${author.displayName} comentou numa memória.',
      body: trimmed.length > 120 ? '${trimmed.substring(0, 120)}…' : trimmed,
      entityId: timelineEventId,
      payload: {'timeline_event_id': timelineEventId},
      requestPushBroadcast: true,
      pushTitle: 'Comentário na memória',
      pushBody: trimmed.length > 120 ? '${trimmed.substring(0, 120)}…' : trimmed,
    );
  }

  @override
  Future<void> deleteTimelineEventComment({
    required TimelineEventComment comment,
    required JbcProfile deletedBy,
  }) async {
    if (comment.author != deletedBy.storageKey) {
      throw StateError('Só é possível apagar o próprio comentário.');
    }
    await _client.from('timeline_event_comments').delete().eq('id', comment.id);
  }

  @override
  Future<void> createManualTimelineEvent({
    required JbcProfile profile,
    required DateTime occurredAt,
    required String title,
    required String description,
    List<TimelineImageInput> images = const [],
    int primaryImageIndex = 0,
  }) async {
    final id = _uuid.v4();
    final now = DateTime.now().toUtc();
    final urls = await _resolveTimelineImageUrls(eventId: id, inputs: images);
    final p = _clampPrimaryIndex(primaryImageIndex, urls.length);
    final cover = urls.isEmpty ? null : urls[p];
    await _client.from('timeline_events').insert({
      'id': id,
      'occurred_at': occurredAt.toUtc().toIso8601String(),
      'title': title,
      'description': description,
      'image_url': cover,
      'image_urls': urls,
      'primary_image_index': p,
      'created_by': profile.storageKey,
      'origin': 'manual',
      'hangout_id': null,
      'created_at': now.toIso8601String(),
      'updated_at': now.toIso8601String(),
    });
    await emitAppNotification(
      module: JbcNotificationModule.timeline,
      actor: profile,
      eventType: JbcNotificationTypes.timelineNew,
      title: '${profile.displayName} adicionou uma memória: $title',
      entityId: id,
      payload: {'timeline_event_id': id},
      requestPushBroadcast: true,
      pushTitle: 'Nova memória',
      pushBody: title,
    );
  }

  @override
  Future<void> updateTimelineEvent({
    required JbcProfile updatedBy,
    required TimelineEvent existing,
    required DateTime occurredAt,
    required String title,
    required String description,
    required List<TimelineImageInput> images,
    required int primaryImageIndex,
  }) async {
    final now = DateTime.now().toUtc();
    final urls = await _resolveTimelineImageUrls(
      eventId: existing.id,
      inputs: images,
    );
    final p = _clampPrimaryIndex(primaryImageIndex, urls.length);
    final cover = urls.isEmpty ? null : urls[p];
    await _removeOrphanTimelineImages(
      previous: existing.imageUrls,
      kept: urls,
    );
    await _client.from('timeline_events').update({
      'occurred_at': occurredAt.toUtc().toIso8601String(),
      'title': title,
      'description': description,
      'image_url': cover,
      'image_urls': urls,
      'primary_image_index': p,
      'updated_at': now.toIso8601String(),
    }).eq('id', existing.id);

    final delta = _timelineEditDelta(
      existing: existing,
      occurredAt: occurredAt,
      title: title,
      description: description,
      newImageUrls: urls,
    );
    _timelineEditCoalescer.schedule(
      timelineEventId: existing.id,
      actor: updatedBy,
      delta: delta,
    );
  }

  @override
  Future<void> deleteTimelineEvent(TimelineEvent event) async {
    for (final u in event.imageUrls) {
      await _deleteTimelineImageIfExists(u);
    }
    await _client.from('timeline_events').delete().eq('id', event.id);
  }

  int _clampPrimaryIndex(int primary, int length) {
    if (length <= 0) return 0;
    if (primary < 0) return 0;
    if (primary >= length) return length - 1;
    return primary;
  }

  Future<List<String>> _resolveTimelineImageUrls({
    required String eventId,
    required List<TimelineImageInput> inputs,
  }) async {
    final out = <String>[];
    for (final input in inputs) {
      final url = input.existingPublicUrl?.trim();
      if (url != null && url.isNotEmpty) {
        out.add(url);
      } else if (input.isUpload) {
        final ext = (input.fileExtension ?? 'jpg').toLowerCase();
        final uploaded = await _uploadTimelineImage(
          eventId,
          input.bytes!,
          ext,
        );
        out.add(uploaded);
      }
    }
    return out;
  }

  Future<void> _removeOrphanTimelineImages({
    required List<String> previous,
    required List<String> kept,
  }) async {
    for (final u in previous) {
      if (!kept.contains(u)) {
        await _deleteTimelineImageIfExists(u);
      }
    }
  }

  Future<String> _uploadTimelineImage(
    String eventId,
    List<int> bytes,
    String ext,
  ) async {
    final objectId = _uuid.v4();
    final path = timelineImageObjectPath(eventId, objectId, ext);
    final contentType = lookupMimeType('file.$ext') ?? 'image/jpeg';
    await _client.storage.from(kTimelineImagesBucket).uploadBinary(
          path,
          Uint8List.fromList(bytes),
          fileOptions: FileOptions(
            contentType: contentType,
            upsert: false,
          ),
        );
    return _client.storage.from(kTimelineImagesBucket).getPublicUrl(path);
  }

  Future<void> _deleteTimelineImageIfExists(String? publicUrl) async {
    if (publicUrl == null || publicUrl.isEmpty) return;
    final path = storagePathFromPublicUrl(publicUrl);
    if (path == null) return;
    try {
      await _client.storage.from(kTimelineImagesBucket).remove([path]);
    } catch (_) {
      // Arquivo ausente ou path legado: segue com update/delete da linha.
    }
  }

  @override
  Stream<List<Hangout>> watchHangouts() {
    return _client
        .from('hangouts')
        .stream(primaryKey: ['id'])
        .map((rows) {
          final list = rows.map(Hangout.fromRow).toList()
            ..sort((a, b) {
              final c = a.date.compareTo(b.date);
              if (c != 0) return c;
              return a.startTime.compareTo(b.startTime);
            });
          return list;
        });
  }

  @override
  Stream<List<Availability>> watchAvailabilities() {
    return _client
        .from('availabilities')
        .stream(primaryKey: ['id'])
        .map((rows) {
          final list = rows.map(Availability.fromRow).toList()
            ..sort((a, b) {
              final c = a.weekday.compareTo(b.weekday);
              if (c != 0) return c;
              final p = a.person.compareTo(b.person);
              if (p != 0) return p;
              return a.startTime.compareTo(b.startTime);
            });
          return list;
        });
  }

  @override
  Future<void> createAvailability({
    required JbcProfile profile,
    required int weekday,
    required String startTime,
    required String endTime,
    String? title,
  }) async {
    final t = title?.trim();
    await _client.from('availabilities').insert({
      'id': _uuid.v4(),
      'person': profile.storageKey,
      'weekday': weekday,
      'start_time': startTime,
      'end_time': endTime,
      if (t != null && t.isNotEmpty) 'title': t,
    });
  }

  @override
  Future<void> updateAvailability({
    required Availability existing,
    required JbcProfile profile,
    required int weekday,
    required String startTime,
    required String endTime,
    String? title,
  }) async {
    if (existing.person != profile.storageKey) {
      throw StateError('Só é possível editar as suas indisponibilidades.');
    }
    final t = title?.trim();
    await _client.from('availabilities').update({
      'weekday': weekday,
      'start_time': startTime,
      'end_time': endTime,
      'title': (t == null || t.isEmpty) ? null : t,
    }).eq('id', existing.id);
  }

  @override
  Future<void> deleteAvailability({
    required Availability existing,
    required JbcProfile profile,
  }) async {
    if (existing.person != profile.storageKey) {
      throw StateError('Só é possível excluir as suas indisponibilidades.');
    }
    await _client.from('availabilities').delete().eq('id', existing.id);
  }

  @override
  Future<void> createHangout({
    required JbcProfile profile,
    required String title,
    String? description,
    required DateTime date,
    required String startTime,
    String? endTime,
    String? notes,
  }) async {
    final now = DateTime.now().toUtc();
    final dateStr =
        DateTime(date.year, date.month, date.day).toIso8601String().split('T').first;
    final hid = _uuid.v4();
    await _client.from('hangouts').insert({
      'id': hid,
      'title': title,
      'description': description,
      'date': dateStr,
      'start_time': startTime,
      'end_time': endTime,
      'status': 'planned',
      'created_by': profile.storageKey,
      'notes': notes,
      'created_at': now.toIso8601String(),
      'updated_at': now.toIso8601String(),
    });
    await emitAppNotification(
      module: JbcNotificationModule.hangouts,
      actor: profile,
      eventType: JbcNotificationTypes.hangoutNew,
      title: '${profile.displayName} criou um rolê: $title',
      entityId: hid,
      payload: {'hangout_id': hid},
      requestPushBroadcast: true,
      pushTitle: 'Novo rolê',
      pushBody: title,
    );
  }

  @override
  Future<void> updateHangout({
    required JbcProfile updatedBy,
    required Hangout existing,
    required String title,
    String? description,
    required DateTime date,
    required String startTime,
    String? endTime,
    String? notes,
  }) async {
    final now = DateTime.now().toUtc();
    final dateStr =
        DateTime(date.year, date.month, date.day).toIso8601String().split('T').first;
    await _client.from('hangouts').update({
      'title': title,
      'description': description,
      'date': dateStr,
      'start_time': startTime,
      'end_time': endTime,
      'notes': notes,
      'updated_at': now.toIso8601String(),
    }).eq('id', existing.id);
    await emitAppNotification(
      module: JbcNotificationModule.hangouts,
      actor: updatedBy,
      eventType: JbcNotificationTypes.hangoutUpdated,
      title: '${updatedBy.displayName} atualizou o rolê “${existing.title}”.',
      entityId: existing.id,
      payload: {'hangout_id': existing.id},
      requestPushBroadcast: true,
      pushTitle: 'Rolê atualizado',
      pushBody: existing.title,
    );
  }

  @override
  Future<void> updateHangoutStatus({
    required JbcProfile updatedBy,
    required Hangout existing,
    required HangoutStatus status,
  }) async {
    final now = DateTime.now().toUtc();
    await _client.from('hangouts').update({
      'status': status.dbValue,
      'updated_at': now.toIso8601String(),
    }).eq('id', existing.id);
    final label = switch (status) {
      HangoutStatus.planned => 'voltou a planejado',
      HangoutStatus.happened => 'marcou como aconteceu',
      HangoutStatus.cancelled => 'cancelou',
    };
    await emitAppNotification(
      module: JbcNotificationModule.hangouts,
      actor: updatedBy,
      eventType: JbcNotificationTypes.hangoutStatus,
      title: '${updatedBy.displayName} $label o rolê “${existing.title}”.',
      entityId: existing.id,
      payload: {'hangout_id': existing.id, 'status': status.dbValue},
      requestPushBroadcast: true,
      pushTitle: 'Rolê',
      pushBody: '${existing.title} — $label',
    );
  }

  @override
  Future<void> createTimelineFromHangout({
    required Hangout hangout,
    required JbcProfile profile,
    required DateTime occurredAt,
    required String title,
    required String description,
    List<TimelineImageInput> images = const [],
    int primaryImageIndex = 0,
  }) async {
    if (hangout.status != HangoutStatus.happened) {
      throw StateError('Marque o rolê como aconteceu antes de registrar a memória.');
    }
    if (hangout.timelineEventId != null && hangout.timelineEventId!.isNotEmpty) {
      throw StateError('Este rolê já foi registrado na timeline.');
    }
    final eventId = _uuid.v4();
    final now = DateTime.now().toUtc();
    final urls = await _resolveTimelineImageUrls(eventId: eventId, inputs: images);
    final p = _clampPrimaryIndex(primaryImageIndex, urls.length);
    final cover = urls.isEmpty ? null : urls[p];
    await _client.from('timeline_events').insert({
      'id': eventId,
      'occurred_at': occurredAt.toUtc().toIso8601String(),
      'title': title,
      'description': description,
      'image_url': cover,
      'image_urls': urls,
      'primary_image_index': p,
      'created_by': profile.storageKey,
      'origin': 'from_hangout',
      'hangout_id': hangout.id,
      'created_at': now.toIso8601String(),
      'updated_at': now.toIso8601String(),
    });
    await _client.from('hangouts').update({
      'timeline_event_id': eventId,
      'updated_at': now.toIso8601String(),
    }).eq('id', hangout.id);
    await emitAppNotification(
      module: JbcNotificationModule.timeline,
      actor: profile,
      eventType: JbcNotificationTypes.timelineNew,
      title: '${profile.displayName} registrou uma memória do rolê: $title',
      entityId: eventId,
      payload: {'timeline_event_id': eventId, 'hangout_id': hangout.id},
      requestPushBroadcast: true,
      pushTitle: 'Nova memória',
      pushBody: title,
    );
  }

  @override
  Stream<List<Idea>> watchIdeas() {
    return _client
        .from('ideas')
        .stream(primaryKey: ['id'])
        .map((rows) {
          final list = rows.map(Idea.fromRow).toList()
            ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
          return list;
        });
  }

  @override
  Future<void> createIdea({
    required JbcProfile profile,
    required String title,
    String? description,
    IdeaCategory? category,
  }) async {
    final now = DateTime.now().toUtc();
    final ideaId = _uuid.v4();
    await _client.from('ideas').insert({
      'id': ideaId,
      'title': title,
      'description': description,
      'category': category?.dbValue,
      'status': 'active',
      'created_by': profile.storageKey,
      'created_at': now.toIso8601String(),
      'updated_at': now.toIso8601String(),
    });
    await emitAppNotification(
      module: JbcNotificationModule.ideas,
      actor: profile,
      eventType: JbcNotificationTypes.ideaNew,
      title: '${profile.displayName} adicionou uma ideia: $title',
      entityId: ideaId,
      payload: {'idea_id': ideaId},
      requestPushBroadcast: true,
      pushTitle: 'Nova ideia',
      pushBody: title,
    );
  }

  @override
  Future<void> updateIdea({
    required JbcProfile updatedBy,
    required Idea existing,
    required String title,
    String? description,
    IdeaCategory? category,
  }) async {
    final now = DateTime.now().toUtc();
    await _client.from('ideas').update({
      'title': title,
      'description': description,
      'category': category?.dbValue,
      'updated_at': now.toIso8601String(),
    }).eq('id', existing.id);
    await emitAppNotification(
      module: JbcNotificationModule.ideas,
      actor: updatedBy,
      eventType: JbcNotificationTypes.ideaUpdated,
      title: '${updatedBy.displayName} editou a ideia “${existing.title}”.',
      entityId: existing.id,
      payload: {'idea_id': existing.id},
      requestPushBroadcast: true,
      pushTitle: 'Ideia atualizada',
      pushBody: existing.title,
    );
  }

  @override
  Future<void> updateIdeaStatus({
    required Idea existing,
    required IdeaStatus status,
    JbcProfile? archivedBy,
    JbcProfile? notificationActor,
  }) async {
    final now = DateTime.now().toUtc();
    final archivedKey =
        status == IdeaStatus.archived ? archivedBy?.storageKey : null;
    await _client.from('ideas').update({
      'status': status.dbValue,
      'archived_by': archivedKey,
      'updated_at': now.toIso8601String(),
    }).eq('id', existing.id);
    final actor = notificationActor;
    if (actor != null) {
      final statusPt = switch (status) {
        IdeaStatus.active => 'reativou',
        IdeaStatus.done => 'marcou como realizada',
        IdeaStatus.archived => 'arquivou',
      };
      await emitAppNotification(
        module: JbcNotificationModule.ideas,
        actor: actor,
        eventType: JbcNotificationTypes.ideaStatus,
        title: '${actor.displayName} $statusPt a ideia “${existing.title}”.',
        entityId: existing.id,
        payload: {'idea_id': existing.id, 'status': status.dbValue},
        requestPushBroadcast: true,
        pushTitle: 'Ideia',
        pushBody: '${existing.title} — $statusPt',
      );
    }
  }

  @override
  Future<void> clearAllRemoteData() async {
    const epoch = '1970-01-01T00:00:00Z';
    await _client.from('timeline_event_comments').delete().gte('created_at', epoch);
    await _client.from('timeline_event_reactions').delete().gte('updated_at', epoch);
    await _client.from('timeline_events').delete().gte('created_at', epoch);
    await _client.from('continhas_expense').delete().gte('created_at', epoch);
    await _client.from('jbc_cash_ledger').delete().gte('created_at', epoch);
    await _client.from('continhas_hangout').delete().or('status.eq.open,status.eq.closed');
    await _client.from('continhas_guest').delete().gte('created_at', epoch);
    await _client.from('hangouts').delete().gte('created_at', epoch);
    await _client.from('ideas').delete().gte('created_at', epoch);
    await _client.from('availabilities').delete().gte('weekday', 1);
    await _client.from('inside_jokes').delete().gte('created_at', epoch);
    await _client.from('moment_emotions').delete().gte('updated_at', epoch);
    await _client.from('conchinha_requests').delete().gte('created_at', epoch);
    await _client.from('conchinha_search_pool').delete().gte('created_at', epoch);
    await _client.from('conchinha_match_state').update({
      'tier': 'idle',
      'dual_notified': false,
      'supreme_notified': false,
      'wave_id': _uuid.v4(),
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', 'singleton');
    await _client.from('jbc_notifications').delete().gte('created_at', epoch);
    await _client.from('fcm_device_tokens').delete().gte('updated_at', epoch);
  }

  @override
  Future<void> importTimelineEventsFromJson({
    required JbcProfile profile,
    required String json,
  }) async {
    final decoded = jsonDecode(json);
    if (decoded is! List) {
      throw FormatException('JSON da timeline deve ser uma lista.');
    }
    for (final raw in decoded) {
      if (raw is! Map) continue;
      final m = Map<String, dynamic>.from(raw);
      final dateStr = m['date'] as String?;
      final title = (m['title'] as String?)?.trim() ?? '';
      if (dateStr == null || dateStr.isEmpty) continue;
      final desc = (m['description'] as String?) ?? '';
      final d = DateTime.tryParse('${dateStr}T12:00:00');
      if (d == null) continue;
      await createManualTimelineEvent(
        profile: profile,
        occurredAt: d,
        title: title.isEmpty ? '(sem título)' : title,
        description: desc,
      );
    }
  }

  @override
  Future<void> deleteIdea(Idea idea) async {
    await _client.from('ideas').delete().eq('id', idea.id);
  }

  @override
  Future<void> insertSampleTimelineEvent(JbcProfile profile) async {
    final now = DateTime.now().toUtc();
    await _client.from('timeline_events').insert({
      'id': _uuid.v4(),
      'occurred_at': now.toIso8601String(),
      'title': 'Memória de exemplo',
      'description': 'Adicionada para testar a sincronização.',
      'image_urls': <String>[],
      'primary_image_index': 0,
      'created_by': profile.storageKey,
      'origin': 'manual',
      'created_at': now.toIso8601String(),
      'updated_at': now.toIso8601String(),
    });
  }

  @override
  Future<void> insertSampleHangout(JbcProfile profile) async {
    final now = DateTime.now().toUtc();
    final day = DateTime(now.year, now.month, now.day);
    await _client.from('hangouts').insert({
      'id': _uuid.v4(),
      'title': 'Rolê de exemplo',
      'description': 'Planejamento de teste.',
      'date': day.toIso8601String().split('T').first,
      'start_time': '18:00',
      'end_time': '22:00',
      'status': 'planned',
      'created_by': profile.storageKey,
      'created_at': now.toIso8601String(),
      'updated_at': now.toIso8601String(),
    });
  }

  @override
  Future<void> insertSampleAvailability(JbcProfile profile) async {
    await _client.from('availabilities').insert({
      'id': _uuid.v4(),
      'person': profile.storageKey,
      'weekday': DateTime.now().weekday,
      'start_time': '09:00',
      'end_time': '12:00',
    });
  }

  @override
  Future<void> insertSampleIdea(JbcProfile profile) async {
    final now = DateTime.now().toUtc();
    await _client.from('ideas').insert({
      'id': _uuid.v4(),
      'title': 'Ideia de exemplo',
      'description': 'Uma sugestão para o futuro.',
      'category': 'other',
      'status': 'active',
      'created_by': profile.storageKey,
      'created_at': now.toIso8601String(),
      'updated_at': now.toIso8601String(),
    });
  }

  // —— Conchinha (Epic 12) ——

  String _conchinhaShortPlace(String label) {
    final t = label.trim();
    if (t.isEmpty) return 'um lugar a definir';
    final comma = t.indexOf(',');
    final head = comma == -1 ? t : t.substring(0, comma).trim();
    if (head.length <= 52) return head;
    return '${head.substring(0, 49)}…';
  }

  @override
  Stream<List<ConchinhaRequest>> watchConchinhaRequests() {
    return _client.from('conchinha_requests').stream(primaryKey: ['id']).map((rows) {
      final list = rows.map(ConchinhaRequest.fromRow).toList()
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return list;
    });
  }

  @override
  Stream<ConchinhaRequest?> watchConchinhaRequest(String requestId) {
    return _client.from('conchinha_requests').stream(primaryKey: ['id']).map((rows) {
      for (final r in rows) {
        if (r['id'] == requestId) return ConchinhaRequest.fromRow(Map<String, dynamic>.from(r));
      }
      return null;
    });
  }

  @override
  Stream<List<ConchinhaAcceptance>> watchConchinhaAcceptances(String requestId) {
    return _client.from('conchinha_acceptances').stream(primaryKey: ['id']).map((rows) {
      final list = rows
          .where((r) => r['request_id'] == requestId)
          .map((r) => ConchinhaAcceptance.fromRow(Map<String, dynamic>.from(r)))
          .toList()
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
      return list;
    });
  }

  @override
  Future<String> createConchinhaRequest({
    required JbcProfile requester,
    required ConchinhaAddress address,
  }) async {
    final trimmed = address.label.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('Informe um endereço ou uma descrição do lugar.');
    }
    final now = DateTime.now().toUtc();
    final id = _uuid.v4();
    try {
      await _client.from('conchinha_requests').insert({
        'id': id,
        'requester': requester.storageKey,
        'address': {
          ...address.toJson(),
          'label': trimmed,
        },
        'status': 'open',
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      });
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        throw StateError('Você já tem um pedido de conchinha aberto.');
      }
      rethrow;
    }
    final place = _conchinhaShortPlace(trimmed);
    await emitAppNotification(
      module: JbcNotificationModule.conchinha,
      actor: requester,
      eventType: JbcNotificationTypes.conchinhaRequestCreated,
      title: '${requester.displayName} pediu conchinha em $place',
      body: trimmed.length > 160 ? '${trimmed.substring(0, 160)}…' : trimmed,
      entityId: id,
      payload: {
        'conchinha_request_id': id,
        'address_label': trimmed,
        if (address.lat != null) 'lat': address.lat,
        if (address.lng != null) 'lng': address.lng,
      },
      requestPushBroadcast: true,
      pushTitle: 'Conchinha',
      pushBody: '${requester.displayName} — $place',
      pushData: {
        'event_type': JbcNotificationTypes.conchinhaRequestCreated,
        'conchinha_request_id': id,
      },
    );
    return id;
  }

  @override
  Future<void> acceptConchinhaRequest({
    required String requestId,
    required JbcProfile profile,
  }) async {
    final row = await _client.from('conchinha_requests').select().eq('id', requestId).maybeSingle();
    if (row == null) throw ArgumentError('Pedido não encontrado.');
    if (row['requester'] == profile.storageKey) {
      throw StateError('Você não pode aceitar o próprio pedido.');
    }
    if (row['status'] != 'open') {
      throw StateError('Este pedido não está mais aberto.');
    }
    final now = DateTime.now().toUtc();
    try {
      await _client.from('conchinha_acceptances').insert({
        'id': _uuid.v4(),
        'request_id': requestId,
        'profile': profile.storageKey,
        'created_at': now.toIso8601String(),
      });
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        throw StateError('Você já tinha aceito este pedido.');
      }
      rethrow;
    }
    await emitAppNotification(
      module: JbcNotificationModule.conchinha,
      actor: profile,
      eventType: JbcNotificationTypes.conchinhaRequestAccepted,
      title: '${profile.displayName} aceitou a conchinha que você pediu.',
      entityId: requestId,
      payload: {'conchinha_request_id': requestId},
      requestPushBroadcast: true,
      pushTitle: 'Conchinha aceita',
      pushBody: '${profile.displayName} aceitou seu pedido.',
      pushData: {
        'event_type': JbcNotificationTypes.conchinhaRequestAccepted,
        'conchinha_request_id': requestId,
      },
    );
  }

  @override
  Future<void> cancelConchinhaRequest({
    required String requestId,
    required JbcProfile requester,
  }) async {
    final row = await _client.from('conchinha_requests').select().eq('id', requestId).maybeSingle();
    if (row == null) return;
    if (row['requester'] != requester.storageKey) {
      throw StateError('Só quem fez o pedido pode cancelar.');
    }
    if (row['status'] != 'open') return;
    final addrRaw = row['address'];
    final addr = addrRaw is Map
        ? ConchinhaAddress.fromJson(Map<String, dynamic>.from(addrRaw))
        : const ConchinhaAddress(label: '');
    final place = _conchinhaShortPlace(addr.label);
    await _client.from('conchinha_acceptances').delete().eq('request_id', requestId);
    final now = DateTime.now().toUtc();
    await _client.from('conchinha_requests').update({
      'status': 'cancelled',
      'updated_at': now.toIso8601String(),
    }).eq('id', requestId);
    await emitAppNotification(
      module: JbcNotificationModule.conchinha,
      actor: requester,
      eventType: JbcNotificationTypes.conchinhaRequestCancelled,
      title: '${requester.displayName} cancelou o pedido de conchinha ($place).',
      entityId: requestId,
      payload: {'conchinha_request_id': requestId},
      requestPushBroadcast: true,
      pushTitle: 'Conchinha cancelada',
      pushBody: '$place — pedido cancelado.',
      pushData: {
        'event_type': JbcNotificationTypes.conchinhaRequestCancelled,
        'conchinha_request_id': requestId,
      },
    );
  }

  @override
  Future<void> completeConchinhaRequest({
    required String requestId,
    required JbcProfile requester,
  }) async {
    final row = await _client.from('conchinha_requests').select().eq('id', requestId).maybeSingle();
    if (row == null) return;
    if (row['requester'] != requester.storageKey) {
      throw StateError('Só quem fez o pedido pode concluir.');
    }
    if (row['status'] != 'open') return;
    final now = DateTime.now().toUtc();
    await _client.from('conchinha_requests').update({
      'status': 'completed',
      'updated_at': now.toIso8601String(),
    }).eq('id', requestId);
    await emitAppNotification(
      module: JbcNotificationModule.conchinha,
      actor: requester,
      eventType: JbcNotificationTypes.conchinhaRequestCompleted,
      title: '${requester.displayName} concluiu o pedido de conchinha.',
      entityId: requestId,
      payload: {'conchinha_request_id': requestId},
      requestPushBroadcast: true,
      pushTitle: 'Conchinha concluída',
      pushBody: '${requester.displayName} concluiu o pedido.',
      pushData: {
        'event_type': JbcNotificationTypes.conchinhaRequestCompleted,
        'conchinha_request_id': requestId,
      },
    );
  }

  // —— Conchinha match pool ——

  @override
  Stream<List<ConchinhaPoolEntry>> watchConchinhaSearchPool() {
    return _client.from('conchinha_search_pool').stream(primaryKey: ['id']).map((rows) {
      final list = rows.map((r) => ConchinhaPoolEntry.fromRow(Map<String, dynamic>.from(r))).toList()
        ..sort((a, b) => a.profileKey.compareTo(b.profileKey));
      return list;
    });
  }

  @override
  Stream<ConchinhaMatchStateRow?> watchConchinhaMatchState() {
    return _client.from('conchinha_match_state').stream(primaryKey: ['id']).map((rows) {
      final mapped = rows.map((r) => Map<String, dynamic>.from(r)).toList();
      return ConchinhaMatchStateRow.fromRows(mapped);
    });
  }

  @override
  Future<ConchinhaTryMatchResult> joinConchinhaSearchPool({
    required JbcProfile profile,
    required ConchinhaSearchPreference preference,
  }) async {
    final now = DateTime.now().toUtc();
    await _client.from('conchinha_search_pool').upsert(
      {
        'profile': profile.storageKey,
        'preference': preference.dbValue,
        'created_at': now.toIso8601String(),
      },
      onConflict: 'profile',
    );
    final raw = await _client.rpc<dynamic>('conchinha_try_match');
    final result = ConchinhaTryMatchResult.fromRpc(raw);
    await _emitConchinhaMatchNotifications(actor: profile, result: result);
    return result;
  }

  @override
  Future<void> leaveConchinhaSearchPool(JbcProfile profile) async {
    await _client.from('conchinha_search_pool').delete().eq('profile', profile.storageKey);
    await _client.rpc<dynamic>('conchinha_try_match');
  }

  @override
  Future<ConchinhaTryMatchResult> tryConchinhaMatch() async {
    final raw = await _client.rpc<dynamic>('conchinha_try_match');
    return ConchinhaTryMatchResult.fromRpc(raw);
  }

  Future<void> _emitConchinhaMatchNotifications({
    required JbcProfile actor,
    required ConchinhaTryMatchResult result,
  }) async {
    if (!result.shouldNotifyDual && !result.shouldNotifySupreme) return;

    final summary = _conchinhaPrefsSummary(result.participants);
    final waveId = result.waveId;
    if (waveId.isEmpty) return;

    if (result.shouldNotifyDual) {
      await emitAppNotification(
        module: JbcNotificationModule.conchinha,
        actor: actor,
        eventType: JbcNotificationTypes.conchinhaMatchDual,
        title: 'Match de conchinha!',
        body: summary,
        entityId: waveId,
        payload: {
          'conchinha_wave_id': waveId,
          'participants': result.participants
              .map((e) => {'profile': e.profileKey, 'preference': e.preference.dbValue})
              .toList(),
        },
        requestPushBroadcast: true,
        pushBroadcastToAllProfiles: true,
        pushTitle: 'Match de conchinha!',
        pushBody: summary,
        pushData: {
          'event_type': JbcNotificationTypes.conchinhaMatchDual,
          'conchinha_wave_id': waveId,
        },
      );
      return;
    }

    if (result.shouldNotifySupreme) {
      final eventType = result.action == 'supreme_upgrade'
          ? JbcNotificationTypes.conchinhaMatchSupremeUpgrade
          : JbcNotificationTypes.conchinhaMatchSupreme;
      await emitAppNotification(
        module: JbcNotificationModule.conchinha,
        actor: actor,
        eventType: eventType,
        title: 'Match Supremo de conchinha!',
        body: summary,
        entityId: waveId,
        payload: {
          'conchinha_wave_id': waveId,
          'participants': result.participants
              .map((e) => {'profile': e.profileKey, 'preference': e.preference.dbValue})
              .toList(),
        },
        requestPushBroadcast: true,
        pushBroadcastToAllProfiles: true,
        pushTitle: 'Match Supremo!',
        pushBody: summary,
        pushData: {
          'event_type': eventType,
          'conchinha_wave_id': waveId,
        },
      );
    }
  }

  String _conchinhaPrefsSummary(List<ConchinhaPoolParticipant> participants) {
    final parts = participants.map((p) {
      final who = JbcProfile.displayNameForStorageKey(p.profileKey);
      return '$who: ${p.preference.labelBr}';
    });
    return parts.join(' · ');
  }

  // —— Piaditas (Epic 13) ——

  @override
  Stream<List<InsideJoke>> watchInsideJokes() {
    return _client.from('inside_jokes').stream(primaryKey: ['id']).map((rows) {
      final list = rows.map((r) => InsideJoke.fromRow(Map<String, dynamic>.from(r))).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  @override
  Future<String> createInsideJoke({
    required JbcProfile author,
    required String body,
    List<String> tags = const [],
  }) async {
    final normalized = InsideJokeBody.normalize(body);
    final id = _uuid.v4();
    final now = DateTime.now().toUtc();
    await _client.from('inside_jokes').insert({
      'id': id,
      'body': normalized,
      'author': author.storageKey,
      'tags': tags.isEmpty ? <String>[] : tags,
      'created_at': now.toIso8601String(),
    });
    final preview =
        normalized.length > 140 ? '${normalized.substring(0, 140)}…' : normalized;
    await emitAppNotification(
      module: JbcNotificationModule.piaditas,
      actor: author,
      eventType: JbcNotificationTypes.insideJokeNew,
      title: '${author.displayName} guardou uma piada no pote.',
      body: preview,
      entityId: id,
      payload: {'inside_joke_id': id},
      requestPushBroadcast: true,
      pushTitle: 'Piaditas',
      pushBody: preview,
    );
    return id;
  }

  Future<void> _flushMomentEmotionNotification(JbcProfile actor) async {
    await emitAppNotification(
      module: JbcNotificationModule.momentEmotion,
      actor: actor,
      eventType: JbcNotificationTypes.momentEmotionUpdated,
      title: '${actor.displayName} atualizou a emoção do momento.',
      entityId: actor.storageKey,
      payload: {'profile': actor.storageKey},
      requestPushBroadcast: true,
      pushTitle: 'Emoção do momento',
      pushBody: '${actor.displayName} atualizou o sticker.',
    );
  }

  @override
  Stream<List<MomentEmotion?>> watchMomentEmotions() {
    return _client.from('moment_emotions').stream(primaryKey: ['profile']).map((rows) {
      final by = <String, MomentEmotion>{};
      for (final r in rows) {
        final m = Map<String, dynamic>.from(r);
        final e = MomentEmotion.fromRow(m);
        by[e.profileKey] = e;
      }
      return [for (final p in JbcProfile.values) by[p.storageKey]];
    });
  }

  @override
  Future<void> setMomentSticker({
    required JbcProfile profile,
    required String stickerId,
  }) async {
    if (!MomentStickerCatalog.isValidId(stickerId)) {
      throw ArgumentError('Sticker inválido.');
    }
    final now = DateTime.now().toUtc();
    await _client.from('moment_emotions').upsert(
      {
        'profile': profile.storageKey,
        'sticker_id': stickerId,
        'updated_at': now.toIso8601String(),
      },
      onConflict: 'profile',
    );
    _momentEmotionCoalescer.schedule(profile);
  }

  // —— Continhas (Epic 15) ——

  Stream<List<ContinhasExpense>> _watchContinhasExpensesMerged(String hangoutId) {
    late final StreamController<List<ContinhasExpense>> controller;
    controller = StreamController<List<ContinhasExpense>>(
      onListen: () {
        var lastExp = <Map<String, dynamic>>[];
        var lastShares = <Map<String, dynamic>>[];

        void emit() {
          final expIds = lastExp.map((r) => r['id'] as String).toSet();
          final byExpense = <String, List<Map<String, dynamic>>>{};
          for (final s in lastShares) {
            final eid = s['expense_id'] as String;
            if (!expIds.contains(eid)) continue;
            byExpense.putIfAbsent(eid, () => []).add(s);
          }
          final sorted = [...lastExp]
            ..sort((a, b) => (b['created_at'] as String).compareTo(a['created_at'] as String));
          final list = sorted
              .map(
                (r) => ContinhasExpense.fromRow(
                  Map<String, dynamic>.from(r),
                  (byExpense[r['id'] as String] ?? const [])
                      .map((x) => ContinhasExpenseShare.fromRow(Map<String, dynamic>.from(x)))
                      .toList(),
                ),
              )
              .toList();
          if (!controller.isClosed) {
            controller.add(list);
          }
        }

        final subA = _client
            .from('continhas_expense')
            .stream(primaryKey: ['id'])
            .eq('hangout_id', hangoutId)
            .listen(
              (rows) {
                lastExp = rows.map((r) => Map<String, dynamic>.from(r)).toList();
                emit();
              },
              onError: controller.addError,
            );
        final subB = _client.from('continhas_expense_share').stream(primaryKey: ['id']).listen(
              (rows) {
                lastShares = rows.map((r) => Map<String, dynamic>.from(r)).toList();
                emit();
              },
              onError: controller.addError,
            );

        controller.onCancel = () async {
          await subA.cancel();
          await subB.cancel();
        };
      },
    );
    return controller.stream;
  }

  @override
  Stream<List<JbcCashLedgerEntry>> watchJbcCashLedger() {
    return _client.from('jbc_cash_ledger').stream(primaryKey: ['id']).map((rows) {
      final list = rows.map((r) => JbcCashLedgerEntry.fromRow(Map<String, dynamic>.from(r))).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  @override
  Future<void> depositJbcCash({
    required JbcProfile profile,
    required double amountBrl,
    String? note,
  }) async {
    final amount = double.parse(amountBrl.toStringAsFixed(2));
    if (amount <= 0) {
      throw ArgumentError('Valor do depósito tem de ser positivo.');
    }
    final id = _uuid.v4();
    final now = DateTime.now().toUtc();
    await _client.from('jbc_cash_ledger').insert({
      'id': id,
      'type': JbcCashLedgerType.deposit.dbValue,
      'amount_brl': amount,
      'recorded_by': profile.storageKey,
      'note': note?.trim().isEmpty ?? true ? null : note!.trim(),
      'created_at': now.toIso8601String(),
    });
    await emitAppNotification(
      module: JbcNotificationModule.continhas,
      actor: profile,
      eventType: JbcNotificationTypes.continhasCashDeposit,
      title: '${profile.displayName} depositou na Caixa do JBC.',
      entityId: id,
      payload: {'ledger_id': id, 'amount_brl': amount},
      requestPushBroadcast: true,
      pushTitle: 'Caixa do JBC',
      pushBody: '${profile.displayName} depositou R\$ ${amount.toStringAsFixed(2)}.',
    );
  }

  @override
  Future<double> fetchJbcCashBalanceBrl() async {
    final rows = await _client.from('jbc_cash_ledger').select('type, amount_brl');
    var cents = 0;
    for (final r in rows) {
      final m = Map<String, dynamic>.from(r);
      final t = m['type'] as String? ?? '';
      final a = parseAmountBrlToCents(m['amount_brl']);
      if (t == JbcCashLedgerType.deposit.dbValue) {
        cents += a;
      } else if (t == JbcCashLedgerType.hangoutExpenseDebit.dbValue) {
        cents -= a;
      }
    }
    return double.parse(centsToBrl(cents).toStringAsFixed(2));
  }

  @override
  Stream<List<ContinhasGuest>> watchContinhasGuests() {
    return _client.from('continhas_guest').stream(primaryKey: ['id']).map((rows) {
      final list = rows.map((r) => ContinhasGuest.fromRow(Map<String, dynamic>.from(r))).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  @override
  Future<String> createContinhasGuest({
    required JbcProfile profile,
    required String displayName,
    required String emoji,
  }) async {
    final name = displayName.trim();
    final em = emoji.trim();
    if (name.isEmpty || em.isEmpty) {
      throw ArgumentError('Nome e emoji são obrigatórios!!');
    }
    final id = _uuid.v4();
    final now = DateTime.now().toUtc();
    await _client.from('continhas_guest').insert({
      'id': id,
      'display_name': name,
      'emoji': em,
      'created_by': profile.storageKey,
      'created_at': now.toIso8601String(),
    });
    return id;
  }

  @override
  Future<void> ensureContinhasHangoutOpen(String hangoutId) async {
    final existing = await _client
        .from('continhas_hangout')
        .select('hangout_id')
        .eq('hangout_id', hangoutId)
        .maybeSingle();
    if (existing != null) return;
    await _client.from('continhas_hangout').insert({
      'hangout_id': hangoutId,
      'status': 'open',
    });
  }

  @override
  Stream<ContinhasHangoutState?> watchContinhasHangoutState(String hangoutId) {
    return _client
        .from('continhas_hangout')
        .stream(primaryKey: ['hangout_id'])
        .eq('hangout_id', hangoutId)
        .map((rows) {
          if (rows.isEmpty) return null;
          return ContinhasHangoutState.fromRow(Map<String, dynamic>.from(rows.first));
        });
  }

  @override
  Stream<List<String>> watchContinhasHangoutGuestIds(String hangoutId) {
    return _client
        .from('continhas_hangout_guest')
        .stream(primaryKey: ['hangout_id', 'guest_id'])
        .eq('hangout_id', hangoutId)
        .map((rows) => rows.map((r) => r['guest_id'] as String).toList());
  }

  @override
  Future<void> addContinhasGuestToHangout({
    required String hangoutId,
    required String guestId,
  }) async {
    await ensureContinhasHangoutOpen(hangoutId);
    final st = await _client.from('continhas_hangout').select('status').eq('hangout_id', hangoutId).maybeSingle();
    if (st == null || st['status'] != 'open') {
      throw StateError('Este rolê não está aberto para continhas.');
    }
    final now = DateTime.now().toUtc();
    await _client.from('continhas_hangout_guest').upsert(
      {
        'hangout_id': hangoutId,
        'guest_id': guestId,
        'created_at': now.toIso8601String(),
      },
      onConflict: 'hangout_id,guest_id',
    );
  }

  @override
  Future<void> removeContinhasGuestFromHangout({
    required String hangoutId,
    required String guestId,
  }) async {
    await _client.from('continhas_hangout_guest').delete().match({
      'hangout_id': hangoutId,
      'guest_id': guestId,
    });
  }

  @override
  Stream<List<ContinhasExpense>> watchContinhasExpenses(String hangoutId) {
    return _watchContinhasExpensesMerged(hangoutId);
  }

  @override
  Future<void> addContinhasExpense({
    required JbcProfile createdBy,
    required String hangoutId,
    required String hangoutTitle,
    required double amountBrl,
    required JbcProfile payer,
    required ContinhasPaymentSource paymentSource,
    required String description,
    required Set<JbcProfile> splitProfiles,
    required Set<String> splitGuestIds,
  }) async {
    final amount = double.parse(amountBrl.toStringAsFixed(2));
    if (amount <= 0) throw ArgumentError('Valor inválido.');
    final stRow = await _client.from('continhas_hangout').select().eq('hangout_id', hangoutId).maybeSingle();
    if (stRow == null || stRow['status'] != 'open') {
      throw StateError('Continhas deste rolê não está aberta.');
    }
    if (!splitProfiles.contains(payer)) {
      throw StateError('Quem pagou tem de entrar no rateio.');
    }
    final guestRows = await _client
        .from('continhas_hangout_guest')
        .select('guest_id')
        .eq('hangout_id', hangoutId);
    final allowedGuests = guestRows.map((r) => r['guest_id'] as String).toSet();
    for (final gid in splitGuestIds) {
      if (!allowedGuests.contains(gid)) {
        throw StateError('Convidado não está neste rolê: adicione-o antes de lançar a despesa.');
      }
    }
    if (splitProfiles.isEmpty && splitGuestIds.isEmpty) {
      throw StateError('Escolha com quem divide.');
    }
    if (paymentSource == ContinhasPaymentSource.jbcCash) {
      final bal = await fetchJbcCashBalanceBrl();
      if (bal + 1e-9 < amount) {
        throw StateError('Saldo insuficiente na Caixa do JBC (v1 não permite saldo negativo).');
      }
    }

    final expenseId = _uuid.v4();
    final now = DateTime.now().toUtc();
    await _client.from('continhas_expense').insert({
      'id': expenseId,
      'hangout_id': hangoutId,
      'amount_brl': amount,
      'payer_profile': payer.storageKey,
      'payment_source': paymentSource.dbValue,
      'description': description.trim(),
      'created_by': createdBy.storageKey,
      'created_at': now.toIso8601String(),
    });

    final shareRows = <Map<String, dynamic>>[];
    for (final p in splitProfiles) {
      shareRows.add({
        'id': _uuid.v4(),
        'expense_id': expenseId,
        'participant_type': ContinhasShareParticipantType.profile.dbValue,
        'participant_id': p.storageKey,
      });
    }
    for (final gid in splitGuestIds) {
      shareRows.add({
        'id': _uuid.v4(),
        'expense_id': expenseId,
        'participant_type': ContinhasShareParticipantType.guest.dbValue,
        'participant_id': gid,
      });
    }
    await _client.from('continhas_expense_share').insert(shareRows);

    if (paymentSource == ContinhasPaymentSource.jbcCash) {
      await _client.from('jbc_cash_ledger').insert({
        'id': _uuid.v4(),
        'type': JbcCashLedgerType.hangoutExpenseDebit.dbValue,
        'amount_brl': amount,
        'recorded_by': createdBy.storageKey,
        'hangout_expense_id': expenseId,
        'created_at': now.toIso8601String(),
      });
    }

    final shortTitle =
        hangoutTitle.length > 48 ? '${hangoutTitle.substring(0, 48)}…' : hangoutTitle;
    await emitAppNotification(
      module: JbcNotificationModule.continhas,
      actor: createdBy,
      eventType: JbcNotificationTypes.continhasExpenseNew,
      title: 'Nova despesa em “$shortTitle”.',
      entityId: expenseId,
      payload: {
        'continhas_expense_id': expenseId,
        'hangout_id': hangoutId,
        'amount_brl': amount,
      },
      requestPushBroadcast: true,
      pushTitle: 'Continhas',
      pushBody: 'Nova despesa em “$shortTitle”.',
    );
  }

  @override
  Future<void> deleteContinhasExpense({
    required String expenseId,
    required JbcProfile deletedBy,
  }) async {
    final row = await _client.from('continhas_expense').select('hangout_id').eq('id', expenseId).maybeSingle();
    if (row == null) return;
    final hangoutId = row['hangout_id'] as String;
    final st = await _client.from('continhas_hangout').select('status').eq('hangout_id', hangoutId).maybeSingle();
    if (st == null || st['status'] != 'open') {
      throw StateError('Só dá para apagar despesas com continhas aberta.');
    }
    await _client.from('continhas_expense').delete().eq('id', expenseId);
  }

  @override
  Future<void> closeContinhasHangout({
    required String hangoutId,
    required JbcProfile closedBy,
    required String hangoutTitle,
  }) async {
    final st = await _client.from('continhas_hangout').select().eq('hangout_id', hangoutId).maybeSingle();
    if (st == null || st['status'] != 'open') {
      throw StateError('Continhas já fechada ou ainda não iniciada.');
    }
    final expRows =
        await _client.from('continhas_expense').select().eq('hangout_id', hangoutId).order('created_at');
    final ids = expRows.map((r) => r['id'] as String).toList();
    final shareRows = ids.isEmpty
        ? <Map<String, dynamic>>[]
        : await _client.from('continhas_expense_share').select().inFilter('expense_id', ids);

    final byExpense = <String, List<Map<String, dynamic>>>{};
    for (final sh in shareRows) {
      final m = Map<String, dynamic>.from(sh);
      final eid = m['expense_id'] as String;
      byExpense.putIfAbsent(eid, () => []).add(m);
    }

    final ledger = <ContinhasExpenseForBalance>[];
    for (final r in expRows) {
      final row = Map<String, dynamic>.from(r);
      final shares = byExpense[row['id'] as String] ?? const [];
      final keys = shares.map((x) {
        final sm = Map<String, dynamic>.from(x);
        final t = sm['participant_type'] as String? ?? 'profile';
        final pid = sm['participant_id'] as String;
        if (t == ContinhasShareParticipantType.guest.dbValue) {
          return ContinhasParticipantKey.guest(pid);
        }
        return ContinhasParticipantKey.profile(pid);
      }).toList();
      ledger.add(
        ContinhasExpenseForBalance(
          paymentSource: (row['payment_source'] as String? ?? 'self') == ContinhasPaymentSource.jbcCash.dbValue
              ? ContinhasPaymentSourceCalc.jbcCash
              : ContinhasPaymentSourceCalc.self,
          payerProfileStorageKey: row['payer_profile'] as String,
          amountCents: parseAmountBrlToCents(row['amount_brl']),
          participantKeys: keys,
        ),
      );
    }

    final balances = computeContinhasBalancesCents(ledger);
    final edges = computeMinimalTransfersCents(balances);
    final now = DateTime.now().toUtc();

    final settlement = <String, dynamic>{
      'version': 1,
      'closed_at': now.toIso8601String(),
      'closed_by': closedBy.storageKey,
      'balances_brl': balancesCentsToBrlMap(balances),
      'suggestions': [
        for (final e in edges)
          {
            'from': e.fromKey,
            'to': e.toKey,
            'amount_brl': double.parse(centsToBrl(e.amountCents).toStringAsFixed(2)),
          },
      ],
    };

    await _client.from('continhas_hangout').update({
      'status': 'closed',
      'closed_at': now.toIso8601String(),
      'closed_by': closedBy.storageKey,
      'settlement_json': settlement,
    }).eq('hangout_id', hangoutId);

    final shortTitle =
        hangoutTitle.length > 48 ? '${hangoutTitle.substring(0, 48)}…' : hangoutTitle;
    await emitAppNotification(
      module: JbcNotificationModule.continhas,
      actor: closedBy,
      eventType: JbcNotificationTypes.continhasHangoutClosed,
      title: 'Gastos de "$shortTitle" fechados no Continhas.',
      entityId: hangoutId,
      payload: {'hangout_id': hangoutId},
      requestPushBroadcast: true,
      pushTitle: 'Continhas fechado',
      pushBody: '“$shortTitle” — gastos fechados.',
    );
  }

  // —— Notificações (Epic 9) ——

  TimelineEditDelta _timelineEditDelta({
    required TimelineEvent existing,
    required DateTime occurredAt,
    required String title,
    required String description,
    required List<String> newImageUrls,
  }) {
    final d = TimelineEditDelta();
    final od = existing.occurredAt.toUtc();
    final nd = occurredAt.toUtc();
    if (od.year != nd.year || od.month != nd.month || od.day != nd.day) {
      d.dateChanged = true;
    }
    if (existing.title != title) d.titleChanged = true;
    if (existing.description != description) d.descriptionChanged = true;
    final prev = existing.imageUrls.toSet();
    final next = newImageUrls.toSet();
    d.photosAdded = next.difference(prev).length;
    d.photosRemoved = prev.difference(next).length;
    return d;
  }

  Future<void> _flushTimelineEditNotification({
    required String timelineEventId,
    required JbcProfile actor,
    required TimelineEditDelta delta,
  }) async {
    final detail = delta.describePt();
    if (detail.isEmpty) return;
    await emitAppNotification(
      module: JbcNotificationModule.timeline,
      actor: actor,
      eventType: JbcNotificationTypes.timelineEditAgg,
      title: '${actor.displayName} atualizou uma memória: $detail',
      entityId: timelineEventId,
      payload: {
        'timeline_event_id': timelineEventId,
        'edit_summary': detail,
      },
      requestPushBroadcast: true,
      pushTitle: 'Memória atualizada',
      pushBody: detail,
    );
  }

  @override
  Stream<List<JbcAppNotification>> watchJbcNotifications() {
    return _client.from('jbc_notifications').stream(primaryKey: ['id']).map((rows) {
      final list = rows.map(JbcAppNotification.fromRow).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  @override
  Future<void> markJbcNotificationRead(String id) async {
    await _client.from('jbc_notifications').update({
      'read_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', id);
  }

  @override
  Future<void> markAllJbcNotificationsRead() async {
    await _client.from('jbc_notifications').update({
      'read_at': DateTime.now().toUtc().toIso8601String(),
    }).filter('read_at', 'is', null);
  }

  @override
  Future<void> emitAppNotification({
    required JbcNotificationModule module,
    required JbcProfile actor,
    required String eventType,
    required String title,
    String? body,
    String? entityId,
    Map<String, dynamic> payload = const {},
    bool requestPushBroadcast = false,
    bool pushBroadcastToAllProfiles = false,
    String? pushTitle,
    String? pushBody,
    Map<String, String>? pushData,
  }) async {
    final now = DateTime.now().toUtc();
    await _client.from('jbc_notifications').insert({
      'id': _uuid.v4(),
      'module': module.dbValue,
      'event_type': eventType,
      'actor': actor.storageKey,
      'title': title,
      'body': body,
      'entity_id': entityId,
      'payload': payload,
      'created_at': now.toIso8601String(),
    });
    if (requestPushBroadcast) {
      final exclude = pushBroadcastToAllProfiles ? null : actor.storageKey;
      unawaited(
        _invokePushEdge(
          excludeProfile: exclude,
          title: pushTitle ?? title,
          body: pushBody ?? body ?? title,
          data: pushData,
        ),
      );
    }
  }

  Future<void> _invokePushEdge({
    String? excludeProfile,
    required String title,
    required String body,
    Map<String, String>? data,
  }) async {
    const enabled = bool.fromEnvironment('JBC_PUSH_INVOCATION', defaultValue: true);
    if (!enabled) return;
    try {
      await _client.functions.invoke(
        'send-jbc-push',
        body: <String, dynamic>{
          if (excludeProfile != null && excludeProfile.isNotEmpty) 'exclude_actor': excludeProfile,
          'title': title,
          'body': body,
          if (data != null && data.isNotEmpty) 'data': data,
        },
      );
    } catch (e, st) {
      developer.log('send-jbc-push invoke failed', error: e, stackTrace: st);
    }
  }

  @override
  Future<void> upsertFcmDeviceToken({
    required JbcProfile profile,
    required String token,
  }) async {
    final now = DateTime.now().toUtc();
    await _client.from('fcm_device_tokens').upsert(
      {
        'profile': profile.storageKey,
        'token': token,
        'updated_at': now.toIso8601String(),
      },
      onConflict: 'token',
    );
  }
}
