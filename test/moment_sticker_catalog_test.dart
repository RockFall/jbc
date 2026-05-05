import 'package:flutter_test/flutter_test.dart';

import 'package:jbc/core/moment_emotion/moment_sticker_catalog.dart';

void main() {
  test('ids do catálogo são únicos', () {
    final ids = MomentStickerCatalog.all.map((e) => e.id).toList();
    expect(ids.toSet().length, ids.length);
  });

  test('tryById resolve stickers conhecidos', () {
    expect(MomentStickerCatalog.tryById('radiante')?.emoji, '😄');
    expect(MomentStickerCatalog.tryById('inexistente'), isNull);
  });

  test('isValidId', () {
    expect(MomentStickerCatalog.isValidId('chill'), isTrue);
    expect(MomentStickerCatalog.isValidId('nope'), isFalse);
  });
}
