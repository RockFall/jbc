import 'dart:typed_data';

import 'package:mime/mime.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../core/profile/jbc_profile.dart';
import '../models/availability.dart';
import '../models/hangout.dart';
import '../models/idea.dart';
import '../models/timeline_event.dart';
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
  Future<void> createManualTimelineEvent({
    required JbcProfile profile,
    required DateTime occurredAt,
    required String title,
    required String description,
    List<int>? imageBytes,
    String? imageExtension,
  }) async {
    final id = _uuid.v4();
    final now = DateTime.now().toUtc();
    String? imageUrl;
    if (imageBytes != null && imageBytes.isNotEmpty) {
      final ext = (imageExtension ?? 'jpg').toLowerCase();
      imageUrl = await _uploadTimelineCover(id, imageBytes, ext);
    }
    await _client.from('timeline_events').insert({
      'id': id,
      'occurred_at': occurredAt.toUtc().toIso8601String(),
      'title': title,
      'description': description,
      'image_url': imageUrl,
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
    List<int>? newImageBytes,
    String? newImageExtension,
    bool removeImage = false,
  }) async {
    final now = DateTime.now().toUtc();
    String? imageUrl = existing.imageUrl;
    if (newImageBytes != null && newImageBytes.isNotEmpty) {
      await _deleteTimelineImageIfExists(existing.imageUrl);
      final ext = (newImageExtension ?? 'jpg').toLowerCase();
      imageUrl = await _uploadTimelineCover(existing.id, newImageBytes, ext);
    } else if (removeImage) {
      await _deleteTimelineImageIfExists(existing.imageUrl);
      imageUrl = null;
    }
    await _client.from('timeline_events').update({
      'occurred_at': occurredAt.toUtc().toIso8601String(),
      'title': title,
      'description': description,
      'image_url': imageUrl,
      'updated_at': now.toIso8601String(),
    }).eq('id', existing.id);
  }

  @override
  Future<void> deleteTimelineEvent(TimelineEvent event) async {
    await _deleteTimelineImageIfExists(event.imageUrl);
    await _client.from('timeline_events').delete().eq('id', event.id);
  }

  Future<String> _uploadTimelineCover(
    String eventId,
    List<int> bytes,
    String ext,
  ) async {
    final path = timelineCoverObjectPath(eventId, ext);
    final contentType = lookupMimeType('file.$ext') ?? 'image/jpeg';
    await _client.storage.from(kTimelineImagesBucket).uploadBinary(
          path,
          Uint8List.fromList(bytes),
          fileOptions: FileOptions(
            contentType: contentType,
            upsert: true,
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
  }) async {
    await _client.from('availabilities').insert({
      'id': _uuid.v4(),
      'person': profile.storageKey,
      'weekday': weekday,
      'start_time': startTime,
      'end_time': endTime,
    });
  }

  @override
  Future<void> updateAvailability({
    required Availability existing,
    required JbcProfile profile,
    required int weekday,
    required String startTime,
    required String endTime,
  }) async {
    if (existing.person != profile.storageKey) {
      throw StateError('Só é possível editar as suas indisponibilidades.');
    }
    await _client.from('availabilities').update({
      'weekday': weekday,
      'start_time': startTime,
      'end_time': endTime,
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
    List<int>? imageBytes,
    String? imageExtension,
  }) async {
    if (hangout.status != HangoutStatus.happened) {
      throw StateError('Marque o rolê como aconteceu antes de registrar a memória.');
    }
    if (hangout.timelineEventId != null && hangout.timelineEventId!.isNotEmpty) {
      throw StateError('Este rolê já foi registrado na timeline.');
    }
    final eventId = _uuid.v4();
    final now = DateTime.now().toUtc();
    String? imageUrl;
    if (imageBytes != null && imageBytes.isNotEmpty) {
      final ext = (imageExtension ?? 'jpg').toLowerCase();
      imageUrl = await _uploadTimelineCover(eventId, imageBytes, ext);
    }
    await _client.from('timeline_events').insert({
      'id': eventId,
      'occurred_at': occurredAt.toUtc().toIso8601String(),
      'title': title,
      'description': description,
      'image_url': imageUrl,
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
  }) async {
    final now = DateTime.now().toUtc();
    await _client.from('ideas').update({
      'status': status.dbValue,
      'updated_at': now.toIso8601String(),
    }).eq('id', existing.id);
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
