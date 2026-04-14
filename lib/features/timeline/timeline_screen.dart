import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/profile/jbc_profile.dart';
import '../../core/providers.dart';
import '../../data/models/timeline_event.dart';
import 'timeline_event_editor_screen.dart';

enum _TimelineMenuAction { edit, delete }

class TimelineScreen extends ConsumerWidget {
  const TimelineScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(timelineEventsProvider);

    Future<void> onRefresh() async {
      ref.invalidate(timelineEventsProvider);
      await Future<void>.delayed(const Duration(milliseconds: 400));
    }

    return async.when(
      skipLoadingOnReload: true,
      data: (events) => RefreshIndicator(
        onRefresh: onRefresh,
        child: events.isEmpty
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(
                    height: MediaQuery.sizeOf(context).height * 0.35,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'Nenhuma memória ainda.\nToque em + para registrar o primeiro momento.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ),
                    ),
                  ),
                ],
              )
            : ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                itemCount: events.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final e = events[index];
                  return _TimelineEventCard(
                    event: e,
                    onEdit: () async {
                      await Navigator.of(context).push<void>(
                        MaterialPageRoute<void>(
                          builder: (_) => TimelineEventEditorScreen(initial: e),
                        ),
                      );
                      if (context.mounted) {
                        ref.invalidate(timelineEventsProvider);
                      }
                    },
                    onDelete: () => _confirmDelete(context, ref, e),
                  );
                },
              ),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Não foi possível carregar a timeline.',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                '$error',
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => ref.invalidate(timelineEventsProvider),
                icon: const Icon(Icons.refresh),
                label: const Text('Tentar de novo'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    TimelineEvent event,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir memória?'),
        content: Text('Remover “${event.title}” para todo mundo?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    try {
      await ref.read(repositoryProvider).deleteTimelineEvent(event);
      ref.invalidate(timelineEventsProvider);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Memória excluída.')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao excluir: $e')),
      );
    }
  }
}

class _TimelineEventCard extends StatelessWidget {
  const _TimelineEventCard({
    required this.event,
    required this.onEdit,
    required this.onDelete,
  });

  final TimelineEvent event;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateStr = DateFormat('dd/MM/yyyy').format(event.occurredAt.toLocal());
    final author = JbcProfile.displayNameForStorageKey(event.createdBy);
    final created = DateFormat('dd/MM/yyyy HH:mm').format(event.createdAt.toLocal());
    final updated = DateFormat('dd/MM/yyyy HH:mm').format(event.updatedAt.toLocal());
    final desc = event.description.trim();
    final snippet = desc.length > 120 ? '${desc.substring(0, 120)}…' : desc;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onEdit,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Thumbnail(url: event.imageUrl),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$dateStr · $author',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    if (snippet.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        snippet,
                        style: theme.textTheme.bodyMedium,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 6),
                    Text(
                      'Registrada em $created · Atualizada $updated',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                    if (event.origin == TimelineEventOrigin.fromHangout) ...[
                      const SizedBox(height: 6),
                      Chip(
                        label: const Text('Rolê'),
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        labelStyle: theme.textTheme.labelSmall,
                      ),
                    ],
                  ],
                ),
              ),
              PopupMenuButton<_TimelineMenuAction>(
                icon: const Icon(Icons.more_vert),
                onSelected: (action) {
                  switch (action) {
                    case _TimelineMenuAction.edit:
                      onEdit();
                      break;
                    case _TimelineMenuAction.delete:
                      onDelete();
                      break;
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: _TimelineMenuAction.edit,
                    child: Text('Editar'),
                  ),
                  PopupMenuItem(
                    value: _TimelineMenuAction.delete,
                    child: Text('Excluir'),
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

class _Thumbnail extends StatelessWidget {
  const _Thumbnail({this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    const size = 72.0;
    if (url == null || url!.isEmpty) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          Icons.image_outlined,
          color: Theme.of(context).colorScheme.outline,
        ),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        url!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return SizedBox(
            width: size,
            height: size,
            child: const Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) => Container(
          width: size,
          height: size,
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Icon(
            Icons.broken_image_outlined,
            color: Theme.of(context).colorScheme.outline,
          ),
        ),
      ),
    );
  }
}
