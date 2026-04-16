import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'timeline_theme.dart';

/// Fundo ao longo da altura total do scroll, pintado num canvas do **tamanho do
/// viewport** com `translate(0, -scrollOffset)` para evitar overflow de layout
/// (UnconstrainedBox + SizedBox gigante).
class TimelineDocumentBackgroundPainter extends CustomPainter {
  TimelineDocumentBackgroundPainter({
    required this.scheme,
    required this.contentHeight,
    required this.scrollOffset,
  });

  final ColorScheme scheme;
  final double contentHeight;
  final double scrollOffset;

  static int _mix32(String s) {
    var h = 0;
    for (var i = 0; i < s.length; i++) {
      h = 0x1fffffff & (h + s.codeUnitAt(i));
      h = 0x1fffffff & (h + ((0x0007ffff & h) << 10));
      h ^= h >> 6;
    }
    h = 0x1fffffff & (h + ((0x03ffffff & h) << 3));
    h ^= h >> 11;
    h = 0x1fffffff & (h + ((0x00003fff & h) << 15));
    return h.abs();
  }

  static Path _organicBlob(
    double cx,
    double cy,
    double radius,
    int seed,
  ) {
    final rnd = math.Random(seed);
    const n = 11;
    final path = Path();
    for (var i = 0; i <= n; i++) {
      final t = (i / n) * math.pi * 2;
      final wobble = 0.52 + rnd.nextDouble() * 0.55;
      final squash = 0.62 + rnd.nextDouble() * 0.48;
      final x = cx + math.cos(t) * radius * wobble;
      final y = cy + math.sin(t) * radius * wobble * squash;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final viewportH = size.height;
    final docH = math.max(contentHeight, viewportH);

    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, w, viewportH));
    canvas.translate(0, -scrollOffset);

    final docRect = Rect.fromLTWH(0, 0, w, docH);

    final colors = timelineBackgroundGradientColors(scheme);
    final bg = Paint()
      ..shader = ui.Gradient.linear(
        Offset.zero,
        Offset(w, docH),
        colors,
        const [0.0, 0.34, 0.62, 1.0],
      );
    canvas.drawRect(docRect, bg);

    final surface = scheme.surface;
    final count = math.max(22, (docH / 130).floor()).clamp(22, 90);

    for (var i = 0; i < count; i++) {
      final seed = _mix32('docblob$i');
      final t = (i + 0.37) / count;
      final cy = t * docH + (seed % 180) / 6.0 - 20;
      final cx = w * (0.08 + (seed % 1000) / 1000.0 * 0.84);
      final r = (w * 0.18 + (seed >> 8) % 140).clamp(56.0, w * 0.42);

      final mode = i % 3;
      final Color fill;
      final double a;
      if (mode == 0) {
        fill = Color.lerp(surface, scheme.tertiaryContainer, 0.42)!;
        a = 0.10 + (seed & 7) / 120.0;
      } else if (mode == 1) {
        fill = Color.lerp(scheme.primary, surface, 0.35)!;
        a = 0.055 + (seed & 5) / 140.0;
      } else {
        fill = Color.lerp(surface, scheme.primaryContainer, 0.38)!;
        a = 0.075 + (seed & 11) / 130.0;
      }

      final path = _organicBlob(cx, cy, r.toDouble(), seed);
      final paint = Paint()
        ..color = fill.withValues(alpha: a)
        ..isAntiAlias = true
        ..style = PaintingStyle.fill;
      canvas.drawPath(path, paint);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant TimelineDocumentBackgroundPainter oldDelegate) {
    return oldDelegate.scheme != scheme ||
        oldDelegate.contentHeight != contentHeight ||
        oldDelegate.scrollOffset != scrollOffset;
  }
}
