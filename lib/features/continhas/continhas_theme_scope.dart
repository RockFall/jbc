import 'package:flutter/material.dart';

import '../../core/theme/continhas_tokens.dart';

/// Tema local estilo app de rateio (canvas cinza + teal); desliga o vermelho JBC neste fluxo.
class ContinhasThemeScope extends StatelessWidget {
  const ContinhasThemeScope({super.key, required this.child});

  final Widget child;

  static const Color _onCanvas = Color(0xFF1C1C1E);
  static const Color _onCanvasMuted = Color(0xFF6B7280);

  @override
  Widget build(BuildContext context) {
    final parent = Theme.of(context);
    final t = ContinhasTokens.of(context);
    final cs = parent.colorScheme.copyWith(
      primary: t.brandTeal,
      onPrimary: Colors.white,
      primaryContainer: t.brandTeal.withValues(alpha: 0.14),
      onPrimaryContainer: t.brandTealDark,
      secondary: t.brandTeal,
      onSecondary: Colors.white,
      secondaryContainer: t.brandTeal.withValues(alpha: 0.18),
      onSecondaryContainer: t.brandTealDark,
      tertiary: t.brandTealDark,
      onTertiary: Colors.white,
      tertiaryContainer: t.positiveContainer,
      onTertiaryContainer: t.onPositive,
      surface: t.canvas,
      onSurface: _onCanvas,
      onSurfaceVariant: _onCanvasMuted,
      surfaceContainerLowest: t.canvas,
      surfaceContainerLow: t.canvas,
      surfaceContainer: t.cardBackground,
      surfaceContainerHigh: t.cardBackground,
      surfaceContainerHighest: Colors.white,
      outline: t.cardBorder,
      outlineVariant: const Color(0xFFE5E7EB),
    );

    final baseText = parent.textTheme;
    final continhasText = baseText.copyWith(
      titleLarge: baseText.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
        color: _onCanvas,
      ),
      titleMedium: baseText.titleMedium?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
        color: _onCanvas,
      ),
      titleSmall: baseText.titleSmall?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.1,
      ),
      bodyLarge: baseText.bodyLarge?.copyWith(
        height: 1.35,
        color: _onCanvas,
      ),
      bodyMedium: baseText.bodyMedium?.copyWith(
        height: 1.4,
        color: _onCanvasMuted,
      ),
      bodySmall: baseText.bodySmall?.copyWith(
        color: _onCanvasMuted,
        height: 1.35,
      ),
      labelLarge: baseText.labelLarge?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
      ),
    );

    return Theme(
      data: parent.copyWith(
        scaffoldBackgroundColor: t.canvas,
        colorScheme: cs,
        appBarTheme: AppBarTheme(
          backgroundColor: t.canvas,
          foregroundColor: _onCanvas,
          elevation: 0,
          scrolledUnderElevation: 0,
          surfaceTintColor: Colors.transparent,
          titleTextStyle: continhasText.titleMedium?.copyWith(fontSize: 18),
          iconTheme: const IconThemeData(color: _onCanvas, size: 22),
        ),
        cardTheme: CardThemeData(
          color: t.cardBackground,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          margin: EdgeInsets.zero,
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: t.brandTeal,
          foregroundColor: Colors.white,
          elevation: 3,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: t.brandTeal,
            foregroundColor: Colors.white,
          ),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: t.cardBackground,
          selectedColor: t.brandTeal.withValues(alpha: 0.22),
          disabledColor: t.canvas,
          labelStyle: TextStyle(color: _onCanvas, fontWeight: FontWeight.w600),
          secondaryLabelStyle: TextStyle(color: _onCanvasMuted),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          side: BorderSide(color: t.cardBorder),
          checkmarkColor: t.brandTealDark,
          brightness: Brightness.light,
        ),
        checkboxTheme: CheckboxThemeData(
          fillColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return t.brandTeal;
            return null;
          }),
          checkColor: WidgetStateProperty.all(Colors.white),
          side: BorderSide(color: t.cardBorder),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return Colors.white;
            return null;
          }),
          trackColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return t.brandTeal;
            return null;
          }),
          trackOutlineColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return Colors.transparent;
            return null;
          }),
        ),
        bottomSheetTheme: BottomSheetThemeData(
          backgroundColor: t.canvas,
          surfaceTintColor: Colors.transparent,
          dragHandleColor: _onCanvasMuted.withValues(alpha: 0.45),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: t.cardBackground,
          surfaceTintColor: Colors.transparent,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: t.cardBackground,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: t.cardBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: t.cardBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: t.brandTeal, width: 2),
          ),
          labelStyle: TextStyle(color: _onCanvasMuted),
          floatingLabelStyle: WidgetStateTextStyle.resolveWith((states) {
            if (states.contains(WidgetState.focused)) {
              return TextStyle(color: t.brandTealDark, fontWeight: FontWeight.w600);
            }
            return TextStyle(color: _onCanvasMuted);
          }),
        ),
        textTheme: continhasText,
      ),
      child: child,
    );
  }
}
