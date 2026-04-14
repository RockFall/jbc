import '../../core/profile/jbc_profile.dart';
import '../models/availability.dart';
import '../models/hangout.dart';
import '../models/idea.dart';
import '../models/timeline_event.dart';
import '../models/timeline_event_comment.dart';

abstract class JbcRepository {
  Stream<List<TimelineEvent>> watchTimelineEvents();

  Stream<List<TimelineEventComment>> watchTimelineEventComments(String timelineEventId);

  Future<void> addTimelineEventComment({
    required String timelineEventId,
    required JbcProfile author,
    required String body,
  });

  /// Remove comentário; só o autor [deletedBy] pode apagar.
  Future<void> deleteTimelineEventComment({
    required TimelineEventComment comment,
    required JbcProfile deletedBy,
  });

  /// Cria memória manual (`origin = manual`, sem `hangout_id`).
  Future<void> createManualTimelineEvent({
    required JbcProfile profile,
    required DateTime occurredAt,
    required String title,
    required String description,
    List<TimelineImageInput> images = const [],
    int primaryImageIndex = 0,
  });

  /// Atualiza texto/data/fotos; preserva `origin`, `hangout_id` e `created_by`.
  Future<void> updateTimelineEvent({
    required TimelineEvent existing,
    required DateTime occurredAt,
    required String title,
    required String description,
    required List<TimelineImageInput> images,
    required int primaryImageIndex,
  });

  Future<void> deleteTimelineEvent(TimelineEvent event);

  Stream<List<Hangout>> watchHangouts();

  Stream<List<Availability>> watchAvailabilities();

  Future<void> createAvailability({
    required JbcProfile profile,
    required int weekday,
    required String startTime,
    required String endTime,
    String? title,
  });

  Future<void> updateAvailability({
    required Availability existing,
    required JbcProfile profile,
    required int weekday,
    required String startTime,
    required String endTime,
    String? title,
  });

  Future<void> deleteAvailability({
    required Availability existing,
    required JbcProfile profile,
  });

  Future<void> createHangout({
    required JbcProfile profile,
    required String title,
    String? description,
    required DateTime date,
    required String startTime,
    String? endTime,
    String? notes,
  });

  Future<void> updateHangout({
    required Hangout existing,
    required String title,
    String? description,
    required DateTime date,
    required String startTime,
    String? endTime,
    String? notes,
  });

  Future<void> updateHangoutStatus({
    required Hangout existing,
    required HangoutStatus status,
  });

  /// Cria evento na timeline ligado ao rolê; atualiza `timeline_event_id`. Idempotente: erro se já existir vínculo.
  Future<void> createTimelineFromHangout({
    required Hangout hangout,
    required JbcProfile profile,
    required DateTime occurredAt,
    required String title,
    required String description,
    List<TimelineImageInput> images = const [],
    int primaryImageIndex = 0,
  });

  Stream<List<Idea>> watchIdeas();

  Future<void> createIdea({
    required JbcProfile profile,
    required String title,
    String? description,
    IdeaCategory? category,
  });

  Future<void> updateIdea({
    required Idea existing,
    required String title,
    String? description,
    IdeaCategory? category,
  });

  Future<void> updateIdeaStatus({
    required Idea existing,
    required IdeaStatus status,
    /// Preenchido ao marcar como [IdeaStatus.archived] (quem odiou).
    JbcProfile? archivedBy,
  });

  /// Apaga todos os dados das tabelas JBC (perigoso). Só para dev.
  Future<void> clearAllRemoteData();

  /// Insere memórias manuais a partir de JSON `[{date, title, description}]`.
  Future<void> importTimelineEventsFromJson({
    required JbcProfile profile,
    required String json,
  });

  Future<void> deleteIdea(Idea idea);

  Future<void> insertSampleTimelineEvent(JbcProfile profile);

  Future<void> insertSampleHangout(JbcProfile profile);

  Future<void> insertSampleAvailability(JbcProfile profile);

  Future<void> insertSampleIdea(JbcProfile profile);
}

