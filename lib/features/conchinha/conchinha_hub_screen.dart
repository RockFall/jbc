import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/profile/jbc_profile.dart';
import '../../core/providers.dart';
import '../../data/models/conchinha_match_models.dart';
import '../../data/models/conchinha_request.dart';
import '../../data/repositories/noop_repository.dart';
import 'conchinha_new_request_screen.dart';
import 'conchinha_preference_screen.dart';
import 'conchinha_request_detail_screen.dart';
import 'conchinha_searching_screen.dart';
import 'conchinha_theme_scope.dart';

/// Hub Conchinha: modo match (CTA central) + modo clássico com pedidos por endereço.
class ConchinhaHubScreen extends ConsumerWidget {
  const ConchinhaHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider);
    final repo = ref.watch(repositoryProvider);
    final listAsync = ref.watch(conchinhaRequestsProvider);
    final poolAsync = ref.watch(conchinhaSearchPoolProvider);

    return ConchinhaThemeScope(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: repo is NoopRepository
            ? const Center(child: Text('Configure o Supabase para usar a Conchinha.'))
            : Stack(
                fit: StackFit.expand,
                children: [
                  const Positioned.fill(
                    child: CustomPaint(
                      painter: _ConchinhaHubBackdropPainter(),
                    ),
                  ),
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.white.withValues(alpha: 0.12),
                            Colors.transparent,
                            ConchinhaThemeScope.brandRed.withValues(alpha: 0.06),
                          ],
                          stops: const [0.0, 0.45, 1.0],
                        ),
                      ),
                    ),
                  ),
                  CustomScrollView(
                    slivers: [
                      SliverAppBar(
                        floating: true,
                        backgroundColor: Colors.transparent,
                        elevation: 0,
                        scrolledUnderElevation: 0,
                        surfaceTintColor: Colors.transparent,
                      ),
                      SliverToBoxAdapter(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final h = math.max(
                              440.0,
                              MediaQuery.sizeOf(context).height * 0.62,
                            );
                            return SizedBox(
                              height: h,
                              width: double.infinity,
                              child: SafeArea(
                                bottom: false,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 28),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Text(
                                        'As vezes tudo que você precisa é de uma…',
                                        textAlign: TextAlign.center,
                                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                              shadows: [
                                                Shadow(
                                                  color: Colors.white.withValues(alpha: 0.9),
                                                  blurRadius: 12,
                                                ),
                                              ],
                                            ),
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        'Toque no botão e veja se mais alguém do trio está disponível.',
                                        textAlign: TextAlign.center,
                                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                              color: ConchinhaThemeScope.textDark.withValues(alpha: 0.82),
                                            ),
                                      ),
                                      const SizedBox(height: 36),
                                      Center(
                                        child: ConstrainedBox(
                                          constraints: const BoxConstraints(maxWidth: 340),
                                          child: SizedBox(
                                            height: 56,
                                            width: double.infinity,
                                            child: FilledButton.icon(
                                              onPressed: profile == null
                                                  ? null
                                                  : () async {
                                                      final pref = await Navigator.of(context)
                                                          .push<ConchinhaSearchPreference>(
                                                        MaterialPageRoute(
                                                          fullscreenDialog: true,
                                                          builder: (_) =>
                                                              const ConchinhaPreferenceScreen(),
                                                        ),
                                                      );
                                                      if (pref == null || !context.mounted) return;
                                                      await Navigator.of(context).push<void>(
                                                        MaterialPageRoute<void>(
                                                          builder: (_) =>
                                                              ConchinhaSearchingScreen(
                                                                  preference: pref),
                                                        ),
                                                      );
                                                    },
                                              icon: const Icon(Icons.favorite_rounded),
                                              label: const Text('Requisitar uma conchinha'),
                                            ),
                                          ),
                                        ),
                                      ),
                                      poolAsync.when(
                                        skipLoadingOnReload: true,
                                        data: (pool) {
                                          if (pool.isEmpty) return const SizedBox(height: 20);
                                          final mine = pool
                                              .where((e) => e.profileKey == profile?.storageKey)
                                              .toList();
                                          if (mine.isEmpty) {
                                            return const SizedBox(height: 20);
                                          }
                                          return Padding(
                                            padding: const EdgeInsets.only(top: 20),
                                            child: Text(
                                              'Você está ativo no modo match (${mine.first.preference.labelBr}).',
                                              textAlign: TextAlign.center,
                                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                            ),
                                          );
                                        },
                                        loading: () => const SizedBox(height: 20),
                                        error: (_, _) => const SizedBox(height: 20),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                  SliverToBoxAdapter(
                    child: listAsync.when(
                      skipLoadingOnReload: true,
                      data: (all) {
                        final open = all.where((r) => r.status == ConchinhaRequestStatus.open).toList();
                        if (open.isEmpty) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
                          child: ExpansionTile(
                            initiallyExpanded: false,
                            title: const Text('Modo clássico — pedidos com local'),
                            subtitle: const Text('Mapa e endereço'),
                            children: [
                              _ClassicRequestsBody(
                                profile: profile,
                                open: open,
                              ),
                            ],
                          ),
                        );
                      },
                      loading: () => const SizedBox.shrink(),
                      error: (_, _) => const SizedBox.shrink(),
                    ),
                  ),
                ],
              ),
                ],
              ),
      ),
    );
  }
}

