import '../../data/models/idea.dart';

String ideaCategoryLabelPt(IdeaCategory c) {
  switch (c) {
    case IdeaCategory.hangout:
      return 'Rolê';
    case IdeaCategory.food:
      return 'Comida';
    case IdeaCategory.movie:
      return 'Filme';
    case IdeaCategory.series:
      return 'Série';
    case IdeaCategory.travel:
      return 'Viagem';
    case IdeaCategory.other:
      return 'Outro';
  }
}

String ideaStatusLabelPt(IdeaStatus s) {
  switch (s) {
    case IdeaStatus.active:
      return 'Ativa';
    case IdeaStatus.done:
      return 'Realizada';
    case IdeaStatus.archived:
      return 'Arquivada';
  }
}
