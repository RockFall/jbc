import 'package:flutter/material.dart';

import '../../data/models/conchinha_match_models.dart';
import 'conchinha_theme_scope.dart';

/// Escolhe “Na minha casa” ou “Em qualquer lugar” e devolve [ConchinhaSearchPreference] com `pop`.
class ConchinhaPreferenceScreen extends StatelessWidget {
  const ConchinhaPreferenceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ConchinhaThemeScope(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Onde você quer a conchinha?'),
        ),
        body: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _SoftTexturePainter(
                  color: ConchinhaThemeScope.canvas.withValues(alpha: 0.9),
                ),
              ),
            ),
            ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              children: [
                Text(
                  'Escolha sua preferência.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),
                _BigChoiceCard(
                  icon: Icons.home_rounded,
                  title: 'Na minha casa',
                  subtitle: 'Pra quando você não quer sair por nada.',
                  gradient: const [Color(0xFFFFF8F0), Colors.white],
                  onTap: () => Navigator.of(context).pop(ConchinhaSearchPreference.home),
                ),
                const SizedBox(height: 16),
                _BigChoiceCard(
                  icon: Icons.public_rounded,
                  title: 'Em qualquer lugar',
                  subtitle: 'Onde será que vai ser?',
                  gradient: const [Color(0xFFF0F9FF), Colors.white],
                  onTap: () => Navigator.of(context).pop(ConchinhaSearchPreference.anywhere),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BigChoiceCard extends StatelessWidget {
  const _BigChoiceCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final List<Color> gradient;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradient,
            ),
            boxShadow: [
              BoxShadow(
                color: ConchinhaThemeScope.brandRed.withValues(alpha: 0.12),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
            border: Border.all(
              color: ConchinhaThemeScope.brandRed.withValues(alpha: 0.08),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: ConchinhaThemeScope.brandRed.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: ConchinhaThemeScope.brandRed, size: 30),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontSize: 20,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 18,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SoftTexturePainter extends CustomPainter {
  _SoftTexturePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final g = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          color,
          color.withValues(alpha: 0.7),
        ],
      ).createShader(rect);
    canvas.drawRect(rect, g);
    final dot = Paint()..color = ConchinhaThemeScope.accentYellow.withValues(alpha: 0.04);
    const step = 18.0;
    for (double x = 0; x < size.width; x += step) {
      for (double y = 0; y < size.height; y += step) {
        if (((x ~/ step) + (y ~/ step)) % 3 == 0) {
          canvas.drawCircle(Offset(x, y), 1.2, dot);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
