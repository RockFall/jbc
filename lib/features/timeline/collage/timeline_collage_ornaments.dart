import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'timeline_collage_seed.dart';

/// Decorações discretas (cantos / manchas) — não cobrem texto.
class CollageOrnamentsLayer extends StatelessWidget {
  const CollageOrnamentsLayer({
    super.key,
    required this.eventId,
    required this.reduceMotion,
  });

  final String eventId;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    if (reduceMotion) return const SizedBox.shrink();
    final seed = timelineCollageSeed(eventId);
    return IgnorePointer(
      child: CustomPaint(
        painter: _OrnamentPainter(seed: seed),
        size: Size.infinite,
      ),
    );
  }
}

class _OrnamentPainter extends CustomPainter {
  _OrnamentPainter({required this.seed});

  final int seed;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final w = size.width;
    final h = size.height;

    final wash = Paint()
      ..color = const Color(0x14C45A4A)
      ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 24);
    final ox = ((seed % 73) / 73.0 - 0.5) * w * 0.15;
    final oy = (((seed >> 5) % 61) / 61.0 - 0.5) * h * 0.1;
    canvas.drawOval(Rect.fromCenter(center: Offset(w * 0.82 + ox, h * 0.12 + oy), width: w * 0.5, height: h * 0.22), wash);

    final tape = Paint()
      ..color = const Color(0x33D4A574)
      ..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(w * 0.02, h * 0.35)
      ..lineTo(w * 0.22, h * 0.32)
      ..lineTo(w * 0.21, h * 0.38)
      ..lineTo(w * 0.03, h * 0.41)
      ..close();
    canvas.drawPath(path, tape);

    final corner = Paint()
      ..color = const Color(0x22957565)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
    canvas.drawArc(Rect.fromLTWH(w - 56, 8, 48, 48), -1.2, 1.2, false, corner);
  }

  @override
  bool shouldRepaint(covariant _OrnamentPainter oldDelegate) => oldDelegate.seed != seed;
}
