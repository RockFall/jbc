import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/profile/jbc_profile.dart';
import '../../core/providers.dart';
import '../../data/models/conchinha_match_models.dart';
import '../../data/repositories/noop_repository.dart';
import 'conchinha_theme_scope.dart';

class ConchinhaMatchResultScreen extends ConsumerStatefulWidget {
  const ConchinhaMatchResultScreen({
    super.key,
    required this.waveId,
    required this.isSupreme,
    this.initialParticipants = const [],
  });

  final String waveId;
  final bool isSupreme;
  final List<ConchinhaPoolParticipant> initialParticipants;

  @override
  ConsumerState<ConchinhaMatchResultScreen> createState() => _ConchinhaMatchResultScreenState();
}

class _ConchinhaMatchResultScreenState extends ConsumerState<ConchinhaMatchResultScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _burst;
  late bool _showSupreme;

  @override
  void initState() {
    super.initState();
    _showSupreme = widget.isSupreme;
    _burst = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..forward();
  }

  @override
  void dispose() {
    _burst.dispose();
    super.dispose();
  }

  Future<void> _done() async {
    final profile = ref.read(userProfileProvider);
    final repo = ref.read(repositoryProvider);
    if (profile != null && repo is! NoopRepository) {
      try {
        await repo.leaveConchinhaSearchPool(profile);
      } catch (_) {}
    }
    if (mounted) Navigator.of(context).pop();
  }

  List<ConchinhaPoolParticipant> _participants(
    AsyncValue<List<ConchinhaPoolEntry>> poolAsync,
  ) {
    if (widget.initialParticipants.isNotEmpty) return widget.initialParticipants;
    return poolAsync.whenOrNull(
          data: (list) => list
              .map(
                (e) => ConchinhaPoolParticipant(
                  profileKey: e.profileKey,
                  preference: e.preference,
                ),
              )
              .toList(),
        ) ??
        const [];
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(conchinhaMatchStateProvider, (prev, next) {
      next.whenData((s) {
        if (s != null && s.isSupreme && mounted && !_showSupreme) {
          setState(() => _showSupreme = true);
          _burst.forward(from: 0);
        }
      });
    });

    final poolAsync = ref.watch(conchinhaSearchPoolProvider);
    final participants = _participants(poolAsync);
    final title = _showSupreme ? 'Match Supremo!' : 'Match de conchinha!';
    final subtitle = _showSupreme
        ? 'Os três aceitaram essa conchinha — mete JBC nisso.'
        : 'Vocês toparam uma conchinha!';

    return ConchinhaThemeScope(
      child: Scaffold(
        body: Stack(
          children: [
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _burst,
                builder: (context, _) {
                  return CustomPaint(
                    painter: _ConfettiPainter(t: _burst.value),
                  );
                },
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 8),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                            fontSize: _showSupreme ? 34 : 30,
                            color: ConchinhaThemeScope.brandRed,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      subtitle,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 28),
                    Expanded(
                      child: ListView.separated(
                        itemCount: participants.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (context, i) {
                          final p = participants[i];
                          final name = JbcProfile.displayNameForStorageKey(p.profileKey);
                          return Card(
                            child: Padding(
                              padding: const EdgeInsets.all(18),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 26,
                                    backgroundColor:
                                        ConchinhaThemeScope.accentYellow.withValues(alpha: 0.35),
                                    child: Text(
                                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                            color: ConchinhaThemeScope.textDark,
                                          ),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          name,
                                          style: Theme.of(context).textTheme.titleMedium,
                                        ),
                                        const SizedBox(height: 6),
                                        Chip(
                                          label: Text(p.preference.labelBr),
                                          visualDensity: VisualDensity.compact,
                                          backgroundColor:
                                              ConchinhaThemeScope.brandRed.withValues(alpha: 0.08),
                                          side: BorderSide.none,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    FilledButton(
                      onPressed: _done,
                      child: const Text('Fechou — bora!'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter({required this.t});

  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final rand = math.Random(7);
    final colors = [
      ConchinhaThemeScope.brandRed,
      ConchinhaThemeScope.accentYellow,
      const Color(0xFFFF9F7A),
    ];
    for (var i = 0; i < 36; i++) {
      final cx = rand.nextDouble() * size.width;
      final baseY = -40 + t * (size.height + 80) + (i * 17 % 64);
      final wobble = math.sin(t * math.pi * 2 + i) * 12;
      final p = Offset(cx + wobble, baseY % (size.height + 40));
      final paint = Paint()
        ..color = colors[i % colors.length].withValues(alpha: 0.35 + 0.25 * (1 - t))
        ..style = i.isEven ? PaintingStyle.fill : PaintingStyle.stroke
        ..strokeWidth = 2;
      if (i.isEven) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: p, width: 8, height: 12),
            const Radius.circular(2),
          ),
          paint,
        );
      } else {
        canvas.drawCircle(p, 4, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) => oldDelegate.t != t;
}
