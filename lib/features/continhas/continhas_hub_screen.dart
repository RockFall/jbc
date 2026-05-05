import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import 'continhas_hangout_screen.dart';
import 'continhas_theme_scope.dart';
import 'jbc_cash_screen.dart';
import 'widgets/continhas_balance_hero.dart';
import 'widgets/continhas_hangout_list_tile.dart';
import 'widgets/continhas_section_header.dart';

class ContinhasHubScreen extends ConsumerWidget {
  const ContinhasHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hangoutsAsync = ref.watch(hangoutsProvider);
    final balanceAsync = ref.watch(jbcCashBalanceBrlProvider);

    final hangoutSlivers = hangoutsAsync.when<List<Widget>>(
      skipLoadingOnReload: true,
      data: (hangouts) {
        if (hangouts.isEmpty) {
          return [
            SliverFillRemaining(
              hasScrollBody: false,
              child: _EmptyHangoutsHint(),
            ),
          ];
        }
        final sorted = [...hangouts]
          ..sort((a, b) {
            final c = b.date.compareTo(a.date);
            if (c != 0) return c;
            return b.startTime.compareTo(a.startTime);
          });
        return [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) {
                  final h = sorted[i];
                  return ContinhasHangoutListTile(
                    hangout: h,
                    onTap: () {
                      Navigator.of(context).push<void>(
                        MaterialPageRoute<void>(
                          builder: (_) => ContinhasHangoutScreen(hangout: h),
                        ),
                      );
                    },
                  );
                },
                childCount: sorted.length,
              ),
            ),
          ),
        ];
      },
      loading: () => [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          sliver: SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary),
              ),
            ),
          ),
        ),
      ],
      error: (e, _) => [
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverToBoxAdapter(child: Text('$e')),
        ),
      ],
    );

    return ContinhasThemeScope(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Continhas'),
        ),
        body: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Caixa do JBC',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 14),
                    ContinhasBalanceHero(
                      title: 'Dindin do JBC',
                      subtitle: 'Depósitos e gastos pagos pelo fundo comum',
                      balanceAsync: balanceAsync,
                      ctaLabel: 'Ver movimentos',
                      onCta: () {
                        Navigator.of(context).push<void>(
                          MaterialPageRoute<void>(builder: (_) => const JbcCashScreen()),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
              sliver: SliverToBoxAdapter(
                child: ContinhasSectionHeader(
                  title: 'Rolês',
                ),
              ),
            ),
            ...hangoutSlivers,
          ],
        ),
      ),
    );
  }
}

class _EmptyHangoutsHint extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_outlined, size: 64, color: scheme.outline),
          const SizedBox(height: 16),
          Text(
            'Ainda não há rolês',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Crie um rolê no separador Rolês (ícone de calendário na barra em baixo).',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          FilledButton.tonal(
            onPressed: () {
              showDialog<void>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Como criar rolês'),
                  content: const Text(
                    'No ecrã principal, escolhe o separador «Rolês» na navegação inferior e usa o botão + para criar um rolê. Depois volta aqui para lançar despesas.',
                  ),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
                  ],
                ),
              );
            },
            child: const Text('Como criar rolês?'),
          ),
        ],
      ),
    );
  }
}
