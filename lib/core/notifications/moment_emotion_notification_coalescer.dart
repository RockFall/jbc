import 'dart:async';

import '../profile/jbc_profile.dart';

typedef MomentEmotionNotificationFlush = Future<void> Function(JbcProfile actor);

/// Uma notificação in-app após [debounce] sem novas mudanças do mesmo perfil (Epic 14).
class MomentEmotionNotificationCoalescer {
  MomentEmotionNotificationCoalescer({
    this.debounce = const Duration(seconds: 4),
    required MomentEmotionNotificationFlush onFlush,
  }) : _onFlush = onFlush;

  final Duration debounce;
  final MomentEmotionNotificationFlush _onFlush;

  final Map<String, Timer> _timers = {};

  void schedule(JbcProfile actor) {
    final key = actor.storageKey;
    _timers[key]?.cancel();
    _timers[key] = Timer(debounce, () {
      _timers.remove(key);
      unawaited(_onFlush(actor));
    });
  }
}
