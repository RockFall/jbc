import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../data/models/idea.dart';
import 'idea_category_style.dart';

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

double _tiltRadians(int h, int layoutIndex) {
  const maxDeg = 2.65;
  var deg = -maxDeg + (h % 19) * (2 * maxDeg / 18);
  if (deg > maxDeg) deg = maxDeg;
  if (layoutIndex.isOdd) deg = -deg;
  return deg * math.pi / 180;
}

/// Linhas horizontais discretas (caderno / recado).
class _IdeaPaperLinesPainter extends CustomPainter {
  _IdeaPaperLinesPainter({required this.lineColor, required this.seed});

  final Color lineColor;
  final int seed;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width < 8 || size.height < 8) return;
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 0.65
      ..strokeCap = StrokeCap.round;
    var y = 22.0 + (seed % 9).toDouble();
    var i = 0;
    while (y < size.height - 6) {
      final w = ((seed + i * 17) % 5 - 2) * 0.35;
      canvas.drawLine(
        Offset(8 + w, y),
        Offset(size.width - 4, y + w * 0.15),
        paint,
      );
      y += 12.5 + ((seed >> (i % 5)) & 3);
      i++;
    }
  }

  @override
  bool shouldRepaint(covariant _IdeaPaperLinesPainter oldDelegate) {
    return lineColor != oldDelegate.lineColor || seed != oldDelegate.seed;
  }
}

class _PaperThumbtack extends StatelessWidget {
  const _PaperThumbtack({required this.seed});

  final int seed;

  @override
  Widget build(BuildContext context) {
    final tilt = (seed % 17 - 8) / 180 * math.pi;
    return Transform.rotate(
      angle: tilt,
      child: Container(
        width: 11,
        height: 11,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            center: const Alignment(-0.35, -0.35),
            colors: [
              const Color(0xFFFF8A80),
              Color.lerp(const Color(0xFFC62828), const Color(0xFF8E0000), 0.35)!,
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.28),
              blurRadius: 2.2,
              offset: const Offset(0, 1.2),
            ),
          ],
        ),
      ),
    );
  }
}

/// Cartão tipo post-it / papel colorido à mão (Cantinho de Ideias).
class IdeaPaperCard extends StatelessWidget {
  const IdeaPaperCard({
    super.key,
    required this.ideaId,
    required this.layoutIndex,
    required this.category,
    required this.scheme,
    required this.minHeight,
    required this.onTap,
    required this.child,
  });

  final String ideaId;
  final int layoutIndex;
  final IdeaCategory? category;
  final ColorScheme scheme;
  final double minHeight;
  final VoidCallback onTap;
  final Widget child;

  static const _cream = Color(0xFFFFFBF7);

  @override
  Widget build(BuildContext context) {
    final h = _mix32(ideaId);
    final accent = ideaCategoryColor(category, scheme);
    final paperMix = category == null ? 0.62 : 0.46;
    final paper = Color.lerp(accent, _cream, paperMix)!;
    final rotation = _tiltRadians(h, layoutIndex);
    final radius = 9.0 + (h % 6) * 0.65;
    final tapeW = 58.0 + (h % 24);
    final tapeAngle = -0.11 + (h % 60) / 900;
    final tapeShift = Offset(((h >> 3) % 13) - 6, -5.0);

    final onPaper = ThemeData.estimateBrightnessForColor(paper) == Brightness.dark
        ? Colors.white
        : const Color(0xFF2C2624);

    final lineColor = onPaper.withValues(alpha: 0.055);
    final borderColor = Color.lerp(accent, const Color(0xFF3E3836), 0.55)!
        .withValues(alpha: 0.16);

    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radius),
      side: BorderSide(color: borderColor, width: 0.85),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 3),
      child: Transform.rotate(
        angle: rotation,
        alignment: Alignment.center,
        child: Material(
          color: paper,
          elevation: 2.8,
          shadowColor: Color.lerp(Colors.black, accent, 0.12)!
              .withValues(alpha: 0.35),
          surfaceTintColor: Colors.transparent,
          shape: shape,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(radius),
            splashColor: accent.withValues(alpha: 0.22),
            highlightColor: accent.withValues(alpha: 0.09),
            child: Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _IdeaPaperLinesPainter(
                      lineColor: lineColor,
                      seed: h,
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  top: 10,
                  bottom: 10,
                  width: 5,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          accent.withValues(alpha: 0.95),
                          Color.lerp(accent, Colors.black, 0.12)!,
                        ],
                      ),
                      borderRadius: BorderRadius.only(
                        topRight: Radius.circular(radius * 0.35),
                        bottomRight: Radius.circular(radius * 0.35),
                      ),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.topCenter,
                  child: Transform.translate(
                    offset: tapeShift,
                    child: Transform.rotate(
                      angle: tapeAngle,
                      child: Container(
                        width: tapeW,
                        height: 13,
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.38),
                          borderRadius: BorderRadius.circular(2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.07),
                              offset: const Offset(0, 1),
                              blurRadius: 0,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.topCenter,
                  child: Transform.translate(
                    offset: Offset(((h >> 5) % 7) - 3, -4),
                    child: _PaperThumbtack(seed: h),
                  ),
                ),
                ConstrainedBox(
                  constraints: BoxConstraints(minHeight: minHeight),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 20, 11, 11),
                    child: DefaultTextStyle.merge(
                      style: TextStyle(color: onPaper),
                      child: child,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
