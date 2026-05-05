import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/continhas/continhas_participant_key.dart';
import '../../core/profile/jbc_profile.dart';
import '../../core/providers.dart';
import '../../data/models/continhas_expense.dart';
import '../../data/models/continhas_guest.dart';
import '../../data/models/hangout.dart';
import '../../data/repositories/noop_repository.dart';
import 'continhas_currency.dart';
import 'continhas_theme_scope.dart';
import '../../core/theme/continhas_tokens.dart';
import 'widgets/continhas_expense_row.dart';
import 'widgets/continhas_person_strip.dart';
import 'widgets/continhas_settlement_body.dart';
import 'widgets/continhas_skeleton.dart';

class ContinhasHangoutScreen extends ConsumerStatefulWidget {
  const ContinhasHangoutScreen({super.key, required this.hangout});

  final Hangout hangout;

  @override
  ConsumerState<ContinhasHangoutScreen> createState() =>
      _ContinhasHangoutScreenState();
}

class _ContinhasHangoutScreenState
    extends ConsumerState<ContinhasHangoutScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final repo = ref.read(repositoryProvider);
      if (repo is NoopRepository) return;
      try {
        await repo.ensureContinhasHangoutOpen(widget.hangout.id);
        if (!mounted) return;
        ref.invalidate(continhasHangoutStateProvider(widget.hangout.id));
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Não foi possível preparar Continhas deste rolê: $e'),
          ),
        );
      }
    });
  }

  Future<void> _retryEnsureOpen(String hangoutId) async {
    final repo = ref.read(repositoryProvider);
    if (repo is NoopRepository) return;
    try {
      await repo.ensureContinhasHangoutOpen(hangoutId);
      if (!mounted) return;
      ref.invalidate(continhasHangoutStateProvider(hangoutId));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  List<Widget> _openHangoutScrollChildren(
    BuildContext context,
    List<ContinhasExpense> expenses,
    List<ContinhasGuest> onHangout,
    List<ContinhasGuest> allGuests,
    List<String> guestIds,
    JbcProfile? profile,
    String hid,
  ) {
    final scheme = Theme.of(context).colorScheme;
    final t = ContinhasTokens.of(context);
    final total = expenses.fold<double>(0, (s, e) => s + e.amountBrl);
    final dateStr = DateFormat(
      "EEEE, d 'de' MMMM",
      'pt_BR',
    ).format(widget.hangout.date);
    final sorted = [...expenses]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final tiles = <Widget>[
      Text(
        widget.hangout.title,
        style: Theme.of(
          context,
        ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
      ),
      const SizedBox(height: 10),
      Row(
        children: [
          Chip(
            avatar: Icon(Icons.lock_open, size: 18, color: scheme.primary),
            label: const Text('Aberto'),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              dateStr,
              textAlign: TextAlign.end,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
      const SizedBox(height: 6),
      Text(
        'Qualquer perfil pode lançar despesas ou fechar o rolê.',
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
      ),
      const SizedBox(height: 16),
      Material(
        color: t.cardBackground,
        elevation: 1,
        shadowColor: Colors.black.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total neste rolê',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      ContinhasCurrency.format(total),
                      style: ContinhasCurrency.headlineBalance(context),
                    ),
                  ],
                ),
              ),
              Icon(Icons.receipt_long_outlined, size: 32, color: t.brandTeal),
            ],
          ),
        ),
      ),
      const SizedBox(height: 22),
      Row(
        children: [
          Text(
            'Convidados',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const Spacer(),
          TextButton.icon(
            onPressed: profile == null
                ? null
                : () =>
                      _manageGuests(context, hid, allGuests, guestIds, profile),
            icon: const Icon(Icons.person_add_alt_1_outlined, size: 20),
            label: const Text('Gerir'),
          ),
        ],
      ),
      const SizedBox(height: 8),
      if (onHangout.isEmpty)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            'Sem convidados extra — só o trio no rateio.',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
        )
      else
        ContinhasPersonStrip(guests: onHangout),
      const SizedBox(height: 22),
      Text(
        'Despesas',
        style: Theme.of(
          context,
        ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
      ),
      const SizedBox(height: 10),
    ];

    if (sorted.isEmpty) {
      tiles.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            'Ainda não há despesas. Usa o botão + para lançar a primeira.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ),
      );
    } else {
      String? lastMonth;
      for (final e in sorted) {
        final m = DateFormat(
          'MMMM yyyy',
          'pt_BR',
        ).format(e.createdAt.toLocal());
        if (m != lastMonth) {
          lastMonth = m;
          final label = m.isEmpty
              ? m
              : '${m[0].toUpperCase()}${m.substring(1)}';
          tiles.add(
            Padding(
              padding: const EdgeInsets.only(top: 6, bottom: 8),
              child: Text(
                label,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
          );
        }
        tiles.add(ContinhasExpenseRow(expense: e, guests: allGuests));
      }
    }

    if (profile != null) {
      tiles.add(const SizedBox(height: 20));
      tiles.add(
        Material(
          color: t.cardBackground,
          elevation: 1,
          shadowColor: Colors.black.withValues(alpha: 0.06),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: t.cardBorder),
          ),
          clipBehavior: Clip.antiAlias,
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 4,
                  decoration: BoxDecoration(
                    color: t.negative,
                    borderRadius: const BorderRadius.horizontal(
                      left: Radius.circular(15),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 16, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Fechar gastos',
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Depois de fechar, não dá para acrescentar nem apagar despesas neste rolê.',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                        const SizedBox(height: 12),
                        FilledButton.tonal(
                          onPressed: () => _confirmClose(context, hid, profile),
                          style: FilledButton.styleFrom(
                            backgroundColor: t.negativeContainer.withValues(
                              alpha: 0.6,
                            ),
                            foregroundColor: t.onNegative,
                          ),
                          child: const Text('Fechar gastos do rolê'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return tiles;
  }

  String _participantLabel(String key, List<ContinhasGuest> guests) {
    if (ContinhasParticipantKey.isProfile(key)) {
      final k = ContinhasParticipantKey.profileStorageKey(key);
      if (k != null) return JbcProfile.displayNameForStorageKey(k);
    }
    final gid = ContinhasParticipantKey.guestId(key);
    if (gid != null) {
      for (final g in guests) {
        if (g.id == gid) return g.label;
      }
    }
    return key;
  }

  @override
  Widget build(BuildContext context) {
    final hid = widget.hangout.id;
    final stateAsync = ref.watch(continhasHangoutStateProvider(hid));
    final expensesAsync = ref.watch(continhasExpensesProvider(hid));
    final guestIdsAsync = ref.watch(continhasHangoutGuestIdsProvider(hid));
    final guestsAsync = ref.watch(continhasGuestsProvider);
    final profile = ref.watch(userProfileProvider);

    return ContinhasThemeScope(
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.hangout.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        body: stateAsync.when(
          skipLoadingOnReload: true,
          data: (state) {
            if (state == null) {
              final repo = ref.watch(repositoryProvider);
              if (repo is NoopRepository) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Configure SUPABASE_URL e SUPABASE_ANON_KEY para abrir Continhas neste rolê.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                );
              }
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 20),
                      Text(
                        'A preparar Continhas deste rolê…',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 16),
                      TextButton.icon(
                        onPressed: () => _retryEnsureOpen(hid),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Tentar de novo'),
                      ),
                    ],
                  ),
                ),
              );
            }
            if (state.isClosed) {
              return ContinhasSettlementBody(
                hangoutTitle: widget.hangout.title,
                settlement: state.settlementJson,
                guests: guestsAsync.value ?? const [],
                labelFor: _participantLabel,
              );
            }
            return guestsAsync.when(
              skipLoadingOnReload: true,
              data: (allGuests) {
                return guestIdsAsync.when(
                  skipLoadingOnReload: true,
                  data: (guestIds) {
                    final onHangout = allGuests
                        .where((g) => guestIds.contains(g.id))
                        .toList();
                    return expensesAsync.when(
                      skipLoadingOnReload: true,
                      data: (expenses) {
                        return CustomScrollView(
                          slivers: [
                            SliverPadding(
                              padding: const EdgeInsets.fromLTRB(
                                20,
                                8,
                                20,
                                120,
                              ),
                              sliver: SliverList(
                                delegate: SliverChildListDelegate(
                                  _openHangoutScrollChildren(
                                    context,
                                    expenses,
                                    onHangout,
                                    allGuests,
                                    guestIds,
                                    profile,
                                    hid,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                      loading: () => const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ContinhasCardSkeleton(height: 100),
                              SizedBox(height: 12),
                              ContinhasCardSkeleton(height: 72),
                            ],
                          ),
                        ),
                      ),
                      error: (e, _) => Center(child: Text('$e')),
                    );
                  },
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: ContinhasCardSkeleton(height: 100),
                    ),
                  ),
                  error: (e, _) => Center(child: Text('$e')),
                );
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: ContinhasCardSkeleton(height: 100),
                ),
              ),
              error: (e, _) => Center(child: Text('$e')),
            );
          },
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ContinhasCardSkeleton(height: 88),
                  SizedBox(height: 12),
                  ContinhasCardSkeleton(height: 88),
                ],
              ),
            ),
          ),
          error: (e, _) => Center(child: Text('$e')),
        ),
        floatingActionButton: stateAsync.maybeWhen(
          data: (s) => s != null && !s.isClosed && profile != null
              ? FloatingActionButton.extended(
                  onPressed: () => _addExpense(context, hid, profile),
                  icon: const Icon(Icons.add),
                  label: const Text('Despesa'),
                )
              : null,
          orElse: () => null,
        ),
      ),
    );
  }

  Future<void> _addExpense(
    BuildContext context,
    String hangoutId,
    JbcProfile profile,
  ) async {
    final bg = ContinhasTokens.of(context).canvas;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: bg,
      builder: (ctx) => ContinhasThemeScope(
        child: _AddExpenseSheet(
          hangoutId: hangoutId,
          hangoutTitle: widget.hangout.title,
          profile: profile,
        ),
      ),
    );
  }

  Future<void> _confirmClose(
    BuildContext context,
    String hangoutId,
    JbcProfile profile,
  ) async {
    final go = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Fechar gastos?'),
        content: const Text(
          'Depois disto não dá para acrescentar nem apagar despesas neste rolê.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
    if (go != true || !context.mounted) return;
    try {
      await ref
          .read(repositoryProvider)
          .closeContinhasHangout(
            hangoutId: hangoutId,
            closedBy: profile,
            hangoutTitle: widget.hangout.title,
          );
      if (context.mounted) {
        ref.invalidate(continhasHangoutStateProvider(hangoutId));
        ref.invalidate(continhasExpensesProvider(hangoutId));
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Continhas fechadas.')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  Future<void> _manageGuests(
    BuildContext context,
    String hangoutId,
    List<ContinhasGuest> catalog,
    List<String> guestIds,
    JbcProfile profile,
  ) async {
    final sheetBg = ContinhasTokens.of(context).canvas;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: sheetBg,
      builder: (ctx) => ContinhasThemeScope(
        child: DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.65,
          maxChildSize: 0.92,
          builder: (context, scroll) {
            final scheme = Theme.of(context).colorScheme;
            final onHangout = catalog
                .where((g) => guestIds.contains(g.id))
                .toList();
            return ListView(
              controller: scroll,
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              children: [
                Text(
                  'Convidados',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton.tonal(
                  onPressed: () async {
                    final id = await _createGuestDialog(context, profile);
                    if (id != null && context.mounted) {
                      await ref
                          .read(repositoryProvider)
                          .addContinhasGuestToHangout(
                            hangoutId: hangoutId,
                            guestId: id,
                          );
                      ref.invalidate(
                        continhasHangoutGuestIdsProvider(hangoutId),
                      );
                      ref.invalidate(continhasGuestsProvider);
                    }
                  },
                  child: const Text('Novo convidado (nome + emoji)'),
                ),
                if (onHangout.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Text(
                    'Neste rolê',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  for (final g in onHangout)
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 0,
                      ),
                      leading: Text(
                        g.emoji,
                        style: const TextStyle(fontSize: 22),
                      ),
                      title: Text(g.displayName),
                      trailing: IconButton(
                        tooltip: 'Tirar deste rolê',
                        icon: Icon(
                          Icons.person_remove_outlined,
                          color: scheme.error,
                        ),
                        onPressed: () async {
                          try {
                            await ref
                                .read(repositoryProvider)
                                .removeContinhasGuestFromHangout(
                                  hangoutId: hangoutId,
                                  guestId: g.id,
                                );
                            if (context.mounted) {
                              ref.invalidate(
                                continhasHangoutGuestIdsProvider(hangoutId),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(
                                context,
                              ).showSnackBar(SnackBar(content: Text('$e')));
                            }
                          }
                        },
                      ),
                    ),
                ],
                const SizedBox(height: 16),
                Text(
                  'Da lista reutilizável',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                ...[
                  for (final g in catalog)
                    if (!guestIds.contains(g.id))
                      ListTile(
                        leading: Text(
                          g.emoji,
                          style: const TextStyle(fontSize: 22),
                        ),
                        title: Text(g.displayName),
                        trailing: const Icon(Icons.add),
                        onTap: () async {
                          await ref
                              .read(repositoryProvider)
                              .addContinhasGuestToHangout(
                                hangoutId: hangoutId,
                                guestId: g.id,
                              );
                          if (context.mounted) {
                            ref.invalidate(
                              continhasHangoutGuestIdsProvider(hangoutId),
                            );
                            Navigator.pop(context);
                          }
                        },
                      ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  Future<String?> _createGuestDialog(
    BuildContext context,
    JbcProfile profile,
  ) async {
    final nameCtrl = TextEditingController();
    final emojiCtrl = TextEditingController();
    final id = await showDialog<String>(
      context: context,
      builder: (ctx) => ContinhasThemeScope(
        child: AlertDialog(
          title: const Text('Novo convidado'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: emojiCtrl,
                decoration: const InputDecoration(labelText: 'Emoji'),
                maxLength: 8,
              ),
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Nome'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () async {
                try {
                  final gid = await ref
                      .read(repositoryProvider)
                      .createContinhasGuest(
                        profile: profile,
                        displayName: nameCtrl.text,
                        emoji: emojiCtrl.text,
                      );
                  if (ctx.mounted) Navigator.pop(ctx, gid);
                } catch (e) {
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(
                      ctx,
                    ).showSnackBar(SnackBar(content: Text('$e')));
                  }
                }
              },
              child: const Text('Criar'),
            ),
          ],
        ),
      ),
    );
    return id;
  }
}

class _AddExpenseSheet extends ConsumerStatefulWidget {
  const _AddExpenseSheet({
    required this.hangoutId,
    required this.hangoutTitle,
    required this.profile,
  });

  final String hangoutId;
  final String hangoutTitle;
  final JbcProfile profile;

  @override
  ConsumerState<_AddExpenseSheet> createState() => _AddExpenseSheetState();
}

class _AddExpenseSheetState extends ConsumerState<_AddExpenseSheet> {
  final _amountCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  JbcProfile _payer = JbcProfile.caio;
  bool _fromCash = false;
  final Set<JbcProfile> _profiles = {...JbcProfile.values};
  Set<String> _guestIds = {};

  @override
  void dispose() {
    _amountCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitExpense() async {
    if (!_profiles.contains(_payer)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Marca o pagador no rateio.')),
      );
      return;
    }
    if (_profiles.isEmpty && _guestIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Escolhe pelo menos uma pessoa no split.'),
        ),
      );
      return;
    }
    final raw = _amountCtrl.text.replaceAll(',', '.').trim();
    final v = double.tryParse(raw);
    if (v == null || v <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Valor inválido.')));
      return;
    }
    try {
      await ref
          .read(repositoryProvider)
          .addContinhasExpense(
            createdBy: widget.profile,
            hangoutId: widget.hangoutId,
            hangoutTitle: widget.hangoutTitle,
            amountBrl: v,
            payer: _payer,
            paymentSource: _fromCash
                ? ContinhasPaymentSource.jbcCash
                : ContinhasPaymentSource.self,
            description: _descCtrl.text,
            splitProfiles: _profiles,
            splitGuestIds: _guestIds,
          );
      if (!mounted) return;
      ref.invalidate(continhasExpensesProvider(widget.hangoutId));
      ref.invalidate(jbcCashLedgerProvider);
      ref.invalidate(jbcCashBalanceBrlProvider);
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final guestIdsAsync = ref.watch(
      continhasHangoutGuestIdsProvider(widget.hangoutId),
    );
    final guestsAsync = ref.watch(continhasGuestsProvider);
    final maxH = MediaQuery.sizeOf(context).height * 0.92;
    final bg = ContinhasTokens.of(context).canvas;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: ColoredBox(
        color: bg,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxH),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Nova despesa',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        widget.hangoutTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _amountCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Valor (BRL)',
                          hintText: '0,00',
                          prefixText: 'R\$ ',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _descCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Descrição',
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Quem pagou',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final p in JbcProfile.values)
                            ChoiceChip(
                              label: Text(p.displayName),
                              selected: _payer == p,
                              onSelected: (_) => setState(() => _payer = p),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SwitchListTile(
                        title: const Text('Pago pela Caixa do JBC'),
                        subtitle: const Text(
                          'Não gera dívida entre pessoas; debita o fundo.',
                        ),
                        value: _fromCash,
                        onChanged: (v) => setState(() => _fromCash = v),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Dividir entre',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      for (final p in JbcProfile.values)
                        CheckboxListTile(
                          dense: true,
                          value: _profiles.contains(p),
                          onChanged: (on) {
                            setState(() {
                              if (on == true) {
                                _profiles.add(p);
                              } else {
                                _profiles.remove(p);
                              }
                            });
                          },
                          title: Text(p.displayName),
                        ),
                      guestsAsync.when(
                        data: (all) {
                          return guestIdsAsync.when(
                            data: (ids) {
                              final onHangout = all
                                  .where((g) => ids.contains(g.id))
                                  .toList();
                              if (onHangout.isEmpty) {
                                return const SizedBox.shrink();
                              }
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  const Divider(),
                                  for (final g in onHangout)
                                    CheckboxListTile(
                                      dense: true,
                                      value: _guestIds.contains(g.id),
                                      onChanged: (on) {
                                        setState(() {
                                          if (on == true) {
                                            _guestIds = {..._guestIds, g.id};
                                          } else {
                                            _guestIds = {..._guestIds}
                                              ..remove(g.id);
                                          }
                                        });
                                      },
                                      title: Text(
                                        '${g.emoji} ${g.displayName}',
                                      ),
                                    ),
                                ],
                              );
                            },
                            loading: () => const SizedBox.shrink(),
                            error: (_, _) => const SizedBox.shrink(),
                          );
                        },
                        loading: () => const SizedBox.shrink(),
                        error: (_, _) => const SizedBox.shrink(),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
              Material(
                elevation: 6,
                shadowColor: Colors.black26,
                color: bg,
                surfaceTintColor: Colors.transparent,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
                  child: SafeArea(
                    top: false,
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _submitExpense,
                        child: const Text('Guardar despesa'),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
