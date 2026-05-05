import 'package:flutter/foundation.dart';

/// Preferência ao pedir conchinha (mapa / modo qualquer lugar).
enum ConchinhaSearchPreference {
  home,
  anywhere;

  String get dbValue => name;

  static ConchinhaSearchPreference parse(String raw) {
    switch (raw) {
      case 'home':
        return ConchinhaSearchPreference.home;
      case 'anywhere':
        return ConchinhaSearchPreference.anywhere;
      default:
        return ConchinhaSearchPreference.anywhere;
    }
  }

  /// Rótulos para UI em pt-BR.
  String get labelBr => switch (this) {
        ConchinhaSearchPreference.home => 'Na minha casa',
        ConchinhaSearchPreference.anywhere => 'Em qualquer lugar',
      };
}

@immutable
class ConchinhaPoolEntry {
  const ConchinhaPoolEntry({
    required this.profileKey,
    required this.preference,
    required this.createdAt,
  });

  final String profileKey;
  final ConchinhaSearchPreference preference;
  final DateTime createdAt;

  static ConchinhaPoolEntry fromRow(Map<String, dynamic> row) {
    return ConchinhaPoolEntry(
      profileKey: row['profile'] as String,
      preference: ConchinhaSearchPreference.parse(row['preference'] as String),
      createdAt: DateTime.parse(row['created_at'] as String),
    );
  }
}

@immutable
class ConchinhaMatchStateRow {
  const ConchinhaMatchStateRow({
    required this.waveId,
    required this.tier,
    required this.dualNotified,
    required this.supremeNotified,
    required this.updatedAt,
  });

  final String waveId;
  final String tier;
  final bool dualNotified;
  final bool supremeNotified;
  final DateTime updatedAt;

  bool get isIdle => tier == 'idle';
  bool get isDual => tier == 'dual';
  bool get isSupreme => tier == 'supreme';

  static ConchinhaMatchStateRow? fromRows(List<Map<String, dynamic>> rows) {
    if (rows.isEmpty) return null;
    final row = rows.first;
    return ConchinhaMatchStateRow(
      waveId: row['wave_id'] as String,
      tier: row['tier'] as String,
      dualNotified: row['dual_notified'] as bool,
      supremeNotified: row['supreme_notified'] as bool,
      updatedAt: DateTime.parse(row['updated_at'] as String),
    );
  }
}

/// Resposta de `conchinha_try_match()` (Supabase RPC).
@immutable
class ConchinhaTryMatchResult {
  const ConchinhaTryMatchResult({
    required this.action,
    required this.poolCount,
    required this.participants,
    required this.waveId,
    this.tier,
  });

  final String action;
  final int poolCount;
  final List<ConchinhaPoolParticipant> participants;
  final String waveId;
  final String? tier;

  static ConchinhaTryMatchResult fromRpc(dynamic raw) {
    if (raw is! Map) {
      return const ConchinhaTryMatchResult(
        action: 'wait',
        poolCount: 0,
        participants: [],
        waveId: '',
      );
    }
    final m = Map<String, dynamic>.from(raw);
    final action = m['action'] as String? ?? 'wait';
    final poolCount = (m['pool_count'] as num?)?.toInt() ?? 0;
    final waveId = m['wave_id'] as String? ?? '';
    final tier = m['tier'] as String?;
    final pRaw = m['participants'];
    final participants = <ConchinhaPoolParticipant>[];
    if (pRaw is List) {
      for (final e in pRaw) {
        if (e is Map) {
          participants.add(
            ConchinhaPoolParticipant(
              profileKey: e['profile'] as String? ?? '',
              preference: ConchinhaSearchPreference.parse(e['preference'] as String? ?? ''),
            ),
          );
        }
      }
    }
    return ConchinhaTryMatchResult(
      action: action,
      poolCount: poolCount,
      participants: participants,
      waveId: waveId,
      tier: tier,
    );
  }

  bool get shouldNotifyDual => action == 'dual';
  bool get shouldNotifySupreme =>
      action == 'supreme_upgrade' || action == 'supreme_direct';
}

@immutable
class ConchinhaPoolParticipant {
  const ConchinhaPoolParticipant({
    required this.profileKey,
    required this.preference,
  });

  final String profileKey;
  final ConchinhaSearchPreference preference;
}
