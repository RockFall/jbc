import '../../data/models/availability.dart';
import '../../data/models/hangout.dart';
import 'hangouts_format.dart';

/// Janela vertical da grade: [firstHour] inclusivo … [lastHour] exclusivo (ex.: 6–24 → até 24:00).
class WeekGridTimeWindow {
  const WeekGridTimeWindow({this.firstHour = 6, this.lastHour = 24});

  final int firstHour;
  final int lastHour;

  int get originMinutes => firstHour * 60;

  int get spanMinutes => (lastHour - firstHour) * 60;
}

int parseHhMmToMinutes(String hhmm) {
  final t = parseTimeHhMm(hhmm);
  return t.hour * 60 + t.minute;
}

/// [start, end) em minutos do dia; [end] ajustado se inválido ou ausente.
(int start, int end) hangoutDayMinutes(Hangout h) {
  var s = parseHhMmToMinutes(h.startTime);
  var e = h.endTime != null && h.endTime!.trim().isNotEmpty ? parseHhMmToMinutes(h.endTime!) : s + 60;
  if (e <= s) {
    e = s + 60;
  }
  return (s, e);
}

(int start, int end) availabilityDayMinutes(Availability a) {
  final s = parseHhMmToMinutes(a.startTime);
  var e = parseHhMmToMinutes(a.endTime);
  if (e <= s) {
    e = s + 60;
  }
  return (s, e);
}

/// Converte minutos do dia para posição vertical 0…1 dentro da [window].
double normalizedYFromMinutes(int minutes, WeekGridTimeWindow window) {
  final span = window.spanMinutes;
  if (span <= 0) return 0;
  final rel = (minutes - window.originMinutes).clamp(0, span);
  return rel / span;
}

double normalizedHeightFromMinutes(int startMin, int endMin, WeekGridTimeWindow window) {
  final span = window.spanMinutes;
  if (span <= 0) return 0;
  final a = (startMin - window.originMinutes).clamp(0, span);
  final b = (endMin - window.originMinutes).clamp(0, span);
  return ((b - a) / span).clamp(0.0, 1.0);
}

(int clipStart, int clipEnd)? clipToWindow(int startMin, int endMin, WeekGridTimeWindow window) {
  final ws = window.originMinutes;
  final we = window.originMinutes + window.spanMinutes;
  final cs = startMin < ws ? ws : startMin;
  final ce = endMin > we ? we : endMin;
  if (ce <= cs) return null;
  return (cs, ce);
}

bool intervalsOverlapHalfOpen(int a0, int a1, int b0, int b1) {
  return a0 < b1 && b0 < a1;
}

/// Rolês num [day] civil local, excluindo cancelados.
List<Hangout> hangoutsOnDay(DateTime day, List<Hangout> hangouts) {
  final d0 = hangoutDateOnly(day);
  return hangouts.where((h) {
    if (h.status == HangoutStatus.cancelled) return false;
    return hangoutDateOnly(h.date) == d0;
  }).toList();
}

/// Indisponibilidades que se aplicam ao [day] (weekday ISO).
List<Availability> availabilitiesOnDay(DateTime day, List<Availability> all, Set<String> visiblePeople) {
  final wd = day.weekday;
  return all.where((a) {
    if (!visiblePeople.contains(a.person)) return false;
    return a.weekday == wd;
  }).toList();
}

/// Agrupa índices de [starts]/[ends] por sobreposição (transitiva).
List<List<int>> overlapComponents(List<int> starts, List<int> ends) {
  final n = starts.length;
  final adj = List.generate(n, (_) => <int>{});
  for (var i = 0; i < n; i++) {
    for (var j = i + 1; j < n; j++) {
      if (intervalsOverlapHalfOpen(starts[i], ends[i], starts[j], ends[j])) {
        adj[i].add(j);
        adj[j].add(i);
      }
    }
  }
  final seen = List.filled(n, false);
  final out = <List<int>>[];
  for (var i = 0; i < n; i++) {
    if (seen[i]) continue;
    final comp = <int>[];
    final q = <int>[i];
    seen[i] = true;
    while (q.isNotEmpty) {
      final u = q.removeLast();
      comp.add(u);
      for (final v in adj[u]) {
        if (!seen[v]) {
          seen[v] = true;
          q.add(v);
        }
      }
    }
    out.add(comp);
  }
  return out;
}

/// Greedy: menor faixa livre com [lastExclusiveEnd] por faixa (fim exclusivo do intervalo ocupado).
List<int> assignLanes(List<int> starts, List<int> ends) {
  final order = List<int>.generate(starts.length, (i) => i)
    ..sort((a, b) {
      final c = starts[a].compareTo(starts[b]);
      if (c != 0) return c;
      return ends[a].compareTo(ends[b]);
    });
  final lastEnd = <int, int>{};
  final lanes = List<int>.filled(starts.length, 0);
  for (final i in order) {
    final s = starts[i];
    final e = ends[i];
    var L = 0;
    while (true) {
      final prev = lastEnd[L];
      if (prev == null || prev <= s) {
        lastEnd[L] = e;
        lanes[i] = L;
        break;
      }
      L++;
    }
  }
  return lanes;
}