/// Fundo do hub: gradientes, orbes suaves, textura em pontos e traços diagonais discretos.
class _ConchinhaHubBackdropPainter extends CustomPainter {
  const _ConchinhaHubBackdropPainter();

  static const _cream = Color(0xFFFFF6F2);
  static const _blush = Color(0xFFFFE8EC);
  static const _rose = Color(0xFFFFCDD8);
  static const _deep = Color(0xFFE8A598);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    final base = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          _cream,
          _blush,
          ConchinhaThemeScope.canvas,
          _rose.withValues(alpha: 0.85),
        ],
        stops: const [0.0, 0.35, 0.72, 1.0],
      ).createShader(rect);
    canvas.drawRect(rect, base);

    void orb(Offset c, double r, Color color, [double a = 0.35]) {
      final g = Paint()
        ..shader = RadialGradient(
          colors: [
            color.withValues(alpha: a),
            color.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(center: c, radius: r));
      canvas.drawCircle(c, r, g);
    }

    orb(Offset(size.width * -0.08, size.height * 0.1), size.shortestSide * 0.65,
        ConchinhaThemeScope.brandRed, 0.18);
    orb(Offset(size.width * 1.05, size.height * -0.02), size.shortestSide * 0.55,
        ConchinhaThemeScope.accentYellow, 0.22);
    orb(Offset(size.width * 0.82, size.height * 0.88), size.shortestSide * 0.5, _deep, 0.15);
    orb(Offset(size.width * 0.15, size.height * 0.72), size.shortestSide * 0.45,
        const Color(0xFFE57373), 0.12);

    final dotPaint = Paint()..color = Colors.white.withValues(alpha: 0.55);
    final rand = math.Random(31);
    const step = 14.0;
    for (double x = 0; x < size.width; x += step) {
      for (double y = 0; y < size.height; y += step) {
        if ((rand.nextDouble()) > 0.72) continue;
        final o = (x / step + y / step).floor();
        canvas.drawCircle(
          Offset(x + rand.nextDouble() * 4, y + rand.nextDouble() * 4),
          o.isEven ? 1.1 : 0.7,
          dotPaint,
        );
      }
    }

    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.7
      ..color = ConchinhaThemeScope.brandRed.withValues(alpha: 0.06);
    for (var i = -4; i < 18; i++) {
      final x0 = i * 36.0;
      canvas.drawLine(
        Offset(x0, 0),
        Offset(x0 + size.height * 0.45, size.height),
        line,
      );
    }

    final vignette = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.transparent,
          ConchinhaThemeScope.brandRed.withValues(alpha: 0.07),
        ],
        stops: const [0.65, 1.0],
      ).createShader(Rect.fromCircle(center: Offset(size.width / 2, size.height / 2), radius: size.longestSide * 0.65));
    canvas.drawRect(rect, vignette);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ClassicRequestsBody extends ConsumerWidget {
  const _ClassicRequestsBody({
    required this.profile,
    required this.open,
  });

  final JbcProfile? profile;
  final List<ConchinhaRequest> open;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mineOpen = open.where((r) => r.requesterKey == profile?.storageKey).toList();
    final othersOpen = open.where((r) => r.requesterKey != profile?.storageKey).toList();
    final hasMyOpen = mineOpen.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FilledButton.tonal(
            onPressed: profile == null || hasMyOpen
                ? null
                : () async {
                    final id = await Navigator.of(context).push<String>(
                      MaterialPageRoute<String>(
                        builder: (_) => const ConchinhaNewRequestScreen(),
                      ),
                    );
                    if (id != null && context.mounted) {
                      ref.invalidate(conchinhaRequestsProvider);
                      await Navigator.of(context).push<void>(
                        MaterialPageRoute<void>(
                          builder: (_) => ConchinhaRequestDetailScreen(requestId: id),
                        ),
                      );
                    }
                  },
            child: Text(hasMyOpen ? 'Você já tem um pedido clássico aberto' : 'Novo pedido com endereço'),
          ),
          if (mineOpen.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'Seu pedido',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            ...mineOpen.map(
              (r) => _RequestCard(
                request: r,
                isMine: true,
                profile: profile,
                onOpen: () {
                  Navigator.of(context).push<void>(
                    MaterialPageRoute<void>(
                      builder: (_) => ConchinhaRequestDetailScreen(requestId: r.id),
                    ),
                  );
                },
              ),
            ),
          ],
          if (othersOpen.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'Pedidos dos amigos',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            ...othersOpen.map(
              (r) => _RequestCard(
                request: r,
                isMine: false,
                profile: profile,
                onOpen: () {
                  Navigator.of(context).push<void>(
                    MaterialPageRoute<void>(
                      builder: (_) => ConchinhaRequestDetailScreen(requestId: r.id),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({
    required this.request,
    required this.isMine,
    required this.profile,
    required this.onOpen,
  });

  final ConchinhaRequest request;
  final bool isMine;
  final JbcProfile? profile;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final who = JbcProfile.displayNameForStorageKey(request.requesterKey);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                request.address.label,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 4),
              Text(
                isMine ? 'Pedido feito por você' : 'Pedido por $who',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: onOpen,
                  child: Text(isMine ? 'Ver quem aceitou' : 'Ver / aceitar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
