import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/availability.dart';
import '../data/models/conchinha_acceptance.dart';
import '../data/models/conchinha_match_models.dart';
import '../data/models/conchinha_request.dart';
import '../data/models/continhas_expense.dart';
import '../data/models/continhas_guest.dart';
import '../data/models/continhas_hangout_state.dart';
import '../data/models/hangout.dart';
import '../data/models/jbc_cash_ledger_entry.dart';
import '../data/models/idea.dart';
import '../data/models/inside_joke.dart';
import '../data/models/moment_emotion.dart';
import '../data/models/jbc_app_notification.dart';
import '../data/models/timeline_event.dart';
import '../data/models/timeline_event_comment.dart';
import '../data/models/timeline_event_reaction.dart';
import '../data/repositories/jbc_repository.dart';
import 'bootstrap.dart';
import 'continhas/continhas_money.dart';
import 'moment_emotion/moment_emotion_prefs_cache.dart';
import 'profile/jbc_profile.dart';
import 'profile/profile_store.dart';

/// Sobrescrito em `main` com [AppBootstrap.load].
final bootstrapProvider = Provider<AppBootstrap>((ref) {
  throw UnimplementedError('bootstrapProvider não inicializado');
});

final momentEmotionCacheProvider = Provider<MomentEmotionPrefsCache>(
  (ref) => ref.watch(bootstrapProvider).momentEmotionCache,
);

final repositoryProvider = Provider<JbcRepository>(
  (ref) => ref.watch(bootstrapProvider).repository,
);

final hasRemoteProvider = Provider<bool>(
  (ref) => ref.watch(bootstrapProvider).hasRemote,
);

final profileStoreProvider = Provider<ProfileStore>(
  (ref) => ref.watch(bootstrapProvider).profileStore,
);

final userProfileProvider = NotifierProvider<UserProfile, JbcProfile?>(
  UserProfile.new,
);

class UserProfile extends Notifier<JbcProfile?> {
  @override
  JbcProfile? build() {
    return ref.read(bootstrapProvider).profileStore.profile;
  }

  Future<void> setProfile(JbcProfile profile) async {
    await ref.read(bootstrapProvider).profileStore.setProfile(profile);
    state = profile;
  }
}

final timelineEventsProvider = StreamProvider<List<TimelineEvent>>((ref) {
  return ref.watch(repositoryProvider).watchTimelineEvents();
});

final timelineEventCommentsProvider =
    StreamProvider.family<List<TimelineEventComment>, String>((ref, eventId) {
  return ref.watch(repositoryProvider).watchTimelineEventComments(eventId);
});

final timelineEventReactionsProvider =
    StreamProvider.family<List<TimelineEventReaction>, String>((ref, eventId) {
  return ref.watch(repositoryProvider).watchTimelineEventReactions(eventId);
});

final hangoutsProvider = StreamProvider<List<Hangout>>((ref) {
  return ref.watch(repositoryProvider).watchHangouts();
});

final availabilitiesProvider = StreamProvider<List<Availability>>((ref) {
  return ref.watch(repositoryProvider).watchAvailabilities();
});

final ideasProvider = StreamProvider<List<Idea>>((ref) {
  return ref.watch(repositoryProvider).watchIdeas();
});

final jbcAppNotificationsProvider = StreamProvider<List<JbcAppNotification>>((ref) {
  return ref.watch(repositoryProvider).watchJbcNotifications();
});

final jbcUnreadNotificationCountProvider = Provider<AsyncValue<int>>((ref) {
  final async = ref.watch(jbcAppNotificationsProvider);
  return async.whenData((list) => list.where((n) => !n.isRead).length);
});

final conchinhaRequestsProvider = StreamProvider<List<ConchinhaRequest>>((ref) {
  return ref.watch(repositoryProvider).watchConchinhaRequests();
});

final conchinhaRequestProvider = StreamProvider.family<ConchinhaRequest?, String>((ref, requestId) {
  return ref.watch(repositoryProvider).watchConchinhaRequest(requestId);
});

final conchinhaAcceptancesProvider =
    StreamProvider.family<List<ConchinhaAcceptance>, String>((ref, requestId) {
  return ref.watch(repositoryProvider).watchConchinhaAcceptances(requestId);
});

final conchinhaSearchPoolProvider = StreamProvider<List<ConchinhaPoolEntry>>((ref) {
  return ref.watch(repositoryProvider).watchConchinhaSearchPool();
});

final conchinhaMatchStateProvider = StreamProvider<ConchinhaMatchStateRow?>((ref) {
  return ref.watch(repositoryProvider).watchConchinhaMatchState();
});

final insideJokesProvider = StreamProvider<List<InsideJoke>>((ref) {
  return ref.watch(repositoryProvider).watchInsideJokes();
});

final momentEmotionsProvider = StreamProvider<List<MomentEmotion?>>((ref) {
  return ref.watch(repositoryProvider).watchMomentEmotions();
});

final jbcCashLedgerProvider = StreamProvider<List<JbcCashLedgerEntry>>((ref) {
  return ref.watch(repositoryProvider).watchJbcCashLedger();
});

final jbcCashBalanceBrlProvider = Provider<AsyncValue<double>>((ref) {
  final async = ref.watch(jbcCashLedgerProvider);
  return async.whenData((entries) {
    var cents = 0;
    for (final e in entries) {
      final c = brlToCents(e.amountBrl);
      switch (e.type) {
        case JbcCashLedgerType.deposit:
          cents += c;
        case JbcCashLedgerType.hangoutExpenseDebit:
          cents -= c;
      }
    }
    return double.parse(centsToBrl(cents).toStringAsFixed(2));
  });
});

final continhasGuestsProvider = StreamProvider<List<ContinhasGuest>>((ref) {
  return ref.watch(repositoryProvider).watchContinhasGuests();
});

final continhasHangoutStateProvider =
    StreamProvider.family<ContinhasHangoutState?, String>((ref, hangoutId) {
  return ref.watch(repositoryProvider).watchContinhasHangoutState(hangoutId);
});

final continhasHangoutGuestIdsProvider =
    StreamProvider.family<List<String>, String>((ref, hangoutId) {
  return ref.watch(repositoryProvider).watchContinhasHangoutGuestIds(hangoutId);
});

final continhasExpensesProvider =
    StreamProvider.family<List<ContinhasExpense>, String>((ref, hangoutId) {
  return ref.watch(repositoryProvider).watchContinhasExpenses(hangoutId);
});
