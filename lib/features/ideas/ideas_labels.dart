import '../../data/models/idea.dart';

String ideaCategoryLabelPt(IdeaCategory c) {
  switch (c) {
    case IdeaCategory.hangout:
      return 'Rolê';
    case IdeaCategory.cozinhaaar:
      return 'Cozinhaaar';
    case IdeaCategory.filmin:
      return 'Filmin';
    case IdeaCategory.seriesAnime:
      return 'Série/Anime';
    case IdeaCategory.travel:
      return 'Viajar';
    case IdeaCategory.hobby:
      return 'Hobby';
    case IdeaCategory.other:
      return 'Outro';
  }
}

String ideaStatusLabelPt(IdeaStatus s) {
  switch (s) {
    case IdeaStatus.active:
      return 'A fazer';
    case IdeaStatus.done:
      return 'Já fizemos';
    case IdeaStatus.archived:
      return 'Odiei';
  }
}

/// Ordem fixa para seletores (alinhada à Epic 5).
List<IdeaCategory> ideaCategoryPickerOrder() => const [
      IdeaCategory.hangout,
      IdeaCategory.cozinhaaar,
      IdeaCategory.filmin,
      IdeaCategory.seriesAnime,
      IdeaCategory.travel,
      IdeaCategory.hobby,
      IdeaCategory.other,
    ];
