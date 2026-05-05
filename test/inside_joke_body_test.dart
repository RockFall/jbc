import 'package:flutter_test/flutter_test.dart';

import 'package:jbc/core/piaditas/inside_joke_body.dart';

void main() {
  group('InsideJokeBody.normalize', () {
    test('remove espaços e aceita texto válido', () {
      expect(InsideJokeBody.normalize('  olá pote  '), 'olá pote');
    });

    test('rejeita vazio', () {
      expect(() => InsideJokeBody.normalize('   '), throwsFormatException);
      expect(() => InsideJokeBody.normalize(''), throwsFormatException);
    });

    test('rejeita acima do limite', () {
      final long = 'a' * (InsideJokeBody.maxLength + 1);
      expect(() => InsideJokeBody.normalize(long), throwsFormatException);
    });

    test('aceita no limite', () {
      final s = 'z' * InsideJokeBody.maxLength;
      expect(InsideJokeBody.normalize(s).length, InsideJokeBody.maxLength);
    });
  });
}
