import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../data/models/hangout.dart';

/// ISO weekday: 1 = segunda … 7 = domingo.
String weekdayLabelPt(int weekday) {
  const names = [
    'Segunda-feira',
    'Terça-feira',
    'Quarta-feira',
    'Quinta-feira',
    'Sexta-feira',
    'Sábado',
    'Domingo',
  ];
  if (weekday < 1 || weekday > 7) return 'Dia $weekday';
  return names[weekday - 1];
}

String hangoutStatusLabelPt(HangoutStatus s) {
  switch (s) {
    case HangoutStatus.planned:
      return 'Planejado';
    case HangoutStatus.happened:
      return 'Aconteceu';
    case HangoutStatus.cancelled:
      return 'Cancelado';
  }
}

String formatTimeOfDay(TimeOfDay t) =>
    '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

TimeOfDay parseTimeHhMm(String hhmm) {
  final p = hhmm.split(':');
  final h = int.tryParse(p[0]) ?? 0;
  final m = p.length > 1 ? (int.tryParse(p[1]) ?? 0) : 0;
  return TimeOfDay(hour: h.clamp(0, 23), minute: m.clamp(0, 59));
}

DateTime hangoutDateOnly(DateTime d) =>
    DateTime(d.year, d.month, d.day);

DateTime _mondayOfWeekContaining(DateTime dayLocal) {
  final x = hangoutDateOnly(dayLocal);
  return x.subtract(Duration(days: x.weekday - 1));
}

/// Segunda … Domingo (curto, para “Essa quarta”).
String weekdayShortPt(int weekday) {
  const names = [
    'Segunda',
    'Terça',
    'Quarta',
    'Quinta',
    'Sexta',
    'Sábado',
    'Domingo',
  ];
  if (weekday < 1 || weekday > 7) return 'Dia $weekday';
  return names[weekday - 1];
}

/// Data amigável em português: “Hoje”, “Essa quarta”, “Terça da semana que vem”, etc.
/// Requer `initializeDateFormatting('pt_BR')` no startup para o fallback longo.
String formatHangoutDateRelativePt(DateTime date) {
  final d = hangoutDateOnly(date.toLocal());
  final today = hangoutDateOnly(DateTime.now());
  final diffDays = d.difference(today).inDays;

  if (d == today) return 'Hoje';
  if (diffDays == 1) return 'Amanhã';
  if (diffDays == -1) return 'Ontem';

  final monThis = _mondayOfWeekContaining(today);
  final monThat = _mondayOfWeekContaining(d);
  final weekDiff = monThat.difference(monThis).inDays ~/ 7;

  final wd = weekdayShortPt(d.weekday);
  if (weekDiff == 0) return 'Essa $wd';
  if (weekDiff == 1) return '$wd da semana que vem';
  if (weekDiff == -1) return '$wd passada';

  try {
    return DateFormat("EEEE, d 'de' MMMM 'de' y", 'pt_BR').format(d);
  } catch (_) {
    return DateFormat('dd/MM/y').format(d);
  }
}
