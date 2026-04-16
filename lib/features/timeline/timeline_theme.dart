import 'dart:math' as math;

import 'package:flutter/material.dart';

// Epic 6–7 — constantes e variante visual estável por evento.

/// Quanto a foto invade a faixa central da haste (px). Epic 7: mais presença.
const double timelineRailOverlapPx = 26.0;

/// Rotação máxima em graus (fora do modo reduzir movimento).
const double timelineMaxRotationDegrees = 3.8;

/// Multiplicador de largura da foto: [min, max] (~até 1,5× vs. referência antiga).
const double timelinePhotoWidthFactorMin = 1.0;
const double timelinePhotoWidthFactorMax = 1.42;

// Epic 7 — moldura tipo polaroid (leve, sem asset).

const double timelinePolaroidPadH = 6;
const double timelinePolaroidPadTop = 6;
const double timelinePolaroidPadBottom = 15;

/// Escala extra só na zona da foto dentro da polaroid (mantém legenda estável).
const double timelinePolaroidImageBoost = 1.07;

/// Espaço extra no layout por baixo da polaroid para a pintura da rotação não
/// invadir o item seguinte (onde a haste volta a ser desenhada por cima).
const double timelinePolaroidLayoutBottomBleed = 48;
const double timelinePolaroidInnerRadius = 2.5;
const double timelinePolaroidOuterRadius = 6;

/// Assinatura (autor) no canto da polaroid — pequena, estilo manuscrito.
const double timelinePolaroidSignatureFontSize = 11.5;

Color timelinePolaroidMatColor(ColorScheme scheme) {
  return Color.lerp(
        scheme.surfaceContainerHighest,
        const Color(0xFFFAF8F5),
        0.5,
      ) ??
      scheme.surfaceContainerHighest;
}

/// Opacidade base e faixa da haste por posição na lista (topo = mais recente).
const double timelineRailAlphaMin = 0.22;
const double timelineRailAlphaMax = 0.52;

class TimelineVisualVariant {
  const TimelineVisualVariant({
    required this.widthFactor,
    required this.rotationRadians,
  });

  /// ~1.0–1.42 (Epic 7); 1.2 com redução de movimento.
  final double widthFactor;

  /// Radianos; 0 com redução de movimento.
  final double rotationRadians;
}

int _mix32(String id) {
  var h = 0;
  for (var i = 0; i < id.length; i++) {
    h = 0x1fffffff & (h + id.codeUnitAt(i));
    h = 0x1fffffff & (h + ((0x0007ffff & h) << 10));
    h ^= h >> 6;
  }
  h = 0x1fffffff & (h + ((0x03ffffff & h) << 3));
  h ^= h >> 11;
  h = 0x1fffffff & (h + ((0x00003fff & h) << 15));
  return h.abs();
}

/// Variante pseudo-aleatória estável por `eventId`; `listIndex` alterna o sinal da rotação.
TimelineVisualVariant timelineVisualVariantFor({
  required String eventId,
  required int listIndex,
  required bool reduceMotion,
}) {
  if (reduceMotion) {
    return const TimelineVisualVariant(widthFactor: 1.2, rotationRadians: 0);
  }
  final h = _mix32(eventId);
  final span = timelinePhotoWidthFactorMax - timelinePhotoWidthFactorMin;
  final wf = timelinePhotoWidthFactorMin + (h % 4096) / 4095.0 * span;

  final step = timelineMaxRotationDegrees * 2 / 8;
  var deg = -timelineMaxRotationDegrees + (h >> 11) % 9 * step;
  if (deg > timelineMaxRotationDegrees) deg = timelineMaxRotationDegrees;
  if (listIndex.isOdd) deg = -deg;

  return TimelineVisualVariant(
    widthFactor: wf,
    rotationRadians: deg * math.pi / 180,
  );
}

/// Intensidade da haste: 1 = topo (mais recente), 0 = base da lista.
double timelineRailAlphaForIndex({
  required int index,
  required int total,
}) {
  if (total <= 1) return timelineRailAlphaMax;
  final t = 1.0 - index / (total - 1);
  return timelineRailAlphaMin + (timelineRailAlphaMax - timelineRailAlphaMin) * t;
}

/// Cores do fundo da timeline (lista vazia / loading / erro + base comum ao pintor).
List<Color> timelineBackgroundGradientColors(ColorScheme scheme) {
  final base = scheme.surface;
  final rose = Color.lerp(base, scheme.primary, 0.22)!;
  final lavender = Color.lerp(base, scheme.tertiary, 0.34)!;
  final peach = Color.lerp(base, scheme.secondaryContainer, 0.28)!;
  final mist = Color.lerp(base, scheme.surfaceContainerHighest, 0.55)!;
  return [lavender, rose, mist, peach];
}

BoxDecoration timelineListBackgroundDecoration(ColorScheme scheme) {
  final colors = timelineBackgroundGradientColors(scheme);
  return BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: colors,
      stops: const [0.0, 0.34, 0.62, 1.0],
    ),
  );
}
