import 'package:flutter/material.dart';

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
