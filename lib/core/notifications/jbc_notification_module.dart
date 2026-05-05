/// Módulo de origem (valor persistido em `jbc_notifications.module`).
enum JbcNotificationModule {
  timeline('timeline'),
  hangouts('hangouts'),
  ideas('ideas'),
  conchinha('conchinha'),
  piaditas('piaditas'),
  momentEmotion('moment_emotion'),
  continhas('continhas');

  const JbcNotificationModule(this.dbValue);

  final String dbValue;

  static JbcNotificationModule? tryParse(String raw) {
    for (final m in JbcNotificationModule.values) {
      if (m.dbValue == raw) return m;
    }
    return null;
  }

  String get displayLabelPt {
    switch (this) {
      case JbcNotificationModule.timeline:
        return 'Linha do tempo';
      case JbcNotificationModule.hangouts:
        return 'Rolês';
      case JbcNotificationModule.ideas:
        return 'Cantinho de ideias';
      case JbcNotificationModule.conchinha:
        return 'Conchinha';
      case JbcNotificationModule.piaditas:
        return 'Piaditas';
      case JbcNotificationModule.momentEmotion:
        return 'Emoção do momento';
      case JbcNotificationModule.continhas:
        return 'Continhas';
    }
  }
}
