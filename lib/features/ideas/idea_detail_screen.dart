import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/profile/jbc_profile.dart';
import '../../core/providers.dart';
import '../../data/models/idea.dart';
import '../../data/repositories/noop_repository.dart';
import '../hangouts/hangout_editor_screen.dart';
import 'idea_editor_screen.dart';
import 'ideas_labels.dart';

class IdeaDetailScreen extends ConsumerWidget {
  const IdeaDetailScreen({super.key, required this.idea});

  final Idea idea;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final created = DateFormat('dd/MM/yyyy HH:mm').format(idea.createdAt.toLocal());
    final updated = DateFormat('dd/MM/yyyy HH:mm').format(idea.updatedAt.toLocal());

    Future<void> setStatus(IdeaStatus s) async {
      final me = ref.read(userProfileProvider);
      try {
        await ref.read(repositoryProvider).updateIdeaStatus(
              existing: idea,
              status: s,
              archivedBy: s == IdeaStatus.archived ? me : null,
            );
        ref.invalidate(ideasProvider);
        if (context.mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Status atualizado.')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro: $e')),
          );
        }
      }
    }

    Future<void> confirmDelete() async {
      final ok = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Excluir ideia?'),
          content: Text('Remover “${idea.title}” para todo mundo?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Não')),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Excluir')),
          ],
        ),
      );
      if (ok != true || !context.mounted) return;
      try {
        await ref.read(repositoryProvider).deleteIdea(idea);
        ref.invalidate(ideasProvider);
        if (context.mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ideia excluída.')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro: $e')),
          );
        }
      }
    }

    Future<void> transformToHangout() async {
      if (ref.read(repositoryProvider) is NoopRepository) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Configure Supabase para criar rolês a partir da ideia.'),
          ),
        );
        return;
      }
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => HangoutEditorScreen(prefillFromIdea: idea),
        ),
      );
      if (context.mounted) {
        ref.invalidate(ideasProvider);
        ref.invalidate(hangoutsProvider);
        Navigator.of(context).pop();
      }
    }

    final actions = <Widget>[];

    if (idea.status == IdeaStatus.active) {
      actions.addAll([
        FilledButton.tonalIcon(
          onPressed: transformToHangout,
          icon: const Icon(Icons.event_outlined),
          label: const Text('Transformar em rolê'),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => setStatus(IdeaStatus.done),
          icon: const Icon(Icons.check_circle_outline),
          label: const Text('Marcar como realizada'),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () => setStatus(IdeaStatus.archived),
          icon: const Icon(Icons.sentiment_dissatisfied_outlined),
          label: const Text('Odiei'),
        ),
      ]);
    } else if (idea.status == IdeaStatus.done) {
      actions.addAll([
        OutlinedButton.icon(
          onPressed: () => setStatus(IdeaStatus.archived),
          icon: const Icon(Icons.sentiment_dissatisfied_outlined),
          label: const Text('Odiei'),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () => setStatus(IdeaStatus.active),
          icon: const Icon(Icons.restore_outlined),
          label: const Text('Reativar'),
        ),
      ]);
    } else {
      actions.add(
        OutlinedButton.icon(
          onPressed: () => setStatus(IdeaStatus.active),
          icon: const Icon(Icons.unarchive_outlined),
          label: const Text('Reativar'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ideia'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () async {
              await Navigator.of(context).push<void>(
                MaterialPageRoute<void>(
                  builder: (_) => IdeaEditorScreen(initial: idea),
                ),
              );
              if (context.mounted) {
                ref.invalidate(ideasProvider);
                Navigator.of(context).pop();
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: confirmDelete,
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          16 + MediaQuery.viewPaddingOf(context).bottom,
        ),
        children: [
          Row(
            children: [
              Chip(label: Text(ideaStatusLabelPt(idea.status))),
              if (idea.category != null) ...[
                const SizedBox(width: 8),
                Chip(
                  label: Text(ideaCategoryLabelPt(idea.category!)),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Text(
            idea.title,
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            'Por ${JbcProfile.displayNameForStorageKey(idea.createdBy)}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
          if (idea.status == IdeaStatus.archived) ...[
            const SizedBox(height: 6),
            Text(
              idea.archivedBy != null && idea.archivedBy!.isNotEmpty
                  ? 'Odiado por: ${JbcProfile.displayNameForStorageKey(idea.archivedBy!)}'
                  : 'Odiado por: —',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.tertiary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          Text(
            'Criada em $created · Atualizada $updated',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
          if ((idea.description ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 20),
            Text(
              idea.description!,
              style: theme.textTheme.bodyLarge,
            ),
          ],
          const SizedBox(height: 32),
          Align(
            alignment: Alignment.center,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 340),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: actions,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
