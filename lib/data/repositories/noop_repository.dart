import '../../core/notifications/jbc_notification_module.dart';
import '../../core/profile/jbc_profile.dart';
import '../models/availability.dart';
import '../models/conchinha_acceptance.dart';
import '../models/conchinha_address.dart';
import '../models/conchinha_match_models.dart';
import '../models/conchinha_request.dart';
import '../models/hangout.dart';
import '../models/inside_joke.dart';
import '../models/continhas_expense.dart';
import '../models/continhas_guest.dart';
import '../models/continhas_hangout_state.dart';
import '../models/jbc_cash_ledger_entry.dart';
import '../models/moment_emotion.dart';
import '../models/idea.dart';
import '../models/jbc_app_notification.dart';
import '../models/timeline_event.dart';
import '../models/timeline_event_comment.dart';
import '../models/timeline_event_reaction.dart';
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
  Stream<List<TimelineEventComment>> watchTimelineEventComments(String timelineEventId) =>
      Stream.value(const []);

  @override
  Stream<List<TimelineEventReaction>> watchTimelineEventReactions(String timelineEventId) =>
      Stream.value(const []);

  @override
  Future<void> upsertTimelineEventReaction({
    required String timelineEventId,
    required JbcProfile profile,
    required String emoji,
  }) async {}

  @override
  Future<void> addTimelineEventComment({
    required String timelineEventId,
    required JbcProfile author,
    required String body,
  }) async {
    throw UnsupportedError('Configure Supabase para comentários na timeline.');
  }

  @override
  Future<void> deleteTimelineEventComment({
    required TimelineEventComment comment,
    required JbcProfile deletedBy,
  }) async {
    throw UnsupportedError('Configure Supabase para comentários na timeline.');
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
    throw UnsupportedError(
      'Configure SUPABASE_URL e SUPABASE_ANON_KEY para salvar memórias.',
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
    String? title,
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
    String? title,
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
    required JbcProfile updatedBy,
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
    required JbcProfile updatedBy,
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
    List<TimelineImageInput> images = const [],
    int primaryImageIndex = 0,
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
    required JbcProfile updatedBy,
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
    JbcProfile? archivedBy,
    JbcProfile? notificationActor,
  }) async {
    throw UnsupportedError('Configure Supabase para ideias.');
  }

  @override
  Future<void> clearAllRemoteData() async {
    throw UnsupportedError('Configure Supabase para limpar dados remotos.');
  }

  @override
  Future<void> importTimelineEventsFromJson({
    required JbcProfile profile,
    required String json,
  }) async {
    throw UnsupportedError('Configure Supabase para importar a timeline.');
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

  @override
  Stream<List<ConchinhaRequest>> watchConchinhaRequests() =>
      Stream<List<ConchinhaRequest>>.value(const []);

  @override
  Stream<ConchinhaRequest?> watchConchinhaRequest(String requestId) =>
      Stream<ConchinhaRequest?>.value(null);

  @override
  Stream<List<ConchinhaAcceptance>> watchConchinhaAcceptances(String requestId) =>
      Stream<List<ConchinhaAcceptance>>.value(const []);

  @override
  Future<String> createConchinhaRequest({
    required JbcProfile requester,
    required ConchinhaAddress address,
  }) async {
    throw UnsupportedError('Configure o Supabase para pedidos de conchinha.');
  }

  @override
  Future<void> acceptConchinhaRequest({
    required String requestId,
    required JbcProfile profile,
  }) async {
    throw UnsupportedError('Configure o Supabase para pedidos de conchinha.');
  }

  @override
  Future<void> cancelConchinhaRequest({
    required String requestId,
    required JbcProfile requester,
  }) async {
    throw UnsupportedError('Configure o Supabase para pedidos de conchinha.');
  }

  @override
  Future<void> completeConchinhaRequest({
    required String requestId,
    required JbcProfile requester,
  }) async {
    throw UnsupportedError('Configure o Supabase para pedidos de conchinha.');
  }

  @override
  Stream<List<ConchinhaPoolEntry>> watchConchinhaSearchPool() =>
      Stream<List<ConchinhaPoolEntry>>.value(const []);

  @override
  Stream<ConchinhaMatchStateRow?> watchConchinhaMatchState() =>
      Stream<ConchinhaMatchStateRow?>.value(null);

  @override
  Future<ConchinhaTryMatchResult> joinConchinhaSearchPool({
    required JbcProfile profile,
    required ConchinhaSearchPreference preference,
  }) async {
    throw UnsupportedError('Configure o Supabase para o match de conchinha.');
  }

  @override
  Future<void> leaveConchinhaSearchPool(JbcProfile profile) async {}

  @override
  Future<ConchinhaTryMatchResult> tryConchinhaMatch() async {
    return ConchinhaTryMatchResult.fromRpc(<String, dynamic>{
      'action': 'wait',
      'pool_count': 0,
      'participants': <dynamic>[],
      'wave_id': '',
    });
  }

  @override
  Stream<List<InsideJoke>> watchInsideJokes() =>
      Stream<List<InsideJoke>>.value(const []);

  @override
  Future<String> createInsideJoke({
    required JbcProfile author,
    required String body,
    List<String> tags = const [],
  }) async {
    throw UnsupportedError('Configure Supabase para Piaditas.');
  }

  @override
  Stream<List<MomentEmotion?>> watchMomentEmotions() =>
      Stream<List<MomentEmotion?>>.value(const [null, null, null]);

  @override
  Future<void> setMomentSticker({
    required JbcProfile profile,
    required String stickerId,
  }) async {
    throw UnsupportedError('Configure Supabase para emoção do momento.');
  }

  @override
  Stream<List<JbcCashLedgerEntry>> watchJbcCashLedger() =>
      Stream<List<JbcCashLedgerEntry>>.value(const []);

  @override
  Future<void> depositJbcCash({
    required JbcProfile profile,
    required double amountBrl,
    String? note,
  }) async {
    throw UnsupportedError('Configure Supabase para Continhas / Caixa.');
  }

  @override
  Future<double> fetchJbcCashBalanceBrl() async => 0;

  @override
  Stream<List<ContinhasGuest>> watchContinhasGuests() =>
      Stream<List<ContinhasGuest>>.value(const []);

  @override
  Future<String> createContinhasGuest({
    required JbcProfile profile,
    required String displayName,
    required String emoji,
  }) async {
    throw UnsupportedError('Configure Supabase para Continhas.');
  }

  @override
  Future<void> ensureContinhasHangoutOpen(String hangoutId) async {
    throw UnsupportedError('Configure Supabase para Continhas.');
  }

  @override
  Stream<ContinhasHangoutState?> watchContinhasHangoutState(String hangoutId) =>
      Stream<ContinhasHangoutState?>.value(null);

  @override
  Stream<List<String>> watchContinhasHangoutGuestIds(String hangoutId) =>
      Stream<List<String>>.value(const []);

  @override
  Future<void> addContinhasGuestToHangout({
    required String hangoutId,
    required String guestId,
  }) async {
    throw UnsupportedError('Configure Supabase para Continhas.');
  }

  @override
  Future<void> removeContinhasGuestFromHangout({
    required String hangoutId,
    required String guestId,
  }) async {
    throw UnsupportedError('Configure Supabase para Continhas.');
  }

  @override
  Stream<List<ContinhasExpense>> watchContinhasExpenses(String hangoutId) =>
      Stream<List<ContinhasExpense>>.value(const []);

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
    throw UnsupportedError('Configure Supabase para Continhas.');
  }

  @override
  Future<void> deleteContinhasExpense({
    required String expenseId,
    required JbcProfile deletedBy,
  }) async {
    throw UnsupportedError('Configure Supabase para Continhas.');
  }

  @override
  Future<void> closeContinhasHangout({
    required String hangoutId,
    required JbcProfile closedBy,
    required String hangoutTitle,
  }) async {
    throw UnsupportedError('Configure Supabase para Continhas.');
  }

  @override
  Stream<List<JbcAppNotification>> watchJbcNotifications() =>
      Stream<List<JbcAppNotification>>.value(const []);

  @override
  Future<void> markJbcNotificationRead(String id) async {}

  @override
  Future<void> markAllJbcNotificationsRead() async {}

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
  }) async {}

  @override
  Future<void> upsertFcmDeviceToken({
    required JbcProfile profile,
    required String token,
  }) async {}
}
