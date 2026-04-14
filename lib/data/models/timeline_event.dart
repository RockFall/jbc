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

/// Entrada ao salvar: URL já no storage ou bytes novos para upload.
class TimelineImageInput {
  const TimelineImageInput.existing(this.existingPublicUrl)
      : bytes = null,
        fileExtension = null;

  const TimelineImageInput.upload(this.bytes, this.fileExtension)
      : existingPublicUrl = null;

  final String? existingPublicUrl;
  final List<int>? bytes;
  final String? fileExtension;

  bool get isUpload =>
      bytes != null && bytes!.isNotEmpty && (fileExtension ?? 'jpg').isNotEmpty;
}

class TimelineEvent {
  const TimelineEvent({
    required this.id,
    required this.occurredAt,
    required this.title,
    required this.description,
    required this.imageUrls,
    required this.primaryImageIndex,
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
  final List<String> imageUrls;
  final int primaryImageIndex;
  final String createdBy;
  final TimelineEventOrigin origin;
  final String? hangoutId;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// URL da foto principal (capa na lista).
  String? get coverImageUrl {
    if (imageUrls.isEmpty) return null;
    final i = primaryImageIndex.clamp(0, imageUrls.length - 1);
    return imageUrls[i];
  }

  factory TimelineEvent.fromRow(Map<String, dynamic> row) {
    final urls = <String>[];
    final raw = row['image_urls'];
    if (raw is List) {
      for (final e in raw) {
        final s = e?.toString().trim() ?? '';
        if (s.isNotEmpty) urls.add(s);
      }
    }
    var pIndex = 0;
    final pi = row['primary_image_index'];
    if (pi is int) {
      pIndex = pi;
    } else if (pi != null) {
      pIndex = int.tryParse(pi.toString()) ?? 0;
    }
    if (urls.isEmpty) {
      final legacy = row['image_url'] as String?;
      if (legacy != null && legacy.trim().isNotEmpty) {
        urls.add(legacy.trim());
        pIndex = 0;
      }
    }
    if (urls.isNotEmpty) {
      pIndex = pIndex.clamp(0, urls.length - 1);
    } else {
      pIndex = 0;
    }
    return TimelineEvent(
      id: row['id'] as String,
      occurredAt: DateTime.parse(row['occurred_at'] as String),
      title: row['title'] as String,
      description: row['description'] as String? ?? '',
      imageUrls: List.unmodifiable(urls),
      primaryImageIndex: pIndex,
      createdBy: row['created_by'] as String,
      origin: TimelineEventOrigin.fromDb(row['origin'] as String? ?? 'manual'),
      hangoutId: row['hangout_id'] as String?,
      createdAt: DateTime.parse(row['created_at'] as String),
      updatedAt: DateTime.parse(row['updated_at'] as String),
    );
  }
}
