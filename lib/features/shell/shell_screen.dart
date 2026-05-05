import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/providers.dart';
import '../../data/repositories/noop_repository.dart';
import '../hangouts/availability_editor_screen.dart';
import '../hangouts/hangout_editor_screen.dart';
import '../hangouts/hangouts_screen.dart';
import '../ideas/idea_editor_screen.dart';
import '../ideas/ideas_screen.dart';
import 'jbc_hub_screen.dart';
import '../notifications/notifications_screen.dart';
import '../timeline/timeline_event_editor_screen.dart';
import '../timeline/timeline_screen.dart';
import '../../core/push/jbc_firebase_bootstrap.dart';

class ShellScreen extends ConsumerStatefulWidget {
  const ShellScreen({super.key});

  @override
  ConsumerState<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends ConsumerState<ShellScreen> {
  /// 0 = Central (hub), 1 = Ideias, 2 = Linha do tempo, 3 = Rolês.
  int _index = 2;

  Future<void> _onFab() async {
    final profile = ref.read(userProfileProvider);
    if (profile == null) return;

    if (_index == 1) {
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => const IdeaEditorScreen(),
        ),
      );
      if (mounted) ref.invalidate(ideasProvider);
      return;
    }

    if (_index == 2) {
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => const TimelineEventEditorScreen(),
        ),
      );
      if (mounted) ref.invalidate(timelineEventsProvider);
      return;
    }

    if (_index == 3) {
      final repo = ref.read(repositoryProvider);
      if (repo is NoopRepository) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Configure SUPABASE_URL e SUPABASE_ANON_KEY para sincronizar.',
            ),
          ),
        );
        return;
      }
      final choice = await showModalBottomSheet<String>(
        context: context,
        showDragHandle: true,
        builder: (ctx) {
          return SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.event_outlined),
                  title: const Text('Novo rolê'),
                  onTap: () => Navigator.pop(ctx, 'hangout'),
                ),
                ListTile(
                  leading: const Icon(Icons.event_busy),
                  title: const Text('Nova indisponibilidade'),
                  onTap: () => Navigator.pop(ctx, 'avail'),
                ),
              ],
            ),
          );
        },
      );
      if (!mounted) return;
      if (choice == 'hangout') {
        await Navigator.of(context).push<void>(
          MaterialPageRoute<void>(
            builder: (_) => const HangoutEditorScreen(),
          ),
        );
      } else if (choice == 'avail') {
        await Navigator.of(context).push<void>(
          MaterialPageRoute<void>(
            builder: (_) => const AvailabilityEditorScreen(),
          ),
        );
      }
      if (mounted) {
        ref.invalidate(hangoutsProvider);
        ref.invalidate(availabilitiesProvider);
      }
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasRemote = ref.watch(hasRemoteProvider);
    final unreadAsync = ref.watch(jbcUnreadNotificationCountProvider);
    final unreadCount = unreadAsync.when(
      data: (n) => n,
      error: (_, _) => 0,
      loading: () => 0,
    );

    ref.listen(userProfileProvider, (previous, next) {
      if (next == null || !ref.read(hasRemoteProvider)) return;
      Future.microtask(() => JbcFirebaseBootstrap.registerMessagingTokenIfPossible(
            repository: ref.read(repositoryProvider),
            profile: next,
          ));
    });

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.brandRed,
        foregroundColor: Colors.white,
        leading: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
          child: Image.asset(
            'assets/jbc_logo_white_on_red.png',
            fit: BoxFit.contain,
          ),
        ),
        title: Text(_titles[_index]),
        actions: [
          if (hasRemote)
            IconButton(
              tooltip: 'Notificações',
              onPressed: () {
                Navigator.of(context).push<void>(
                  MaterialPageRoute<void>(
                    builder: (_) => const NotificationsScreen(),
                  ),
                );
              },
              icon: Badge(
                isLabelVisible: unreadCount > 0,
                label: Text(
                  unreadCount > 99 ? '99+' : '$unreadCount',
                  style: const TextStyle(fontSize: 10),
                ),
                child: const Icon(Icons.notifications_outlined),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          if (!hasRemote)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Card(
                color: Theme.of(context).colorScheme.errorContainer,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    'Supabase não configurado: sem sincronização entre aparelhos. '
                    'Veja README.md para definir SUPABASE_URL e SUPABASE_ANON_KEY.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onErrorContainer,
                        ),
                  ),
                ),
              ),
            ),
          Expanded(
            child: IndexedStack(
              index: _index,
              children: const [
                JbcHubScreen(),
                IdeasScreen(),
                TimelineScreen(),
                HangoutsScreen(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _index == 0
          ? null
          : FloatingActionButton(
              onPressed: _onFab,
              tooltip: _index == 1
                  ? 'Nova ideia'
                  : _index == 2
                      ? 'Nova memória'
                      : _index == 3
                          ? 'Novo rolê ou indisponibilidade'
                          : 'Adicionar',
              child: const Icon(Icons.add),
            ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.auto_awesome_mosaic_outlined),
            selectedIcon: Icon(Icons.auto_awesome_mosaic),
            label: 'Central',
          ),
          NavigationDestination(
            icon: Icon(Icons.lightbulb_outline),
            selectedIcon: Icon(Icons.lightbulb),
            label: 'Cantinho',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite_outline),
            selectedIcon: Icon(Icons.favorite),
            label: 'Linha do Tempo',
          ),
          NavigationDestination(
            icon: Icon(Icons.event_outlined),
            selectedIcon: Icon(Icons.event),
            label: 'Rolês',
          ),
        ],
      ),
    );
  }
}

const _titles = <String>[
  'Central JBC',
  'Cantinho de Ideias',
  'Linha do Tempo',
  'Rolês',
];

