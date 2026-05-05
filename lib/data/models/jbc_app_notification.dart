import '../../core/notifications/jbc_notification_module.dart';

class JbcAppNotification {
  const JbcAppNotification({
    required this.id,
    required this.module,
    required this.eventType,
    required this.actorKey,
    required this.title,
    this.body,
    this.entityId,
    required this.createdAt,
    this.readAt,
    this.payload = const {},
  });

  final String id;
  final String module;
  final String eventType;
  final String actorKey;
  final String title;
  final String? body;
  final String? entityId;
  final DateTime createdAt;
  final DateTime? readAt;
  final Map<String, dynamic> payload;

  bool get isRead => readAt != null;

  JbcNotificationModule? get moduleEnum => JbcNotificationModule.tryParse(module);

  static JbcAppNotification fromRow(Map<String, dynamic> row) {
    final payloadRaw = row['payload'];
    Map<String, dynamic> payload = const {};
    if (payloadRaw is Map) {
      payload = Map<String, dynamic>.from(payloadRaw);
    }
    return JbcAppNotification(
      id: row['id'] as String,
      module: row['module'] as String,
      eventType: row['event_type'] as String,
      actorKey: row['actor'] as String,
      title: row['title'] as String,
      body: row['body'] as String?,
      entityId: row['entity_id'] as String?,
      createdAt: DateTime.parse(row['created_at'] as String),
      readAt: row['read_at'] != null
          ? DateTime.parse(row['read_at'] as String)
          : null,
      payload: payload,
    );
  }
}
