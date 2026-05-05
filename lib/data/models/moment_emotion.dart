class MomentEmotion {
  const MomentEmotion({
    required this.profileKey,
    required this.stickerId,
    required this.updatedAt,
  });

  final String profileKey;
  final String stickerId;
  final DateTime updatedAt;

  Map<String, dynamic> toJson() => {
        'profile': profileKey,
        'sticker_id': stickerId,
        'updated_at': updatedAt.toUtc().toIso8601String(),
      };

  static MomentEmotion fromRow(Map<String, dynamic> row) {
    return MomentEmotion(
      profileKey: row['profile'] as String,
      stickerId: (row['sticker_id'] as String).trim(),
      updatedAt: DateTime.parse(row['updated_at'] as String),
    );
  }

  static MomentEmotion? fromJsonMap(Object? raw) {
    if (raw is! Map) return null;
    final m = Map<String, dynamic>.from(raw);
    final p = m['profile'] as String?;
    final s = m['sticker_id'] as String?;
    final t = m['updated_at'] as String?;
    if (p == null || s == null || t == null) return null;
    return MomentEmotion(
      profileKey: p,
      stickerId: s.trim(),
      updatedAt: DateTime.parse(t),
    );
  }
}
