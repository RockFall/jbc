import '../../core/profile/jbc_profile.dart';
import '../models/availability.dart';
import '../models/hangout.dart';
import '../models/idea.dart';
import '../models/timeline_event.dart';
import 'jbc_repository.dart';

/// Backend não configurado: sem sincronização (streams vazios).
class NoopRepository implements JbcRepository {
  const NoopRepository();

  @override
  Stream<List<Availability>> watchAvailabilities() => Stream.value(const []);

  @override
  Stream<List<Hangout>> watchHangouts() => Stream.value(const []);

  @override
  Stream<List<Idea>> watchIdeas() => Stream.value(const []);

  @override
  Stream<List<TimelineEvent>> watchTimelineEvents() => Stream.value(const []);

  @override
  Future<void> createManualTimelineEvent({
    required JbcProfile profile,
    required DateTime occurredAt,
    required String title,
    required String description,
    List<int>? imageBytes,
    String? imageExtension,
  }) async {
    throw UnsupportedError(
      'Configure SUPABASE_URL e SUPABASE_ANON_KEY para salvar memórias.',
    );
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
    throw UnsupportedError(
      'Configure SUPABASE_URL e SUPABASE_ANON_KEY para editar memórias.',
    );
  }

  @override
  Future<void> deleteTimelineEvent(TimelineEvent event) async {
    throw UnsupportedError(
      'Configure SUPABASE_URL e SUPABASE_ANON_KEY para excluir memórias.',
    );
  }

  @override
  Future<void> createAvailability({
    required JbcProfile profile,
    required int weekday,
    required String startTime,
    required String endTime,
  }) async {
    throw UnsupportedError('Configure Supabase para indisponibilidades.');
  }

  @override
  Future<void> updateAvailability({
    required Availability existing,
    required JbcProfile profile,
    required int weekday,
    required String startTime,
    required String endTime,
  }) async {
    throw UnsupportedError('Configure Supabase para indisponibilidades.');
  }

  @override
  Future<void> deleteAvailability({
    required Availability existing,
    required JbcProfile profile,
  }) async {
    throw UnsupportedError('Configure Supabase para indisponibilidades.');
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
    throw UnsupportedError('Configure Supabase para rolês.');
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
    throw UnsupportedError('Configure Supabase para rolês.');
  }

  @override
  Future<void> updateHangoutStatus({
    required Hangout existing,
    required HangoutStatus status,
  }) async {
    throw UnsupportedError('Configure Supabase para rolês.');
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
    throw UnsupportedError('Configure Supabase para registrar memória do rolê.');
  }

  @override
  Future<void> createIdea({
    required JbcProfile profile,
    required String title,
    String? description,
    IdeaCategory? category,
  }) async {
    throw UnsupportedError('Configure Supabase para ideias.');
  }

  @override
  Future<void> updateIdea({
    required Idea existing,
    required String title,
    String? description,
    IdeaCategory? category,
  }) async {
    throw UnsupportedError('Configure Supabase para ideias.');
  }

  @override
  Future<void> updateIdeaStatus({
    required Idea existing,
    required IdeaStatus status,
  }) async {
    throw UnsupportedError('Configure Supabase para ideias.');
  }

  @override
  Future<void> deleteIdea(Idea idea) async {
    throw UnsupportedError('Configure Supabase para ideias.');
  }

  @override
  Future<void> insertSampleAvailability(JbcProfile profile) async {}

  @override
  Future<void> insertSampleHangout(JbcProfile profile) async {}

  @override
  Future<void> insertSampleIdea(JbcProfile profile) async {}

  @override
  Future<void> insertSampleTimelineEvent(JbcProfile profile) async {}
}
