/// Origem do evento na timeline (`project_definition` §5.1).
enum TimelineEventOrigin {
  manual,
  fromHangout;

  static TimelineEventOrigin fromDb(String value) {
    switch (value) {
      case 'manual':
        return TimelineEventOrigin.manual;
      case 'from_hangout':
        return TimelineEventOrigin.fromHangout;
      default:
        return TimelineEventOrigin.manual;
    }
  }

  String get dbValue {
    switch (this) {
      case TimelineEventOrigin.manual:
        return 'manual';
      case TimelineEventOrigin.fromHangout:
        return 'from_hangout';
    }
  }
}

class TimelineEvent {
  const TimelineEvent({
    required this.id,
    required this.occurredAt,
    required this.title,
    required this.description,
    this.imageUrl,
    required this.createdBy,
    required this.origin,
    this.hangoutId,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final DateTime occurredAt;
  final String title;
  final String description;
  final String? imageUrl;
  final String createdBy;
  final TimelineEventOrigin origin;
  final String? hangoutId;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory TimelineEvent.fromRow(Map<String, dynamic> row) {
    return TimelineEvent(
      id: row['id'] as String,
      occurredAt: DateTime.parse(row['occurred_at'] as String),
      title: row['title'] as String,
      description: row['description'] as String? ?? '',
      imageUrl: row['image_url'] as String?,
      createdBy: row['created_by'] as String,
      origin: TimelineEventOrigin.fromDb(row['origin'] as String? ?? 'manual'),
      hangoutId: row['hangout_id'] as String?,
      createdAt: DateTime.parse(row['created_at'] as String),
      updatedAt: DateTime.parse(row['updated_at'] as String),
    );
  }
}
