import '../data/models/availability.dart';

/// Minutos desde meia-noite para string "HH:mm".
int hhmmToMinutes(String hhmm) {
  final parts = hhmm.trim().split(':');
  if (parts.length != 2) return 0;
  final h = int.tryParse(parts[0]) ?? 0;
  final m = int.tryParse(parts[1]) ?? 0;
  return h * 60 + m.clamp(0, 59);
}

/// Sobreposição em intervalos **inclusivos** nos minutos do dia (suficiente para o trio).
bool _intervalsOverlapInclusive(int aStart, int aEnd, int bStart, int bEnd) {
  return aStart <= bEnd && bStart <= aEnd;
}

/// Se o rolê não tem horário final, assume **1 hora** de duração (definição do produto v1).
int hangoutEffectiveEndMinutes(String startTime, String? endTime) {
  final start = hhmmToMinutes(startTime);
  if (endTime != null && endTime.trim().isNotEmpty) {
    return hhmmToMinutes(endTime);
  }
  return (start + 60).clamp(0, 24 * 60 - 1);
}

/// Retorna as chaves de perfil (`caio`, `jojo`, `bibi`) em conflito com o rolê.
Set<String> conflictingPersonKeys({
  required DateTime hangoutDateLocal,
  required String hangoutStartTime,
  required String? hangoutEndTime,
  required List<Availability> allAvailabilities,
}) {
  final weekday = hangoutDateLocal.weekday;
  final hStart = hhmmToMinutes(hangoutStartTime);
  final hEnd = hangoutEffectiveEndMinutes(hangoutStartTime, hangoutEndTime);
  if (hEnd < hStart) {
    // Faixa inválida no rolê: não sinaliza conflito (validação fica no formulário).
    return {};
  }

  final conflicts = <String>{};
  for (final a in allAvailabilities) {
    if (a.weekday != weekday) continue;
    final aStart = hhmmToMinutes(a.startTime);
    final aEnd = hhmmToMinutes(a.endTime);
    if (aEnd < aStart) continue;
    if (_intervalsOverlapInclusive(hStart, hEnd, aStart, aEnd)) {
      conflicts.add(a.person);
    }
  }
  return conflicts;
}
