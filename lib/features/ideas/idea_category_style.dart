import 'package:flutter/material.dart';

import '../../data/models/idea.dart';

/// Cor de destaque por categoria (Cantinho / grid).
Color ideaCategoryColor(IdeaCategory? c, ColorScheme scheme) {
  switch (c) {
    case IdeaCategory.hangout:
      return const Color(0xFF6A1B9A);
    case IdeaCategory.cozinhaaar:
      return const Color(0xFFE65100);
    case IdeaCategory.filmin:
      return const Color(0xFF1565C0);
    case IdeaCategory.seriesAnime:
      return const Color(0xFFC2185B);
    case IdeaCategory.travel:
      return const Color(0xFF00838F);
    case IdeaCategory.hobby:
      return const Color(0xFF2E7D32);
    case IdeaCategory.other:
      return const Color(0xFF5D4037);
    case null:
      return scheme.surfaceContainerHigh;
  }
}

IconData ideaCategoryIcon(IdeaCategory? c) {
  switch (c) {
    case IdeaCategory.hangout:
      return Icons.celebration_outlined;
    case IdeaCategory.cozinhaaar:
      return Icons.restaurant_outlined;
    case IdeaCategory.filmin:
      return Icons.movie_outlined;
    case IdeaCategory.seriesAnime:
      return Icons.tv_outlined;
    case IdeaCategory.travel:
      return Icons.flight_outlined;
    case IdeaCategory.hobby:
      return Icons.palette_outlined;
    case IdeaCategory.other:
      return Icons.label_outline;
    case null:
      return Icons.lightbulb_outline;
  }
}
