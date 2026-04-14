import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/availability.dart';
import '../data/models/hangout.dart';
import '../data/models/idea.dart';
import '../data/models/timeline_event.dart';
import '../data/models/timeline_event_comment.dart';
import '../data/repositories/jbc_repository.dart';
import 'bootstrap.dart';
import 'profile/jbc_profile.dart';
import 'profile/profile_store.dart';

/// Sobrescrito em `main` com [AppBootstrap.load].
final bootstrapProvider = Provider<AppBootstrap>((ref) {
  throw UnimplementedError('bootstrapProvider não inicializado');
});

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

final hangoutsProvider = StreamProvider<List<Hangout>>((ref) {
  return ref.watch(repositoryProvider).watchHangouts();
});

final availabilitiesProvider = StreamProvider<List<Availability>>((ref) {
  return ref.watch(repositoryProvider).watchAvailabilities();
});

final ideasProvider = StreamProvider<List<Idea>>((ref) {
  return ref.watch(repositoryProvider).watchIdeas();
});
