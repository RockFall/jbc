import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/hangout_conflict.dart';
import '../../core/profile/jbc_profile.dart';
import '../../core/providers.dart';
import '../../data/models/availability.dart';
import '../../data/models/hangout.dart';
import 'availability_editor_screen.dart';
import 'hangout_editor_screen.dart';
import 'hangouts_format.dart';

bool _hangoutIsUpcoming(Hangout h) {
  if (h.status != HangoutStatus.planned) return false;
  final now = DateTime.now();
  final t0 = DateTime(now.year, now.month, now.day);
  final d = DateTime(h.date.year, h.date.month, h.date.day);
  return !d.isBefore(t0);
}

List<Hangout> _upcomingHangoutsSorted(List<Hangout> hangouts) {
  final list = hangouts.where(_hangoutIsUpcoming).toList()
    ..sort((a, b) {
      final c = a.date.compareTo(b.date);
      if (c != 0) return c;
      return a.startTime.compareTo(b.startTime);
    });
  return list;
}

class HangoutsScreen extends ConsumerStatefulWidget {
  const HangoutsScreen({super.key});

  @override
  ConsumerState<HangoutsScreen> createState() => _HangoutsScreenState();
}

class _HangoutsScreenState extends ConsumerState<HangoutsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Rolês'),
            Tab(text: 'Meus horários'),
            Tab(text: 'Horários do trio'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: const [
              _HangoutsListTab(),
              _MyAvailabilitiesTab(),
              _ConsolidatedAvailTab(),
            ],
          ),
        ),
      ],
    );
  }
}

class _HangoutsListTab extends ConsumerWidget {
  const _HangoutsListTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hAsync = ref.watch(hangoutsProvider);
    final aAsync = ref.watch(availabilitiesProvider);

    Future<void> onRefresh() async {
      ref.invalidate(hangoutsProvider);
      ref.invalidate(availabilitiesProvider);
      await Future<void>.delayed(const Duration(milliseconds: 400));
    }

