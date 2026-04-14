import 'dart:convert';
import 'dart:typed_data';

import 'package:mime/mime.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../core/profile/jbc_profile.dart';
import '../models/availability.dart';
import '../models/hangout.dart';
import '../models/idea.dart';
import '../models/timeline_event.dart';
import '../models/timeline_event_comment.dart';
import 'jbc_repository.dart';
import 'timeline_storage_paths.dart';

class SupabaseRepository implements JbcRepository {
  SupabaseRepository(this._client);

  final SupabaseClient _client;
  final _uuid = const Uuid();

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
  }

  @override
  Future<void> updateTimelineEvent({
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
    await _client.from('hangouts').insert({
      'id': _uuid.v4(),
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
  }

  @override
  Future<void> updateHangout({
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
  }

  @override
  Future<void> updateHangoutStatus({
    required Hangout existing,
    required HangoutStatus status,
  }) async {
    final now = DateTime.now().toUtc();
    await _client.from('hangouts').update({
      'status': status.dbValue,
      'updated_at': now.toIso8601String(),
    }).eq('id', existing.id);
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
    await _client.from('ideas').insert({
      'id': _uuid.v4(),
      'title': title,
      'description': description,
      'category': category?.dbValue,
      'status': 'active',
      'created_by': profile.storageKey,
      'created_at': now.toIso8601String(),
      'updated_at': now.toIso8601String(),
    });
  }

  @override
  Future<void> updateIdea({
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
  }

  @override
  Future<void> updateIdeaStatus({
    required Idea existing,
    required IdeaStatus status,
    JbcProfile? archivedBy,
  }) async {
    final now = DateTime.now().toUtc();
    final archivedKey =
        status == IdeaStatus.archived ? archivedBy?.storageKey : null;
    await _client.from('ideas').update({
      'status': status.dbValue,
      'archived_by': archivedKey,
      'updated_at': now.toIso8601String(),
    }).eq('id', existing.id);
  }

  @override
  Future<void> clearAllRemoteData() async {
    const epoch = '1970-01-01T00:00:00Z';
    await _client.from('timeline_event_comments').delete().gte('created_at', epoch);
    await _client.from('timeline_events').delete().gte('created_at', epoch);
    await _client.from('hangouts').delete().gte('created_at', epoch);
    await _client.from('ideas').delete().gte('created_at', epoch);
    await _client.from('availabilities').delete().gte('weekday', 1);
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
}
