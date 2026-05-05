import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/profile/jbc_profile.dart';
import '../../core/providers.dart';
import '../../data/models/conchinha_match_models.dart';
import '../../data/repositories/noop_repository.dart';
import 'conchinha_match_result_screen.dart';
import 'conchinha_theme_scope.dart';

class ConchinhaSearchingScreen extends ConsumerStatefulWidget {
  const ConchinhaSearchingScreen({super.key, required this.preference});

  final ConchinhaSearchPreference preference;

  @override
  ConsumerState<ConchinhaSearchingScreen> createState() => _ConchinhaSearchingScreenState();
}

class _ConchinhaSearchingScreenState extends ConsumerState<ConchinhaSearchingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  bool _joining = true;
  String? _joinError;
  bool _openedMatch = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startJoin());
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _startJoin() async {
    final profile = ref.read(userProfileProvider);
    final repo = ref.read(repositoryProvider);
    if (profile == null) return;
    if (repo is NoopRepository) {
      setState(() {
        _joining = false;
        _joinError = 'Configure o Supabase para o match em tempo real.';
      });
      return;
    }
    setState(() {
      _joining = true;
      _joinError = null;
    });
    try {
      final result = await repo.joinConchinhaSearchPool(
        profile: profile,
        preference: widget.preference,
      );
      if (!mounted) return;
      if (result.shouldNotifyDual || result.shouldNotifySupreme) {
        _openMatch(result, profile);
        return;
      }
      setState(() => _joining = false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _joining = false;
        _joinError = '$e';
      });
    }
  }

  void _openMatch(ConchinhaTryMatchResult r, JbcProfile me) {
    if (_openedMatch) return;
    _openedMatch = true;
    Navigator.of(context)
        .push<void>(
      MaterialPageRoute<void>(
        builder: (_) => ConchinhaMatchResultScreen(
          waveId: r.waveId,
          isSupreme: r.shouldNotifySupreme,
          initialParticipants: r.participants,
        ),
      ),
    )
        .then((_) {
      if (mounted) {
        setState(() => _openedMatch = false);
        Navigator.of(context).maybePop();
      }
    });
  }

  void _tryOpenMatchFromState(ConchinhaMatchStateRow? state, JbcProfile? me) {
    if (state == null || me == null || _openedMatch) return;
    if (state.isIdle) return;
    final asyncPool = ref.read(conchinhaSearchPoolProvider);
    final pool = asyncPool.asData?.value;
    if (pool == null || !pool.any((e) => e.profileKey == me.storageKey)) return;
    if (!state.isDual && !state.isSupreme) return;
    _openedMatch = true;
    Navigator.of(context)
        .push<void>(
      MaterialPageRoute<void>(
        builder: (_) => ConchinhaMatchResultScreen(
          waveId: state.waveId,
          isSupreme: state.isSupreme,
        ),
      ),
    )
        .then((_) {
      if (mounted) {
        setState(() => _openedMatch = false);
        Navigator.of(context).maybePop();
      }
    });
  }

  Future<void> _cancel() async {
    final profile = ref.read(userProfileProvider);
    final repo = ref.read(repositoryProvider);
    if (profile != null && repo is! NoopRepository) {
      try {
        await repo.leaveConchinhaSearchPool(profile);
      } catch (_) {}
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(userProfileProvider);
    ref.listen(conchinhaMatchStateProvider, (_, next) {
      next.whenData((s) => _tryOpenMatchFromState(s, profile));
    });

    final reduceMotion = MediaQuery.of(context).disableAnimations;

    return ConchinhaThemeScope(
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: _joining ? null : _cancel,
          ),
          title: const Text('Só um instante…'),
        ),
        body: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0xFFFFF6F2),
                      ConchinhaThemeScope.canvas,
                      ConchinhaThemeScope.brandRed.withValues(alpha: 0.06),
                    ],
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _ctrl,
                builder: (context, _) {
                  return CustomPaint(
                    painter: _SearchPulsePainter(
                      t: reduceMotion ? 0 : _ctrl.value,
                    ),
                  );
                },
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    AnimatedBuilder(
                      animation: _ctrl,
                      builder: (context, child) {
                        final scale = reduceMotion
                            ? 1.0
                            : 1.0 + 0.07 * math.sin(_ctrl.value * math.pi * 2);
                        return Transform.scale(
                          scale: scale,
                          child: child,
                        );
                      },
                      child: Icon(
                        Icons.bed_rounded,
                        size: 88,
                        color: ConchinhaThemeScope.brandRed.withValues(alpha: 0.92),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Procurando conchinha',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(fontSize: 30),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Preferência: ${widget.preference.labelBr}\n'
                      'Quando alguém do trio pedir ao mesmo tempo, dá match — e você vai receber uma notificação.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    if (_joining) ...[
                      const SizedBox(height: 36),
                      const CircularProgressIndicator(color: ConchinhaThemeScope.brandRed),
                      const SizedBox(height: 16),
                      Text(
                        'Sincronizando…',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                    ],
                    if (_joinError != null) ...[
                      const SizedBox(height: 24),
                      Text(
                        _joinError!,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: ConchinhaThemeScope.brandRedDark,
                            ),
                      ),
                      TextButton(onPressed: _startJoin, child: const Text('Tentar de novo')),
                    ],
                    const Spacer(),
                    TextButton(
                      onPressed: _joining ? null : _cancel,
                      child: const Text('Cancelar'),
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

class _SearchPulsePainter extends CustomPainter {
  _SearchPulsePainter({required this.t});

  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height * 0.22;
    final base = Paint()
      ..shader = RadialGradient(
        colors: [
          ConchinhaThemeScope.accentYellow.withValues(alpha: 0.25),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: size.shortestSide * 0.45));

    canvas.drawCircle(Offset(cx, cy), size.shortestSide * 0.55, base);

    for (var i = 0; i < 4; i++) {
      final phase = (t + i * 0.22) % 1.0;
      final r = 40 + phase * (size.shortestSide * 0.55);
      final ring = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = ConchinhaThemeScope.brandRed.withValues(alpha: 0.22 * (1 - phase));
      canvas.drawCircle(Offset(cx, cy), r, ring);
    }

    final spice = Paint()..color = ConchinhaThemeScope.accentYellow.withValues(alpha: 0.35);
    final rand = math.Random(42);
    for (var i = 0; i < 28; i++) {
      final a = rand.nextDouble() * math.pi * 2;
      final dist = 80 + rand.nextDouble() * 160 + math.sin(t * math.pi * 2 + i) * 12;
      final x = cx + math.cos(a) * dist;
      final y = cy + math.sin(a) * dist * 0.85;
      canvas.drawCircle(Offset(x, y), 2 + rand.nextDouble() * 2, spice);
    }
  }

  @override
  bool shouldRepaint(covariant _SearchPulsePainter oldDelegate) =>
      oldDelegate.t != t;
}
