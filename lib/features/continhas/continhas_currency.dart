import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Formatação BRL com algarismos tabulares (alinhamento tipo Splitwise).
abstract final class ContinhasCurrency {
  static final NumberFormat _brl = NumberFormat.currency(locale: 'pt_BR', symbol: r'R$');

  static String format(double value) => _brl.format(value);

  static TextStyle amountStyle(
    BuildContext context, {
    double fontSize = 17,
    FontWeight fontWeight = FontWeight.w700,
    Color? color,
  }) {
    return TextStyle(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color ?? Theme.of(context).colorScheme.onSurface,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
  }

  static TextStyle headlineBalance(BuildContext context, {Color? color}) {
    return amountStyle(context, fontSize: 34, fontWeight: FontWeight.w800, color: color);
  }
}
