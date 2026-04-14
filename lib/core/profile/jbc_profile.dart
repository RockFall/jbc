/// Perfis fixos do produto (apenas Caio, Jojo e Bibi).
enum JbcProfile {
  caio,
  jojo,
  bibi;

  String get displayName {
    switch (this) {
      case JbcProfile.caio:
        return 'Caio';
      case JbcProfile.jojo:
        return 'Jojo';
      case JbcProfile.bibi:
        return 'Bibi';
    }
  }

  /// Valor persistido em `SharedPreferences` e colunas `created_by` / `person`.
  String get storageKey => name;

  static String displayNameForStorageKey(String key) {
    for (final p in JbcProfile.values) {
      if (p.storageKey == key) return p.displayName;
    }
    return key;
  }
}