/// Por dia: blocos de rolê com frações horizontais (faixa / numFaixas no componente).
class HangoutWeekBlock {
  const HangoutWeekBlock({
    required this.hangout,
    required this.dayIndex,
    required this.top,
    required this.height,
    required this.left,
    required this.width,
  });

  final Hangout hangout;
  final int dayIndex;
  final double top;
  final double height;
  final double left;
  final double width;
}

/// [weekMonday]: segunda 00:00 local. [dayIndex] 0 = segunda … 6 = domingo.
List<HangoutWeekBlock> layoutHangoutsForWeek({
  required DateTime weekMonday,
  required List<Hangout> hangouts,
  required WeekGridTimeWindow window,
}) {
  final blocks = <HangoutWeekBlock>[];
  for (var dayIndex = 0; dayIndex < 7; dayIndex++) {
    final day = weekMonday.add(Duration(days: dayIndex));
    final dayList = hangoutsOnDay(day, hangouts);
    if (dayList.isEmpty) continue;

    final indicesByHangout = <Hangout>[];
    final filteredStarts = <int>[];
    final filteredEnds = <int>[];
    for (var i = 0; i < dayList.length; i++) {
      final h = dayList[i];
      final (s0, e0) = hangoutDayMinutes(h);
      final clipped = clipToWindow(s0, e0, window);
      if (clipped == null) continue;
      indicesByHangout.add(h);
      filteredStarts.add(clipped.$1);
      filteredEnds.add(clipped.$2);
    }
    if (indicesByHangout.isEmpty) continue;

    final comps = overlapComponents(filteredStarts, filteredEnds);
    for (final comp in comps) {
      final ss = <int>[];
      final ee = <int>[];
      for (final idx in comp) {
        ss.add(filteredStarts[idx]);
        ee.add(filteredEnds[idx]);
      }
      final lanes = assignLanes(ss, ee);
      var maxLane = 0;
      for (final L in lanes) {
        if (L > maxLane) maxLane = L;
      }
      final k = maxLane + 1;
      for (var j = 0; j < comp.length; j++) {
        final globalIdx = comp[j];
        final h = indicesByHangout[globalIdx];
        final s = filteredStarts[globalIdx];
        final e = filteredEnds[globalIdx];
        final lane = lanes[j];
        blocks.add(
          HangoutWeekBlock(
            hangout: h,
            dayIndex: dayIndex,
            top: normalizedYFromMinutes(s, window),
            height: normalizedHeightFromMinutes(s, e, window).clamp(0.02, 1.0),
            left: lane / k,
            width: 1 / k,
          ),
        );
      }
    }
  }
  return blocks;
}

class AvailabilityWeekBlock {
  const AvailabilityWeekBlock({
    required this.availability,
    required this.dayIndex,
    required this.top,
    required this.height,
  });

  final Availability availability;
  final int dayIndex;
  final double top;
  final double height;
}

List<AvailabilityWeekBlock> layoutAvailabilitiesForWeek({
  required DateTime weekMonday,
  required List<Availability> availabilities,
  required Set<String> visiblePeople,
  required WeekGridTimeWindow window,
}) {
  final out = <AvailabilityWeekBlock>[];
  for (var dayIndex = 0; dayIndex < 7; dayIndex++) {
    final day = weekMonday.add(Duration(days: dayIndex));
    final list = availabilitiesOnDay(day, availabilities, visiblePeople);
    for (final a in list) {
      final (s0, e0) = availabilityDayMinutes(a);
      final clipped = clipToWindow(s0, e0, window);
      if (clipped == null) continue;
      final s = clipped.$1;
      final e = clipped.$2;
      out.add(
        AvailabilityWeekBlock(
          availability: a,
          dayIndex: dayIndex,
          top: normalizedYFromMinutes(s, window),
          height: normalizedHeightFromMinutes(s, e, window).clamp(0.02, 1.0),
        ),
      );
    }
  }
  return out;
}

/// Rolês cuja data civil está em [weekMonday, weekMonday+7).
List<Hangout> hangoutsIntersectingWeek(DateTime weekMonday, List<Hangout> hangouts) {
  final start = hangoutDateOnly(weekMonday);
  final endEx = start.add(const Duration(days: 7));
  return hangouts.where((h) {
    if (h.status == HangoutStatus.cancelled) return false;
    final d = hangoutDateOnly(h.date);
    return !d.isBefore(start) && d.isBefore(endEx);
  }).toList();
}
