class ConchinhaAcceptance {
  const ConchinhaAcceptance({
    required this.id,
    required this.requestId,
    required this.profileKey,
    required this.createdAt,
  });

  final String id;
  final String requestId;
  final String profileKey;
  final DateTime createdAt;

  static ConchinhaAcceptance fromRow(Map<String, dynamic> row) {
    return ConchinhaAcceptance(
      id: row['id'] as String,
      requestId: row['request_id'] as String,
      profileKey: row['profile'] as String,
      createdAt: DateTime.parse(row['created_at'] as String),
    );
  }
}
