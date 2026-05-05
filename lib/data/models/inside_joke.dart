class InsideJoke {
  const InsideJoke({
    required this.id,
    required this.body,
    required this.authorKey,
    required this.createdAt,
    this.tags = const [],
  });

  final String id;
  final String body;
  final String authorKey;
  final DateTime createdAt;
  final List<String> tags;

  static InsideJoke fromRow(Map<String, dynamic> row) {
    final tagsRaw = row['tags'];
    var tags = <String>[];
    if (tagsRaw is List) {
      tags = tagsRaw.map((e) => '$e').toList();
    }
    return InsideJoke(
      id: row['id'] as String,
      body: row['body'] as String,
      authorKey: row['author'] as String,
      createdAt: DateTime.parse(row['created_at'] as String),
      tags: tags,
    );
  }
}