    return hAsync.when(
      skipLoadingOnReload: true,
      data: (hangouts) {
        return aAsync.when(
          skipLoadingOnReload: true,
          data: (avs) {
            if (hangouts.isEmpty) {
              return RefreshIndicator(
                onRefresh: onRefresh,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    SizedBox(
                      height: MediaQuery.sizeOf(context).height * 0.35,
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            'Nenhum rolê ainda.\nUse + para criar o primeiro.',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }

            final upcoming = _upcomingHangoutsSorted(hangouts);
            final upIds = upcoming.map((e) => e.id).toSet();
            final others = hangouts.where((h) => !upIds.contains(h.id)).toList()
              ..sort((a, b) {
                final c = a.date.compareTo(b.date);
                if (c != 0) return c;
                return a.startTime.compareTo(b.startTime);
              });

            return RefreshIndicator(
              onRefresh: onRefresh,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  if (upcoming.isNotEmpty) ...[
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      sliver: SliverToBoxAdapter(
                        child: Text(
                          'Próximos rolês',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      sliver: SliverToBoxAdapter(
                        child: _HangoutHeroCard(
                          hangout: upcoming.first,
                          conflictNames: _conflictNames(upcoming.first, avs),
                          onTap: () => _openHangout(context, ref, upcoming.first),
                        ),
                      ),
                    ),
                    if (upcoming.length > 1)
                      SliverToBoxAdapter(
                        child: SizedBox(
                          height: 132,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                            itemCount: upcoming.length - 1,
                            separatorBuilder: (context, index) =>
                                const SizedBox(width: 12),
                            itemBuilder: (context, i) {
                              final h = upcoming[i + 1];
                              return SizedBox(
                                width: 220,
                                height: 120,
                                child: _HangoutStripCard(
                                  hangout: h,
                                  conflictNames: _conflictNames(h, avs),
                                  onTap: () => _openHangout(context, ref, h),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                  ] else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      sliver: SliverToBoxAdapter(
                        child: Text(
                          'Nenhum rolê futuro na agenda — veja o histórico abaixo.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ),
                  if (others.isNotEmpty)
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      sliver: SliverToBoxAdapter(
                        child: Text(
                          upcoming.isEmpty ? 'Rolês' : 'Demais rolês',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ),
                    ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final h = others[index];
                          return Padding(
                            padding: EdgeInsets.only(
                              bottom: index < others.length - 1 ? 10 : 0,
                            ),
                            child: _HangoutCard(
                              hangout: h,
                              conflictNames: _conflictNames(h, avs),
                              onTap: () => _openHangout(context, ref, h),
                            ),
                          );
                        },
                        childCount: others.length,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => _RetryMessage(
            message: '$e',
            onRetry: () => ref.invalidate(availabilitiesProvider),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _RetryMessage(
        message: '$e',
        onRetry: () => ref.invalidate(hangoutsProvider),
      ),
    );
  }

  static List<String> _conflictNames(Hangout h, List<Availability> avs) {
    final d = DateTime(h.date.year, h.date.month, h.date.day);
    final keys = conflictingPersonKeys(
      hangoutDateLocal: d,
      hangoutStartTime: h.startTime,
      hangoutEndTime: h.endTime,
      allAvailabilities: avs,
    );
    return keys.map(JbcProfile.displayNameForStorageKey).toList();
  }

  static Future<void> _openHangout(
    BuildContext context,
    WidgetRef ref,
    Hangout h,
  ) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => HangoutEditorScreen(initial: h),
      ),
    );
    if (context.mounted) ref.invalidate(hangoutsProvider);
  }
}

class _HangoutHeroCard extends StatelessWidget {
  const _HangoutHeroCard({
    required this.hangout,
    required this.conflictNames,
    required this.onTap,
  });

  final Hangout hangout;
  final List<String> conflictNames;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final day = formatHangoutDateRelativePt(hangout.date);
    final time =
        '${hangout.startTime}${hangout.endTime != null ? ' – ${hangout.endTime}' : ''}';

    return Material(
      color: scheme.primaryContainer.withValues(alpha: 0.35),
      borderRadius: BorderRadius.circular(24),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: scheme.primary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      hangoutStatusLabelPt(hangout.status),
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: scheme.onPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                hangout.title,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                day,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: scheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                time,
                style: theme.textTheme.bodyLarge,
              ),
              if (hangout.timelineEventId != null &&
                  hangout.timelineEventId!.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  'Já virou memória na linha do tempo',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: scheme.tertiary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              if (conflictNames.isNotEmpty) ...[
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.warning_amber_rounded, size: 20, color: scheme.tertiary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Conflito com: ${conflictNames.join(', ')}',
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _HangoutStripCard extends StatelessWidget {
  const _HangoutStripCard({
    required this.hangout,
    required this.conflictNames,
    required this.onTap,
  });

  final Hangout hangout;
  final List<String> conflictNames;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final day = formatHangoutDateRelativePt(hangout.date);
    final time =
        '${hangout.startTime}${hangout.endTime != null ? ' – ${hangout.endTime}' : ''}';

    return Material(
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                hangout.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              Text(
                '$day · $time',
                style: theme.textTheme.labelMedium,
              ),
              if (conflictNames.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Icon(Icons.warning_amber_rounded,
                      size: 16, color: theme.colorScheme.tertiary),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HangoutCard extends StatelessWidget {
  const _HangoutCard({
    required this.hangout,
    required this.conflictNames,
    required this.onTap,
  });

  final Hangout hangout;
  final List<String> conflictNames;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final day = formatHangoutDateRelativePt(hangout.date);
    final time =
        '${hangout.startTime}${hangout.endTime != null ? ' – ${hangout.endTime}' : ''}';

    return Material(
      color: scheme.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.45)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      hangout.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Chip(
                    label: Text(
                      hangoutStatusLabelPt(hangout.status),
                      style: theme.textTheme.labelSmall,
                    ),
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '$day · $time · ${JbcProfile.displayNameForStorageKey(hangout.createdBy)}',
                style: theme.textTheme.bodySmall,
              ),
              if (hangout.timelineEventId != null &&
                  hangout.timelineEventId!.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  'Memória na linha do tempo ✓',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: scheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              if (conflictNames.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      size: 18,
                      color: scheme.tertiary,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Conflito com: ${conflictNames.join(', ')}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _MyAvailabilitiesTab extends ConsumerWidget {
  const _MyAvailabilitiesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider);
    final async = ref.watch(availabilitiesProvider);

    Future<void> onRefresh() async {
      ref.invalidate(availabilitiesProvider);
      await Future<void>.delayed(const Duration(milliseconds: 400));
    }

    if (profile == null) {
      return const Center(child: Text('Escolha um perfil nas configurações.'));
    }

    return async.when(
      skipLoadingOnReload: true,
      data: (all) {
        final mine = all.where((a) => a.person == profile.storageKey).toList();
        if (mine.isEmpty) {
          return RefreshIndicator(
            onRefresh: onRefresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(
                  height: MediaQuery.sizeOf(context).height * 0.3,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Você ainda não cadastrou indisponibilidades.\nUse + para adicionar uma faixa recorrente.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: onRefresh,
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            itemCount: mine.length,
            separatorBuilder: (context, i) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final a = mine[i];
              return Card(
                child: ListTile(
                  title: Text(
                    (a.title != null && a.title!.trim().isNotEmpty)
                        ? a.title!.trim()
                        : weekdayLabelPt(a.weekday),
                  ),
                  subtitle: Text(
                    (a.title != null && a.title!.trim().isNotEmpty)
                        ? '${weekdayLabelPt(a.weekday)} · ${a.startTime} – ${a.endTime}'
                        : '${a.startTime} – ${a.endTime}',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    await Navigator.of(context).push<void>(
                      MaterialPageRoute<void>(
                        builder: (_) => AvailabilityEditorScreen(initial: a),
                      ),
                    );
                    if (context.mounted) {
                      ref.invalidate(availabilitiesProvider);
                    }
                  },
                ),
              );
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _RetryMessage(
        message: '$e',
        onRetry: () => ref.invalidate(availabilitiesProvider),
      ),
    );
  }
}

class _ConsolidatedAvailTab extends ConsumerWidget {
  const _ConsolidatedAvailTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(availabilitiesProvider);

    Future<void> onRefresh() async {
      ref.invalidate(availabilitiesProvider);
      await Future<void>.delayed(const Duration(milliseconds: 400));
    }

    return async.when(
      skipLoadingOnReload: true,
      data: (all) {
        if (all.isEmpty) {
          return RefreshIndicator(
            onRefresh: onRefresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(
                  height: MediaQuery.sizeOf(context).height * 0.3,
                  child: const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'Ninguém cadastrou indisponibilidades ainda.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }
        final byDay = <int, List<Availability>>{};
        for (final a in all) {
          byDay.putIfAbsent(a.weekday, () => []).add(a);
        }
        final days = byDay.keys.toList()..sort();

        return RefreshIndicator(
          onRefresh: onRefresh,
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            itemCount: days.length,
            itemBuilder: (context, i) {
              final w = days[i];
              final items = byDay[w]!
                ..sort((a, b) {
                  final p = a.person.compareTo(b.person);
                  if (p != 0) return p;
                  return a.startTime.compareTo(b.startTime);
                });
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      weekdayLabelPt(w),
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  ...items.map(
                    (a) => Card(
                      margin: const EdgeInsets.only(bottom: 6),
                      child: ListTile(
                        dense: true,
                        title: Text(
                          '${JbcProfile.displayNameForStorageKey(a.person)} · '
                          '${a.startTime} – ${a.endTime}',
                        ),
                        subtitle: (a.title != null && a.title!.trim().isNotEmpty)
                            ? Text(a.title!.trim())
                            : null,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _RetryMessage(
        message: '$e',
        onRetry: () => ref.invalidate(availabilitiesProvider),
      ),
    );
  }
}

class _RetryMessage extends StatelessWidget {
  const _RetryMessage({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar de novo'),
            ),
          ],
        ),
      ),
    );
  }
}
