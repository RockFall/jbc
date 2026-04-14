class TimelineEventComment {
  const TimelineEventComment({
    required this.id,
    required this.timelineEventId,
    required this.author,
    required this.body,
    required this.createdAt,
  });

  final String id;
  final String timelineEventId;
  /// `created_by` / perfil: caio, jojo, bibi
  final String author;
  final String body;
  final DateTime createdAt;

  factory TimelineEventComment.fromRow(Map<String, dynamic> row) {
    return TimelineEventComment(
      id: row['id'] as String,
      timelineEventId: row['timeline_event_id'] as String,
      author: row['author'] as String,
      body: row['body'] as String,
      createdAt: DateTime.parse(row['created_at'] as String),
    );
  }
}
