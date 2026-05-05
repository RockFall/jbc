/// Chave estável para saldos e netting: `p:caio` ou `g:<uuid>`.
abstract final class ContinhasParticipantKey {
  static const profilePrefix = 'p:';
  static const guestPrefix = 'g:';

  static String profile(String storageKey) => '$profilePrefix$storageKey';

  static String guest(String guestId) => '$guestPrefix$guestId';

  static bool isProfile(String key) => key.startsWith(profilePrefix);

  static bool isGuest(String key) => key.startsWith(guestPrefix);

  static String? profileStorageKey(String key) {
    if (!isProfile(key)) return null;
    return key.substring(profilePrefix.length);
  }

  static String? guestId(String key) {
    if (!isGuest(key)) return null;
    return key.substring(guestPrefix.length);
  }
}
