enum IdeaCategory {
  hangout,
  cozinhaaar,
  filmin,
  seriesAnime,
  travel,
  hobby,
  other;

  static IdeaCategory? fromDb(String? value) {
    if (value == null) return null;
    switch (value) {
      case 'hangout':
        return IdeaCategory.hangout;
      case 'cozinhaaar':
        return IdeaCategory.cozinhaaar;
      case 'filmin':
        return IdeaCategory.filmin;
      case 'series_anime':
        return IdeaCategory.seriesAnime;
      case 'travel':
        return IdeaCategory.travel;
      case 'hobby':
        return IdeaCategory.hobby;
      case 'other':
        return IdeaCategory.other;
      // legado MVP
      case 'food':
        return IdeaCategory.cozinhaaar;
      case 'movie':
        return IdeaCategory.filmin;
      case 'series':
        return IdeaCategory.seriesAnime;
      default:
        return null;
    }
  }

  String get dbValue {
    switch (this) {
      case IdeaCategory.hangout:
        return 'hangout';
      case IdeaCategory.cozinhaaar:
        return 'cozinhaaar';
      case IdeaCategory.filmin:
        return 'filmin';
      case IdeaCategory.seriesAnime:
        return 'series_anime';
      case IdeaCategory.travel:
        return 'travel';
      case IdeaCategory.hobby:
        return 'hobby';
      case IdeaCategory.other:
        return 'other';
    }
  }
}

enum IdeaStatus {
  active,
  done,
  archived;

  static IdeaStatus fromDb(String value) {
    switch (value) {
      case 'active':
        return IdeaStatus.active;
      case 'done':
        return IdeaStatus.done;
      case 'archived':
        return IdeaStatus.archived;
      default:
        return IdeaStatus.active;
    }
  }

  String get dbValue {
    switch (this) {
      case IdeaStatus.active:
        return 'active';
      case IdeaStatus.done:
        return 'done';
      case IdeaStatus.archived:
        return 'archived';
    }
  }
}

class Idea {
  const Idea({
    required this.id,
    required this.title,
    this.description,
    this.category,
    required this.status,
    required this.createdBy,
    this.archivedBy,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final String? description;
  final IdeaCategory? category;
  final IdeaStatus status;
  final String createdBy;
  /// Quem marcou como "Odiei" (quando [status] == archived).
  final String? archivedBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory Idea.fromRow(Map<String, dynamic> row) {
    return Idea(
      id: row['id'] as String,
      title: row['title'] as String,
      description: row['description'] as String?,
      category: IdeaCategory.fromDb(row['category'] as String?),
      status: IdeaStatus.fromDb(row['status'] as String? ?? 'active'),
      createdBy: row['created_by'] as String,
      archivedBy: row['archived_by'] as String?,
      createdAt: DateTime.parse(row['created_at'] as String),
      updatedAt: DateTime.parse(row['updated_at'] as String),
    );
  }
}
