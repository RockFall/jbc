class ContinhasGuest {
  const ContinhasGuest({
    required this.id,
    required this.displayName,
    required this.emoji,
    required this.createdBy,
    required this.createdAt,
  });

  final String id;
  final String displayName;
  final String emoji;
  final String createdBy;
  final DateTime createdAt;

  String get label => '$emoji $displayName';

  factory ContinhasGuest.fromRow(Map<String, dynamic> row) {
    return ContinhasGuest(
      id: row['id'] as String,
      displayName: row['display_name'] as String,
      emoji: row['emoji'] as String,
      createdBy: row['created_by'] as String,
      createdAt: DateTime.parse(row['created_at'] as String),
    );
  }
}
