import 'package:flutter/material.dart';

/// Paleta Continhas (referência tipo app de rateio: canvas + teal).
@immutable
class ContinhasTokens extends ThemeExtension<ContinhasTokens> {
  const ContinhasTokens({
    required this.canvas,
    required this.brandTeal,
    required this.brandTealDark,
    required this.subtitleOnCanvas,
    required this.positive,
    required this.positiveContainer,
    required this.onPositive,
    required this.negative,
    required this.negativeContainer,
    required this.onNegative,
    required this.cardBackground,
    required this.cardBorder,
    required this.heroGradientStart,
    required this.heroGradientEnd,
  });

  /// Fundo contínuo atrás das listas.
  final Color canvas;

  /// Cor de marca / CTAs / faixa do hero (teal).
  final Color brandTeal;

  /// Variação mais escura (pressed, texto sobre recipientes claros).
  final Color brandTealDark;

  /// Legendas e meta texto sobre canvas.
  final Color subtitleOnCanvas;

  final Color positive;
  final Color positiveContainer;
  final Color onPositive;
  final Color negative;
  final Color negativeContainer;
  final Color onNegative;
  final Color cardBackground;
  final Color cardBorder;

  /// Mantidos para compatibilidade com [lerp]; hero usa [brandTeal] em UI.
  final Color heroGradientStart;
  final Color heroGradientEnd;

  static const light = ContinhasTokens(
    canvas: Color(0xFFF2F4F6),
    brandTeal: Color(0xFF1CC29F),
    brandTealDark: Color(0xFF17A085),
    subtitleOnCanvas: Color(0xFF6B7280),
    positive: Color(0xFF0F766E),
    positiveContainer: Color(0xFFD1FAE5),
    onPositive: Color(0xFF064E3B),
    negative: Color(0xFFDC2626),
    negativeContainer: Color(0xFFFFE4E6),
    onNegative: Color(0xFF7F1D1D),
    cardBackground: Color(0xFFFFFFFF),
    cardBorder: Color(0x0F000000),
    heroGradientStart: Color(0xFF1CC29F),
    heroGradientEnd: Color(0xFF17A085),
  );

  static ContinhasTokens of(BuildContext context) {
    return Theme.of(context).extension<ContinhasTokens>() ?? light;
  }

  @override
  ContinhasTokens copyWith({
    Color? canvas,
    Color? brandTeal,
    Color? brandTealDark,
    Color? subtitleOnCanvas,
    Color? positive,
    Color? positiveContainer,
    Color? onPositive,
    Color? negative,
    Color? negativeContainer,
    Color? onNegative,
    Color? cardBackground,
    Color? cardBorder,
    Color? heroGradientStart,
    Color? heroGradientEnd,
  }) {
    return ContinhasTokens(
      canvas: canvas ?? this.canvas,
      brandTeal: brandTeal ?? this.brandTeal,
      brandTealDark: brandTealDark ?? this.brandTealDark,
      subtitleOnCanvas: subtitleOnCanvas ?? this.subtitleOnCanvas,
      positive: positive ?? this.positive,
      positiveContainer: positiveContainer ?? this.positiveContainer,
      onPositive: onPositive ?? this.onPositive,
      negative: negative ?? this.negative,
      negativeContainer: negativeContainer ?? this.negativeContainer,
      onNegative: onNegative ?? this.onNegative,
      cardBackground: cardBackground ?? this.cardBackground,
      cardBorder: cardBorder ?? this.cardBorder,
      heroGradientStart: heroGradientStart ?? this.heroGradientStart,
      heroGradientEnd: heroGradientEnd ?? this.heroGradientEnd,
    );
  }

  @override
  ContinhasTokens lerp(ThemeExtension<ContinhasTokens>? other, double t) {
    if (other is! ContinhasTokens) return this;
    return ContinhasTokens(
      canvas: Color.lerp(canvas, other.canvas, t)!,
      brandTeal: Color.lerp(brandTeal, other.brandTeal, t)!,
      brandTealDark: Color.lerp(brandTealDark, other.brandTealDark, t)!,
      subtitleOnCanvas: Color.lerp(subtitleOnCanvas, other.subtitleOnCanvas, t)!,
      positive: Color.lerp(positive, other.positive, t)!,
      positiveContainer: Color.lerp(positiveContainer, other.positiveContainer, t)!,
      onPositive: Color.lerp(onPositive, other.onPositive, t)!,
      negative: Color.lerp(negative, other.negative, t)!,
      negativeContainer: Color.lerp(negativeContainer, other.negativeContainer, t)!,
      onNegative: Color.lerp(onNegative, other.onNegative, t)!,
      cardBackground: Color.lerp(cardBackground, other.cardBackground, t)!,
      cardBorder: Color.lerp(cardBorder, other.cardBorder, t)!,
      heroGradientStart: Color.lerp(heroGradientStart, other.heroGradientStart, t)!,
      heroGradientEnd: Color.lerp(heroGradientEnd, other.heroGradientEnd, t)!,
    );
  }
}
