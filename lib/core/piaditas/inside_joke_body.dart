/// Validação do texto depositado no pote (Epic 13).
abstract final class InsideJokeBody {
  static const maxLength = 10000;

  /// [raw] aparado; falha se vazio ou acima do limite.
  static String normalize(String raw) {
    final t = raw.trim();
    if (t.isEmpty) {
      throw FormatException('Escreva algo para colocar no pote.');
    }
    if (t.length > maxLength) {
      throw FormatException(
        'O texto passou do limite (no máximo $maxLength caracteres).',
      );
    }
    return t;
  }
}
