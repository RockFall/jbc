enum IdeaCategory {
  hangout,
  food,
  movie,
  series,
  travel,
  other;

  static IdeaCategory? fromDb(String? value) {
    if (value == null) return null;
    switch (value) {
      case 'hangout':
        return IdeaCategory.hangout;
      case 'food':
        return IdeaCategory.food;
      case 'movie':
        return IdeaCategory.movie;
      case 'series':
        return IdeaCategory.series;
      case 'travel':
        return IdeaCategory.travel;
      case 'other':
        return IdeaCategory.other;
      default:
        return null;
    }
  }

  String get dbValue {
    switch (this) {
      case IdeaCategory.hangout:
        return 'hangout';
      case IdeaCategory.food:
        return 'food';
      case IdeaCategory.movie:
        return 'movie';
      case IdeaCategory.series:
        return 'series';
      case IdeaCategory.travel:
        return 'travel';
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
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final String? description;
  final IdeaCategory? category;
  final IdeaStatus status;
  final String createdBy;
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
      createdAt: DateTime.parse(row['created_at'] as String),
      updatedAt: DateTime.parse(row['updated_at'] as String),
    );
  }
}
