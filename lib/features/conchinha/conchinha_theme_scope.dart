import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Tema local “entrega / apetite” (inspirado em apps de comida; não copia marcas).
class ConchinhaThemeScope extends StatelessWidget {
  const ConchinhaThemeScope({super.key, required this.child});

  final Widget child;

  static const Color canvas = Color(0xFFF7F3F0);
  static const Color brandRed = Color(0xFFEA1D2C);
  static const Color brandRedDark = Color(0xFFC41623);
  static const Color accentYellow = Color(0xFFFFC72C);
  static const Color textDark = Color(0xFF1A1A1A);

  @override
  Widget build(BuildContext context) {
    final parent = Theme.of(context);
    final displayFont = GoogleFonts.mukta(
      textStyle: parent.textTheme.displaySmall,
    );
    final bodyFont = GoogleFonts.notoSans(
      textStyle: parent.textTheme.bodyLarge,
    );

    final scheme = const ColorScheme.light(
      primary: brandRed,
      onPrimary: Colors.white,
      primaryContainer: Color(0xFFFFE4E6),
      onPrimaryContainer: brandRedDark,
      surface: canvas,
      onSurface: textDark,
      onSurfaceVariant: Color(0xFF5C5C5C),
      surfaceContainerHighest: Colors.white,
      secondary: accentYellow,
      onSecondary: textDark,
    );

    final textTheme = parent.textTheme.copyWith(
      displaySmall: displayFont.copyWith(
        fontWeight: FontWeight.w800,
        color: textDark,
        letterSpacing: -0.5,
      ),
      headlineMedium: bodyFont.copyWith(
        fontWeight: FontWeight.w800,
        fontSize: 26,
        color: textDark,
      ),
      titleLarge: bodyFont.copyWith(
        fontWeight: FontWeight.w700,
        color: textDark,
      ),
      bodyLarge: bodyFont.copyWith(color: textDark, height: 1.35),
      bodyMedium: bodyFont.copyWith(color: const Color(0xFF6B6B6B), height: 1.4),
      labelLarge: bodyFont.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: 0.2,
      ),
    );

    return Theme(
      data: parent.copyWith(
        scaffoldBackgroundColor: canvas,
        colorScheme: scheme,
        textTheme: textTheme,
        appBarTheme: AppBarTheme(
          backgroundColor: canvas,
          foregroundColor: textDark,
          elevation: 0,
          scrolledUnderElevation: 0,
          surfaceTintColor: Colors.transparent,
          titleTextStyle: textTheme.titleLarge?.copyWith(fontSize: 18),
          iconTheme: const IconThemeData(color: textDark),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: brandRed,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            textStyle: textTheme.labelLarge?.copyWith(color: Colors.white),
          ),
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 2,
          shadowColor: Colors.black26,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
      ),
      child: child,
    );
  }
}
