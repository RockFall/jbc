import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/hangout_conflict.dart';
import '../../core/profile/jbc_profile.dart';
import '../../core/providers.dart';
import '../../data/models/availability.dart';
import '../../data/models/hangout.dart';
import 'availability_editor_screen.dart';
import 'hangout_editor_screen.dart';
import 'hangouts_format.dart';

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
            Tab(text: 'Minhas faixas'),
            Tab(text: 'Agenda do trio'),
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
            return RefreshIndicator(
              onRefresh: onRefresh,
              child: ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                itemCount: hangouts.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final h = hangouts[index];
                  final d = DateTime(h.date.year, h.date.month, h.date.day);
                  final keys = conflictingPersonKeys(
                    hangoutDateLocal: d,
                    hangoutStartTime: h.startTime,
                    hangoutEndTime: h.endTime,
                    allAvailabilities: avs,
                  );
                  return _HangoutCard(
                    hangout: h,
                    conflictNames: keys.map(JbcProfile.displayNameForStorageKey).toList(),
                    onTap: () async {
                      await Navigator.of(context).push<void>(
                        MaterialPageRoute<void>(
                          builder: (_) => HangoutEditorScreen(initial: h),
                        ),
                      );
                      if (context.mounted) {
                        ref.invalidate(hangoutsProvider);
                      }
                    },
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
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _RetryMessage(
        message: '$e',
        onRetry: () => ref.invalidate(hangoutsProvider),
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
    final day = DateFormat('dd/MM/yyyy').format(hangout.date.toLocal());
    final time =
        '${hangout.startTime}${hangout.endTime != null ? ' – ${hangout.endTime}' : ''}';

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      hangout.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
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
              const SizedBox(height: 4),
              Text(
                '$day · $time · ${JbcProfile.displayNameForStorageKey(hangout.createdBy)}',
                style: theme.textTheme.bodySmall,
              ),
              if (hangout.timelineEventId != null &&
                  hangout.timelineEventId!.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  'Memória na timeline ✓',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.primary,
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
                      color: theme.colorScheme.tertiary,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Conflito com: ${conflictNames.join(', ')}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
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
                  title: Text(weekdayLabelPt(a.weekday)),
                  subtitle: Text('${a.startTime} – ${a.endTime}'),
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
