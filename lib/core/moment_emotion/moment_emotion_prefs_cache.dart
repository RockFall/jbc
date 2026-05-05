import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../data/models/moment_emotion.dart';

/// Último snapshot das emoções (Epic 14 DoD: cache offline simples).
class MomentEmotionPrefsCache {
  MomentEmotionPrefsCache(this._prefs);

  final SharedPreferences _prefs;
  static const _key = 'jbc_moment_emotions_v1';

  Future<void> saveSnapshot(List<MomentEmotion?> slots) async {
    final encoded = jsonEncode(
      slots.map((e) => e?.toJson()).toList(),
    );
    await _prefs.setString(_key, encoded);
  }

  /// Três entradas na ordem [caio, jojo, bibi]; pode conter `null`.
  List<MomentEmotion?>? readSnapshot() {
    final raw = _prefs.getString(_key);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      final out = <MomentEmotion?>[];
      for (final item in decoded) {
        if (item == null) {
          out.add(null);
        } else {
          out.add(MomentEmotion.fromJsonMap(item));
        }
      }
      return out;
    } catch (_) {
      return null;
    }
  }
}
