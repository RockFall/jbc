import '../../core/notifications/jbc_notification_module.dart';
import '../../core/profile/jbc_profile.dart';
import '../models/availability.dart';
import '../models/conchinha_acceptance.dart';
import '../models/conchinha_address.dart';
import '../models/conchinha_match_models.dart';
import '../models/conchinha_request.dart';
import '../models/hangout.dart';
import '../models/idea.dart';
import '../models/inside_joke.dart';
import '../models/jbc_app_notification.dart';
import '../models/continhas_expense.dart';
import '../models/continhas_guest.dart';
import '../models/continhas_hangout_state.dart';
import '../models/jbc_cash_ledger_entry.dart';
import '../models/moment_emotion.dart';
import '../models/timeline_event.dart';
import '../models/timeline_event_comment.dart';
import '../models/timeline_event_reaction.dart';

abstract class JbcRepository {
  Stream<List<TimelineEvent>> watchTimelineEvents();

  Stream<List<TimelineEventComment>> watchTimelineEventComments(String timelineEventId);

  Stream<List<TimelineEventReaction>> watchTimelineEventReactions(String timelineEventId);

  /// Um emoji por perfil por evento (substitui o anterior).
  Future<void> upsertTimelineEventReaction({
    required String timelineEventId,
    required JbcProfile profile,
    required String emoji,
  });

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
    required JbcProfile updatedBy,
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
    required JbcProfile updatedBy,
    required Hangout existing,
    required String title,
    String? description,
    required DateTime date,
    required String startTime,
    String? endTime,
    String? notes,
  });

  Future<void> updateHangoutStatus({
    required JbcProfile updatedBy,
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
    required JbcProfile updatedBy,
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
    /// Quem fez a mudança (para notificação in-app).
    JbcProfile? notificationActor,
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

  // —— Conchinha (Epic 12) ——

  Stream<List<ConchinhaRequest>> watchConchinhaRequests();

  Stream<ConchinhaRequest?> watchConchinhaRequest(String requestId);

  Stream<List<ConchinhaAcceptance>> watchConchinhaAcceptances(String requestId);

  /// Um pedido `open` por perfil (índice único parcial no Supabase).
  Future<String> createConchinhaRequest({
    required JbcProfile requester,
    required ConchinhaAddress address,
  });

  Future<void> acceptConchinhaRequest({
    required String requestId,
    required JbcProfile profile,
  });

  Future<void> cancelConchinhaRequest({
    required String requestId,
    required JbcProfile requester,
  });

  Future<void> completeConchinhaRequest({
    required String requestId,
    required JbcProfile requester,
  });

  // —— Conchinha match pool ——

  Stream<List<ConchinhaPoolEntry>> watchConchinhaSearchPool();

  Stream<ConchinhaMatchStateRow?> watchConchinhaMatchState();

  /// Entra no pool e corre `conchinha_try_match()`; dispara notificações quando o RPC indica match.
  Future<ConchinhaTryMatchResult> joinConchinhaSearchPool({
    required JbcProfile profile,
    required ConchinhaSearchPreference preference,
  });

  Future<void> leaveConchinhaSearchPool(JbcProfile profile);

  /// Idempotente; útil quando outro dispositivo alterou o pool.
  Future<ConchinhaTryMatchResult> tryConchinhaMatch();

  // —— Piaditas (Epic 13) ——

  Stream<List<InsideJoke>> watchInsideJokes();

  Future<String> createInsideJoke({
    required JbcProfile author,
    required String body,
    List<String> tags = const [],
  });

  // —— Emoção do momento (Epic 14) ——

  /// Ordem fixa: Caio, Jojo, Bibi; `null` se ainda não escolheu sticker.
  Stream<List<MomentEmotion?>> watchMomentEmotions();

  Future<void> setMomentSticker({
    required JbcProfile profile,
    required String stickerId,
  });

  // —— Continhas (Epic 15) ——

  Stream<List<JbcCashLedgerEntry>> watchJbcCashLedger();

  Future<void> depositJbcCash({
    required JbcProfile profile,
    required double amountBrl,
    String? note,
  });

  /// Saldo atual da Caixa (BRL), recalculado a partir do ledger.
  Future<double> fetchJbcCashBalanceBrl();

  Stream<List<ContinhasGuest>> watchContinhasGuests();

  Future<String> createContinhasGuest({
    required JbcProfile profile,
    required String displayName,
    required String emoji,
  });

  Future<void> ensureContinhasHangoutOpen(String hangoutId);

  Stream<ContinhasHangoutState?> watchContinhasHangoutState(String hangoutId);

  Stream<List<String>> watchContinhasHangoutGuestIds(String hangoutId);

  Future<void> addContinhasGuestToHangout({
    required String hangoutId,
    required String guestId,
  });

  Future<void> removeContinhasGuestFromHangout({
    required String hangoutId,
    required String guestId,
  });

  Stream<List<ContinhasExpense>> watchContinhasExpenses(String hangoutId);

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
  });

  Future<void> deleteContinhasExpense({
    required String expenseId,
    required JbcProfile deletedBy,
  });

  Future<void> closeContinhasHangout({
    required String hangoutId,
    required JbcProfile closedBy,
    required String hangoutTitle,
  });

  // —— Notificações (Epic 9) ——

  Stream<List<JbcAppNotification>> watchJbcNotifications();

  Future<void> markJbcNotificationRead(String id);

  Future<void> markAllJbcNotificationsRead();

  /// API extensível: novos módulos chamam isto após ações relevantes.
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
  });

  Future<void> upsertFcmDeviceToken({
    required JbcProfile profile,
    required String token,
  });
}

