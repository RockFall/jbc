import 'package:flutter_test/flutter_test.dart';
import 'package:jbc/data/models/availability.dart';
import 'package:jbc/data/models/hangout.dart';
import 'package:jbc/features/hangouts/hangouts_format.dart';
import 'package:jbc/features/hangouts/week_view_layout.dart';

void main() {
  test('mondayOfWeekContaining — segunda da semana ISO', () {
    final wed = DateTime(2024, 10, 23);
    final mon = mondayOfWeekContaining(wed);
    expect(mon.weekday, 1);
    expect(mon.day, 21);
    expect(mon.month, 10);
  });

  test('clipToWindow remove fora da faixa 6h–24h', () {
    const w = WeekGridTimeWindow(firstHour: 6, lastHour: 24);
    expect(clipToWindow(3 * 60, 5 * 60, w), isNull);
    final c = clipToWindow(10 * 60, 12 * 60, w);
    expect(c, isNotNull);
    expect(c!.$1, 10 * 60);
    expect(c.$2, 12 * 60);
  });

  test('hangoutsIntersectingWeek filtra cancelados e data', () {
    final mon = mondayOfWeekContaining(DateTime(2025, 6, 4));
    final list = [
      Hangout(
        id: '1',
        title: 'A',
        date: mon,
        startTime: '18:00',
        endTime: '20:00',
        status: HangoutStatus.planned,
        createdBy: 'caio',
        createdAt: DateTime.utc(2025),
        updatedAt: DateTime.utc(2025),
      ),
      Hangout(
        id: '2',
        title: 'B',
        date: mon.add(const Duration(days: 8)),
        startTime: '18:00',
        status: HangoutStatus.planned,
        createdBy: 'caio',
        createdAt: DateTime.utc(2025),
        updatedAt: DateTime.utc(2025),
      ),
      Hangout(
        id: '3',
        title: 'C',
        date: mon,
        startTime: '18:00',
        status: HangoutStatus.cancelled,
        createdBy: 'caio',
        createdAt: DateTime.utc(2025),
        updatedAt: DateTime.utc(2025),
      ),
    ];
    final inWeek = hangoutsIntersectingWeek(mon, list);
    expect(inWeek.length, 1);
    expect(inWeek.first.id, '1');
  });

  test('dois rolês sobrepostos geram duas colunas no mesmo componente', () {
    final mon = mondayOfWeekContaining(DateTime(2025, 6, 4));
    const w = WeekGridTimeWindow(firstHour: 6, lastHour: 24);
    final hangouts = [
      Hangout(
        id: 'a',
        title: 'R1',
        date: mon,
        startTime: '18:00',
        endTime: '20:00',
        status: HangoutStatus.planned,
        createdBy: 'caio',
        createdAt: DateTime.utc(2025),
        updatedAt: DateTime.utc(2025),
      ),
      Hangout(
        id: 'b',
        title: 'R2',
        date: mon,
        startTime: '18:30',
        endTime: '19:30',
        status: HangoutStatus.planned,
        createdBy: 'jojo',
        createdAt: DateTime.utc(2025),
        updatedAt: DateTime.utc(2025),
      ),
    ];
    final blocks = layoutHangoutsForWeek(weekMonday: mon, hangouts: hangouts, window: w);
    final monBlocks = blocks.where((b) => b.dayIndex == 0).toList();
    expect(monBlocks.length, 2);
    expect(monBlocks.every((b) => b.width <= 0.51), isTrue);
    expect({monBlocks[0].left, monBlocks[1].left}.length, 2);
  });

  test('availabilitiesOnDay respeita visibilidade', () {
    final mon = mondayOfWeekContaining(DateTime(2025, 6, 4));
    final wed = mon.add(const Duration(days: 2));
    final list = [
      Availability(
        id: '1',
        person: 'caio',
        weekday: 3,
        startTime: '09:00',
        endTime: '12:00',
      ),
    ];
    expect(availabilitiesOnDay(wed, list, {'caio'}).length, 1);
    expect(availabilitiesOnDay(wed, list, {'jojo'}).length, 0);
  });
}
