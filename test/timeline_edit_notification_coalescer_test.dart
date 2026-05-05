import 'package:flutter_test/flutter_test.dart';
import 'package:jbc/core/notifications/timeline_edit_notification_coalescer.dart';
import 'package:jbc/core/profile/jbc_profile.dart';

void main() {
  test('TimelineEditDelta.describePt combina várias alterações', () {
    final d = TimelineEditDelta(
      photosAdded: 2,
      photosRemoved: 0,
      titleChanged: true,
      descriptionChanged: false,
      dateChanged: true,
    );
    expect(
      d.describePt(),
      'adicionou 2 fotos · alterou o título · moveu a data',
    );
  });

  test('TimelineEditDelta.merge acumula contagens', () {
    final a = TimelineEditDelta(photosAdded: 1, titleChanged: true);
    final b = TimelineEditDelta(photosAdded: 2, descriptionChanged: true);
    a.merge(b);
    expect(a.photosAdded, 3);
    expect(a.titleChanged, true);
    expect(a.descriptionChanged, true);
  });

  test('TimelineEditDelta.isEmpty', () {
    expect(TimelineEditDelta().isEmpty, true);
    expect(TimelineEditDelta(titleChanged: true).isEmpty, false);
  });

  test('coalescer agrupa múltiplos schedule antes do flush', () async {
    final flushed = <String>[];
    final coalescer = TimelineEditNotificationCoalescer(
      debounce: const Duration(milliseconds: 30),
      onFlush: (id, actor, delta) async {
        flushed.add('${actor.storageKey}|$id|${delta.describePt()}');
      },
    );

    coalescer.schedule(
      timelineEventId: 'e1',
      actor: JbcProfile.caio,
      delta: TimelineEditDelta(titleChanged: true),
    );
    coalescer.schedule(
      timelineEventId: 'e1',
      actor: JbcProfile.caio,
      delta: TimelineEditDelta(photosAdded: 1),
    );

    await Future<void>.delayed(const Duration(milliseconds: 80));
    expect(flushed.length, 1);
    expect(flushed.first, 'caio|e1|adicionou 1 foto · alterou o título');
  });
}
