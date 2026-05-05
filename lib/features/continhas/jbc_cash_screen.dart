import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/profile/jbc_profile.dart';
import '../../core/providers.dart';
import '../../data/models/jbc_cash_ledger_entry.dart';
import 'continhas_currency.dart';
import '../../core/theme/continhas_tokens.dart';
import 'continhas_theme_scope.dart';
import 'widgets/continhas_balance_hero.dart';
import 'widgets/continhas_section_header.dart';

class JbcCashScreen extends ConsumerWidget {
  const JbcCashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balanceAsync = ref.watch(jbcCashBalanceBrlProvider);
    final ledgerAsync = ref.watch(jbcCashLedgerProvider);
    final profile = ref.watch(userProfileProvider);

    final ledgerSliver = ledgerAsync.when<Widget>(
      skipLoadingOnReload: true,
      data: (rows) {
        if (rows.isEmpty) {
          return SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Text(
                'Sem movimentos ainda.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          );
        }
        final sorted = [...rows]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        final groups = <String, List<JbcCashLedgerEntry>>{};
        for (final e in sorted) {
          final k = DateFormat('MMMM yyyy', 'pt_BR').format(e.createdAt.toLocal());
          groups.putIfAbsent(k, () => []).add(e);
        }
        final keys = groups.keys.toList();
        final tiles = <Widget>[];
        for (final monthKey in keys) {
          final m = monthKey.isEmpty ? monthKey : '${monthKey[0].toUpperCase()}${monthKey.substring(1)}';
          tiles.add(
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 8),
              child: Text(
                m,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ),
          );
          for (final e in groups[monthKey]!) {
            tiles.add(_LedgerRow(entry: e));
          }
        }
        return SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, i) => tiles[i],
              childCount: tiles.length,
            ),
          ),
        );
      },
      loading: () => SliverFillRemaining(
        child: Center(
          child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary),
        ),
      ),
      error: (e, _) => SliverFillRemaining(
        child: Center(child: Text('$e')),
      ),
    );

    return ContinhasThemeScope(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Dindin do JBC'),
        ),
        body: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              sliver: SliverToBoxAdapter(
                child: ContinhasBalanceHero(
                  title: 'Saldo disponível',
                  subtitle: 'Dinheiro que temos pra torrar',
                  balanceAsync: balanceAsync,
                  compact: true,
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              sliver: SliverToBoxAdapter(
                child: ContinhasSectionHeader(title: 'Lançamentos'),
              ),
            ),
            ledgerSliver,
          ],
        ),
        floatingActionButton: profile == null
            ? null
            : FloatingActionButton.extended(
                onPressed: () => openJbcDepositSheet(context, ref, profile),
                icon: const Icon(Icons.add),
                label: const Text('Depositar'),
              ),
      ),
    );
  }
}

Future<void> openJbcDepositSheet(BuildContext context, WidgetRef ref, JbcProfile profile) async {
  final amountCtrl = TextEditingController();
  final noteCtrl = TextEditingController();
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => ContinhasThemeScope(
      child: AlertDialog(
        surfaceTintColor: Colors.transparent,
        title: const Text('Coloque dinheiro'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Valor (BRL)',
                hintText: '0,00',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: noteCtrl,
              decoration: const InputDecoration(
                labelText: 'Nota (opcional)',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Guardar')),
        ],
      ),
    ),
  );
  if (ok != true || !context.mounted) return;
  final raw = amountCtrl.text.replaceAll(',', '.').trim();
  final v = double.tryParse(raw);
  if (v == null || v <= 0) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Coloque um valor válido.')),
    );
    return;
  }
  try {
    await ref.read(repositoryProvider).depositJbcCash(
          profile: profile,
          amountBrl: v,
          note: noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim(),
        );
    if (context.mounted) {
      ref.invalidate(jbcCashLedgerProvider);
      ref.invalidate(jbcCashBalanceBrlProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Depósito registado.')),
      );
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
    }
  }
}

class _LedgerRow extends StatelessWidget {
  const _LedgerRow({required this.entry});

  final JbcCashLedgerEntry entry;

  static String _label(JbcCashLedgerEntry e) {
    switch (e.type) {
      case JbcCashLedgerType.deposit:
        return e.note?.isNotEmpty == true ? e.note! : 'Depósito';
      case JbcCashLedgerType.hangoutExpenseDebit:
        return 'Despesa de rolê (Caixa)';
    }
  }

  static String _formatDate(DateTime d) {
    final local = d.toLocal();
    return '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')} '
        '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final t = ContinhasTokens.of(context);
    final scheme = Theme.of(context).colorScheme;
    final isIn = entry.type == JbcCashLedgerType.deposit;
    final amountColor = isIn ? t.positive : t.negative;
    final bg = isIn ? t.positiveContainer.withValues(alpha: 0.35) : t.negativeContainer.withValues(alpha: 0.35);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: t.cardBackground,
        elevation: 1,
        shadowColor: Colors.black.withValues(alpha: 0.06),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: bg,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isIn ? Icons.south_west_rounded : Icons.north_east_rounded,
                  size: 22,
                  color: amountColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _label(entry),
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      JbcProfile.displayNameForStorageKey(entry.recordedBy),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${isIn ? '+' : '−'} ${ContinhasCurrency.format(entry.amountBrl)}',
                    style: ContinhasCurrency.amountStyle(context, color: amountColor),
                  ),
                  Text(
                    _formatDate(entry.createdAt),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(color: t.subtitleOnCanvas),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
