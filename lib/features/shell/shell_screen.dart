import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../data/repositories/noop_repository.dart';
import '../hangouts/availability_editor_screen.dart';
import '../hangouts/hangout_editor_screen.dart';
import '../hangouts/hangouts_screen.dart';
import '../ideas/idea_editor_screen.dart';
import '../ideas/ideas_screen.dart';
import '../settings/settings_screen.dart';
import '../timeline/timeline_event_editor_screen.dart';
import '../timeline/timeline_screen.dart';

class ShellScreen extends ConsumerStatefulWidget {
  const ShellScreen({super.key});

  @override
  ConsumerState<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends ConsumerState<ShellScreen> {
  int _index = 1;

  Future<void> _onFab() async {
    final profile = ref.read(userProfileProvider);
    if (profile == null) return;

    if (_index == 0) {
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => const IdeaEditorScreen(),
        ),
      );
      if (mounted) ref.invalidate(ideasProvider);
      return;
    }

    if (_index == 1) {
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => const TimelineEventEditorScreen(),
        ),
      );
      if (mounted) ref.invalidate(timelineEventsProvider);
      return;
    }

    if (_index == 2) {
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

    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_index]),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const SettingsScreen(),
                ),
              );
            },
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
                IdeasScreen(),
                TimelineScreen(),
                HangoutsScreen(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _onFab,
        tooltip: _index == 0
            ? 'Nova ideia'
            : _index == 1
                ? 'Nova memória'
                : _index == 2
                    ? 'Novo rolê ou indisponibilidade'
                    : 'Adicionar',
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.lightbulb_outline),
            selectedIcon: Icon(Icons.lightbulb),
            label: 'Cantinho',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite_outline),
            selectedIcon: Icon(Icons.favorite),
            label: 'Timeline',
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
  'Cantinho de Ideias',
  'Timeline',
  'Rolês',
];

