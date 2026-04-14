import 'package:flutter/material.dart';

/// Tema acolhedor; barra superior da marca em vermelho JBC.
class AppTheme {
  static const Color brandRed = Color(0xFFC30028);

  /// Material 3: [TextButton] em [AppBar.actions] não herda [AppBar.foregroundColor]
  /// (usa a cor primária do tema), então precisamos forçar contraste no vermelho.
  static const Color appBarOnBrandForeground = Colors.white;

  static ButtonStyle get appBarActionTextButtonStyle => TextButton.styleFrom(
        foregroundColor: appBarOnBrandForeground,
        disabledForegroundColor: appBarOnBrandForeground.withValues(alpha: 0.38),
      );

  static ThemeData light() {
    final base = ColorScheme.fromSeed(
      seedColor: const Color(0xFF9B6B7A),
      brightness: Brightness.light,
      surface: const Color(0xFFFFF8F5),
    );
    return ThemeData(
      colorScheme: base,
      useMaterial3: true,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: brandRed,
        foregroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        indicatorColor: base.primaryContainer,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          return TextStyle(
            fontSize: 12,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w600
                : FontWeight.w500,
            color: base.onSurface,
          );
        }),
      ),
    );
  }
}
