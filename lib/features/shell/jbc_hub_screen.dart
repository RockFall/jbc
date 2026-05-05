import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart' show Ticker;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
import '../conchinha/conchinha_hub_screen.dart';
import '../continhas/continhas_hub_screen.dart';
import '../moment_emotion/moment_emotion_screen.dart';
import '../piaditas/piaditas_screen.dart';
import '../settings/settings_screen.dart';

/// Central de mini-apps: órbita animada em torno da marca (substitui atalhos da AppBar).
class JbcHubScreen extends ConsumerStatefulWidget {
  const JbcHubScreen({super.key});

  @override
  ConsumerState<JbcHubScreen> createState() => _JbcHubScreenState();
}

class _JbcHubScreenState extends ConsumerState<JbcHubScreen> with SingleTickerProviderStateMixin {
  /// Tempo desde [Ticker.start] — o callback já entrega o acumulado; não somar a cada frame.
  Duration _orbitElapsed = Duration.zero;
  Ticker? _orbitTicker;

  /// ~1 volta completa em ~75 s (suave, legível).
  static const double _driftRadPerSecond = 0.085;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (MediaQuery.of(context).disableAnimations) return;
      _orbitTicker = createTicker(_onOrbitTick)..start();
    });
  }

  void _onOrbitTick(Duration elapsedSinceStart) {
    _orbitElapsed = elapsedSinceStart;
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _orbitTicker?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasRemote = ref.watch(hasRemoteProvider);

    final modules = <_HubModule>[
      _HubModule(
        kind: _HubSatelliteKind.continhas,
        label: 'Continhas',
        tooltip: 'Continhas — Caixa e rolês',
        icon: Icons.attach_money_rounded,
        onOpen: (ctx) {
          if (!hasRemote) {
            ScaffoldMessenger.of(ctx).showSnackBar(
              const SnackBar(
                content: Text(
                  'Configure SUPABASE_URL e SUPABASE_ANON_KEY para sincronizar Continhas.',
                ),
              ),
            );
            return;
          }
          Navigator.of(ctx).push<void>(
            MaterialPageRoute<void>(builder: (_) => const ContinhasHubScreen()),
          );
        },
      ),
      _HubModule(
        kind: _HubSatelliteKind.piaditas,
        label: 'Piaditas',
        tooltip: 'Piaditas',
        icon: Icons.sentiment_very_satisfied_outlined,
        onOpen: (ctx) {
          if (!hasRemote) {
            ScaffoldMessenger.of(ctx).showSnackBar(
              const SnackBar(
                content: Text(
                  'Configure SUPABASE_URL e SUPABASE_ANON_KEY para sincronizar o pote.',
                ),
              ),
            );
            return;
          }
          Navigator.of(ctx).push<void>(
            MaterialPageRoute<void>(builder: (_) => const PiaditasScreen()),
          );
        },
      ),
      _HubModule(
        kind: _HubSatelliteKind.emocao,
        label: 'Emoção',
        tooltip: 'Emoção do momento',
        icon: Icons.mood_outlined,
        onOpen: (ctx) {
          if (!hasRemote) {
            ScaffoldMessenger.of(ctx).showSnackBar(
              const SnackBar(
                content: Text(
                  'Configure SUPABASE_URL e SUPABASE_ANON_KEY para sincronizar as emoções.',
                ),
              ),
            );
            return;
          }
          Navigator.of(ctx).push<void>(
            MaterialPageRoute<void>(builder: (_) => const MomentEmotionScreen()),
          );
        },
      ),
      _HubModule(
        kind: _HubSatelliteKind.conchinha,
        label: 'Conchinha',
        tooltip: 'Conchinha — pedir ajuda com mapa e endereço',
        icon: Icons.bed_rounded,
        onOpen: (ctx) {
          if (!hasRemote) {
            ScaffoldMessenger.of(ctx).showSnackBar(
              const SnackBar(
                content: Text(
                  'Configure SUPABASE_URL e SUPABASE_ANON_KEY para usar a Conchinha entre dispositivos.',
                ),
              ),
            );
            return;
          }
          Navigator.of(ctx).push<void>(
            MaterialPageRoute<void>(builder: (_) => const ConchinhaHubScreen()),
          );
        },
      ),
      _HubModule(
        kind: _HubSatelliteKind.ajustes,
        label: 'Ajustes',
        tooltip: 'Configurações',
        icon: Icons.settings_outlined,
        onOpen: (ctx) {
          Navigator.of(ctx).push<void>(
            MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
          );
        },
      ),
    ];

    final scheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _HubBackdropPainter(
                primarySoft: scheme.primaryContainer,
                secondarySoft: scheme.secondaryContainer,
                tertiarySoft: scheme.tertiaryContainer,
                brand: AppTheme.brandRed,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.88),
                        Colors.black.withValues(alpha: 0.45),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Column(
                      children: [
                        Text(
                          'Explore os cantinhos do JBC',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                shadows: const [
                                  Shadow(
                                    color: Color(0xCC000000),
                                    blurRadius: 14,
                                    offset: Offset(0, 2),
                                  ),
                                  Shadow(
                                    color: Color(0x66000000),
                                    blurRadius: 4,
                                    offset: Offset(0, 1),
                                  ),
                                ],
                              ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Clique em um satélite para abrir uma funcionalidade.',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.white.withValues(alpha: 0.78),
                                shadows: const [
                                  Shadow(
                                    color: Color(0x99000000),
                                    blurRadius: 10,
                                    offset: Offset(0, 1),
                                  ),
                                ],
                              ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: RepaintBoundary(
                    child: LayoutBuilder(
                      builder: (context, cons) {
                        final w = cons.maxWidth;
                        final h = cons.maxHeight;
                        final cx = w / 2;
                        final cy = h * 0.4;
                        final r = math.min(w, h) * 0.36;
                        final drift =
                            _orbitElapsed.inMicroseconds * 1e-6 * _driftRadPerSecond;
                        final n = modules.length;
                        return Stack(
                          clipBehavior: Clip.none,
                          alignment: Alignment.center,
                          children: [
                            CustomPaint(
                              size: Size(w, h),
                              painter: _OrbitRingPainter(
                                cx: cx,
                                cy: cy,
                                rx: r * 1.05,
                                ry: r * 0.88,
                                rotation: drift,
                                color: Colors.white.withValues(alpha: 0.22),
                              ),
                            ),
                            for (var i = 0; i < n; i++)
                              _satellitePosition(
                                cx: cx,
                                cy: cy,
                                rx: r,
                                ry: r * 0.82,
                                index: i,
                                count: n,
                                drift: drift,
                                child: _HubSatelliteTile(
                                  module: modules[i],
                                ),
                              ),
                            Positioned(
                              left: cx - 52,
                              top: cy - 52,
                              width: 104,
                              height: 104,
                              child: const _HubCore(),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _satellitePosition({
    required double cx,
    required double cy,
    required double rx,
    required double ry,
    required int index,
    required int count,
    required double drift,
    required Widget child,
  }) {
    const base = -math.pi / 2;
    final step = 2 * math.pi / count;
    final angle = base + index * step + drift;
    final x = cx + rx * math.cos(angle);
    final y = cy + ry * math.sin(angle);
    const half = 36.0;
    return Positioned(
      left: x - half,
      top: y - half,
      width: half * 2,
      height: half * 2,
      child: child,
    );
  }
}

/// Espaço: preto profundo, nebulosa suave a partir do tema, estrelas estáveis.
class _HubBackdropPainter extends CustomPainter {
  _HubBackdropPainter({
    required this.primarySoft,
    required this.secondarySoft,
    required this.tertiarySoft,
    required this.brand,
  });

  static const Color _voidBlack = Color(0xFF000000);

  final Color primarySoft;
  final Color secondarySoft;
  final Color tertiarySoft;
  final Color brand;

  void _nebulaBlob(Canvas canvas, Offset c, double radius, Color core) {
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          Color.lerp(_voidBlack, core, 0.55)!.withValues(alpha: 0.42),
          Color.lerp(_voidBlack, core, 0.35)!.withValues(alpha: 0.14),
          _voidBlack.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.42, 1.0],
      ).createShader(Rect.fromCircle(center: c, radius: radius));
    canvas.drawCircle(c, radius, paint);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(rect, Paint()..color = _voidBlack);

    final haze = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          _voidBlack,
          Color.lerp(_voidBlack, primarySoft, 0.12)!,
          Color.lerp(_voidBlack, secondarySoft, 0.1)!,
          Color.lerp(_voidBlack, tertiarySoft, 0.08)!,
          _voidBlack,
        ],
        stops: const [0.0, 0.28, 0.52, 0.78, 1.0],
      ).createShader(rect);
    canvas.drawRect(rect, haze);

    final brandOval = Rect.fromCenter(
      center: Offset(size.width * 0.5, size.height * 0.05),
      width: size.width * 1.35,
      height: size.height * 0.5,
    );
    canvas.drawOval(
      brandOval,
      Paint()
        ..shader = RadialGradient(
          colors: [
            brand.withValues(alpha: 0.14),
            brand.withValues(alpha: 0.04),
            _voidBlack.withValues(alpha: 0.0),
          ],
          stops: const [0.0, 0.38, 1.0],
        ).createShader(brandOval),
    );

    final s = size.shortestSide;
    _nebulaBlob(canvas, Offset(size.width * 0.9, size.height * 0.82), s * 0.55, tertiarySoft);
    _nebulaBlob(canvas, Offset(size.width * 0.05, size.height * 0.42), s * 0.52, primarySoft);
    _nebulaBlob(canvas, Offset(size.width * 0.72, size.height * 0.18), s * 0.42, secondarySoft);

    for (var i = 0; i < 72; i++) {
      final u = ((i * 137.508) % 1000) / 1000.0;
      final v = ((i * 491.297 + i * i * 3) % 1000) / 1000.0;
      final px = 8.0 + u * (size.width - 16);
      final py = 8.0 + v * (size.height - 16);
      final pr = i % 7 == 0 ? 1.55 : (i % 4 == 0 ? 1.1 : 0.65);
      final twinkle = 0.35 + (i % 6) * 0.1;
      canvas.drawCircle(
        Offset(px, py),
        pr,
        Paint()..color = Colors.white.withValues(alpha: twinkle),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _HubBackdropPainter oldDelegate) {
    return oldDelegate.primarySoft != primarySoft ||
        oldDelegate.secondarySoft != secondarySoft ||
        oldDelegate.tertiarySoft != tertiarySoft ||
        oldDelegate.brand != brand;
  }
}

enum _HubSatelliteKind {
  continhas,
  piaditas,
  emocao,
  conchinha,
  ajustes,
}

/// Silhueta, cor de acento e fundo por módulo (legível sobre o espaço da Central).
class _HubTileStyle {
  const _HubTileStyle({
    required this.shape,
    required this.accent,
    required this.fill,
    this.contentPadding = const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
    this.elevation = 4,
  });

  final ShapeBorder shape;
  final Color accent;
  final Color fill;
  final EdgeInsets contentPadding;
  final double elevation;
}

Color _hubLabelOnFill(Color fill) {
  final l = fill.computeLuminance();
  return l > 0.38 ? const Color(0xFF121212) : Colors.white.withValues(alpha: 0.92);
}

abstract final class _HubTileStyles {
  static _HubTileStyle resolve(_HubModule m) {
    switch (m.kind) {
      case _HubSatelliteKind.continhas:
        return const _HubTileStyle(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
          accent: Color.fromARGB(255, 30, 255, 0),
          fill: Color.fromARGB(255, 39, 100, 44),
          contentPadding: EdgeInsets.symmetric(horizontal: 5, vertical: 8),
        );
      case _HubSatelliteKind.piaditas:
        return const _HubTileStyle(
          shape: StadiumBorder(),
          accent: Color(0xFFFFD54F),
          fill: Color(0xFF362E18),
          contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        );
      case _HubSatelliteKind.emocao:
        return const _HubTileStyle(
          shape: RoundedSuperellipseBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
          accent: Color(0xFFE1B3FF),
          fill: Color(0xFF24182C),
        );
      case _HubSatelliteKind.conchinha:
        return const _HubTileStyle(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(18),
              topRight: Radius.circular(8),
              bottomLeft: Radius.circular(8),
              bottomRight: Radius.circular(18),
            ),
          ),
          accent: Color.fromARGB(255, 252, 170, 170),
          fill: Color.fromARGB(255, 160, 17, 7),
          contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 7),
        );
      case _HubSatelliteKind.ajustes:
        return _HubTileStyle(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: const Color(0xFFB0BEC5).withValues(alpha: 0.85), width: 1.5),
          ),
          accent: const Color(0xFFB0BEC5),
          fill: const Color(0x14FFFFFF),
          elevation: 2,
        );
    }
  }
}

class _HubModule {
  const _HubModule({
    required this.kind,
    required this.label,
    required this.tooltip,
    required this.icon,
    required this.onOpen,
  });

  final _HubSatelliteKind kind;
  final String label;
  final String tooltip;
  final IconData icon;
  final void Function(BuildContext context) onOpen;
}

class _HubSatelliteTile extends StatelessWidget {
  const _HubSatelliteTile({required this.module});

  final _HubModule module;

  @override
  Widget build(BuildContext context) {
    final style = _HubTileStyles.resolve(module);
    final iconWidget = Icon(module.icon, size: 26, color: style.accent);
    final labelColor = module.kind == _HubSatelliteKind.ajustes
        ? Colors.white
        : _hubLabelOnFill(style.fill);

    return Semantics(
      button: true,
      label: module.tooltip,
      child: Material(
        elevation: style.elevation,
        shadowColor: Colors.black54,
        color: style.fill,
        shape: style.shape,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          customBorder: style.shape,
          onTap: () {
            HapticFeedback.lightImpact();
            module.onOpen(context);
          },
          child: Padding(
            padding: style.contentPadding,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                iconWidget,
                const SizedBox(height: 4),
                Text(
                  module.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 10,
                        color: labelColor,
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

class _HubCore extends StatelessWidget {
  const _HubCore();

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 6,
      shape: const CircleBorder(),
      color: AppTheme.brandRed,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () => HapticFeedback.selectionClick(),
        child: SizedBox(
          width: 104,
          height: 104,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Image.asset(
              'assets/jbc_logo_white_on_red.png',
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }
}

class _OrbitRingPainter extends CustomPainter {
  _OrbitRingPainter({
    required this.cx,
    required this.cy,
    required this.rx,
    required this.ry,
    required this.rotation,
    required this.color,
  });

  final double cx;
  final double cy;
  final double rx;
  final double ry;
  final double rotation;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromCenter(center: Offset(cx, cy), width: rx * 2, height: ry * 2);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(rotation);
    canvas.translate(-cx, -cy);
    canvas.drawOval(rect, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _OrbitRingPainter oldDelegate) {
    return oldDelegate.rotation != rotation ||
        oldDelegate.cx != cx ||
        oldDelegate.cy != cy ||
        oldDelegate.rx != rx ||
        oldDelegate.ry != ry ||
        oldDelegate.color != color;
  }
}
