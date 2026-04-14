import 'package:shared_preferences/shared_preferences.dart';

import 'jbc_profile.dart';

class ProfileStore {
  ProfileStore(this._prefs);

  final SharedPreferences _prefs;

  static const _key = 'jbc_profile';

  JbcProfile? get profile {
    final raw = _prefs.getString(_key);
    if (raw == null) return null;
    for (final p in JbcProfile.values) {
      if (p.storageKey == raw) return p;
    }
    return null;
  }

  Future<void> setProfile(JbcProfile profile) async {
    await _prefs.setString(_key, profile.storageKey);
  }

  Future<void> clear() async {
    await _prefs.remove(_key);
  }
}
