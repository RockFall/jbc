import 'package:flutter/material.dart';

/// Tema acolhedor e simples (tons quentes, sem exageros).
class AppTheme {
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
        centerTitle: true,
        backgroundColor: base.surface,
        foregroundColor: base.onSurface,
        elevation: 0,
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
