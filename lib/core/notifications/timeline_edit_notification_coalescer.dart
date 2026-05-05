import 'dart:async';

import '../profile/jbc_profile.dart';

/// Acumula alterações na mesma memória pelo mesmo ator antes de gerar uma notificação.
class TimelineEditDelta {
  TimelineEditDelta({
    this.photosAdded = 0,
    this.photosRemoved = 0,
    this.titleChanged = false,
    this.descriptionChanged = false,
    this.dateChanged = false,
  });

  int photosAdded;
  int photosRemoved;
  bool titleChanged;
  bool descriptionChanged;
  bool dateChanged;

  bool get isEmpty =>
      photosAdded <= 0 &&
      photosRemoved <= 0 &&
      !titleChanged &&
      !descriptionChanged &&
      !dateChanged;

  void merge(TimelineEditDelta other) {
    photosAdded += other.photosAdded;
    photosRemoved += other.photosRemoved;
    titleChanged = titleChanged || other.titleChanged;
    descriptionChanged = descriptionChanged || other.descriptionChanged;
    dateChanged = dateChanged || other.dateChanged;
  }

  /// Frases curtas em PT-BR (uma linha com “ · ”).
  String describePt() {
    final parts = <String>[];
    if (photosAdded > 0) {
      parts.add(photosAdded == 1 ? 'adicionou 1 foto' : 'adicionou $photosAdded fotos');
    }
    if (photosRemoved > 0) {
      parts.add(photosRemoved == 1 ? 'removeu 1 foto' : 'removeu $photosRemoved fotos');
    }
    if (titleChanged) parts.add('alterou o título');
    if (descriptionChanged) parts.add('alterou a descrição');
    if (dateChanged) parts.add('moveu a data');
    return parts.join(' · ');
  }
}

typedef TimelineEditFlush = Future<void> Function(
  String timelineEventId,
  JbcProfile actor,
  TimelineEditDelta delta,
);

/// Uma única notificação após [debounce] sem novas edições (por par evento+ator).
class TimelineEditNotificationCoalescer {
  TimelineEditNotificationCoalescer({
    this.debounce = const Duration(seconds: 45),
    required TimelineEditFlush onFlush,
  }) : _onFlush = onFlush;

  final Duration debounce;
  final TimelineEditFlush _onFlush;

  final Map<String, _Bucket> _buckets = {};

  String _key(String timelineEventId, JbcProfile actor) =>
      '$timelineEventId|${actor.storageKey}';

  void schedule({
    required String timelineEventId,
    required JbcProfile actor,
    required TimelineEditDelta delta,
  }) {
    if (delta.isEmpty) return;
    final key = _key(timelineEventId, actor);
    final bucket = _buckets.putIfAbsent(key, _Bucket.new);
    bucket.delta.merge(delta);
    bucket.timer?.cancel();
    bucket.timer = Timer(debounce, () {
      final b = _buckets.remove(key);
      if (b == null) return;
      final d = b.delta;
      if (!d.isEmpty) {
        unawaited(_onFlush(timelineEventId, actor, d));
      }
    });
  }
}

class _Bucket {
  TimelineEditDelta delta = TimelineEditDelta();
  Timer? timer;
}
