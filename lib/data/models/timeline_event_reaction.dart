class TimelineEventReaction {
  const TimelineEventReaction({
    required this.id,
    required this.timelineEventId,
    required this.profile,
    required this.emoji,
    required this.updatedAt,
  });

  final String id;
  final String timelineEventId;
  final String profile;
  final String emoji;
  final DateTime updatedAt;

  factory TimelineEventReaction.fromRow(Map<String, dynamic> row) {
    return TimelineEventReaction(
      id: row['id'] as String,
      timelineEventId: row['timeline_event_id'] as String,
      profile: row['profile'] as String,
      emoji: row['emoji'] as String,
      updatedAt: DateTime.parse(row['updated_at'] as String),
    );
  }
}
