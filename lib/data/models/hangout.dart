enum HangoutStatus {
  planned,
  happened,
  cancelled;

  static HangoutStatus fromDb(String value) {
    switch (value) {
      case 'planned':
        return HangoutStatus.planned;
      case 'happened':
        return HangoutStatus.happened;
      case 'cancelled':
        return HangoutStatus.cancelled;
      default:
        return HangoutStatus.planned;
    }
  }

  String get dbValue {
    switch (this) {
      case HangoutStatus.planned:
        return 'planned';
      case HangoutStatus.happened:
        return 'happened';
      case HangoutStatus.cancelled:
        return 'cancelled';
    }
  }
}

class Hangout {
  const Hangout({
    required this.id,
    required this.title,
    this.description,
    required this.date,
    required this.startTime,
    this.endTime,
    required this.status,
    required this.createdBy,
    this.notes,
    this.timelineEventId,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final String? description;
  final DateTime date;
  final String startTime;
  final String? endTime;
  final HangoutStatus status;
  final String createdBy;
  final String? notes;
  final String? timelineEventId;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory Hangout.fromRow(Map<String, dynamic> row) {
    final raw = row['date'] as String;
    final p = raw.split('-').map(int.parse).toList();
    final localDate = DateTime(p[0], p[1], p[2]);
    return Hangout(
      id: row['id'] as String,
      title: row['title'] as String,
      description: row['description'] as String?,
      date: localDate,
      startTime: row['start_time'] as String,
      endTime: row['end_time'] as String?,
      status: HangoutStatus.fromDb(row['status'] as String? ?? 'planned'),
      createdBy: row['created_by'] as String,
      notes: row['notes'] as String?,
      timelineEventId: row['timeline_event_id'] as String?,
      createdAt: DateTime.parse(row['created_at'] as String),
      updatedAt: DateTime.parse(row['updated_at'] as String),
    );
  }

  Hangout copyWith({
    HangoutStatus? status,
    String? timelineEventId,
    DateTime? updatedAt,
  }) {
    return Hangout(
      id: id,
      title: title,
      description: description,
      date: date,
      startTime: startTime,
      endTime: endTime,
      status: status ?? this.status,
      createdBy: createdBy,
      notes: notes,
      timelineEventId: timelineEventId ?? this.timelineEventId,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
