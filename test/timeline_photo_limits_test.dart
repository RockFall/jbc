import 'package:flutter_test/flutter_test.dart';
import 'package:jbc/core/media/timeline_photo_limits.dart';

void main() {
  test('limites da Epic 10', () {
    expect(kMaxGalleryPickBatch, 20);
    expect(kMaxTimelinePhotosPerMemory >= kMaxGalleryPickBatch, true);
  });
}
