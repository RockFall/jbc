import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../core/profile/jbc_profile.dart';
import '../../core/providers.dart';
import '../../data/models/timeline_event.dart';
import '../../data/models/timeline_event_comment.dart';
import '../../data/models/timeline_event_reaction.dart';
import '../../data/repositories/noop_repository.dart';
import 'collage/timeline_collage_ornaments.dart';
import 'collage/timeline_collage_seed.dart';
import 'collage/timeline_photo_lightbox.dart';
import 'collage/timeline_reaction_picker_sheet.dart';
import 'timeline_event_editor_screen.dart';

class TimelineEventDetailScreen extends ConsumerStatefulWidget {
  const TimelineEventDetailScreen({super.key, required this.initialEvent});

  final TimelineEvent initialEvent;

  @override
  ConsumerState<TimelineEventDetailScreen> createState() =>
      _TimelineEventDetailScreenState();
}

class _TimelineEventDetailScreenState extends ConsumerState<TimelineEventDetailScreen> {
  final _commentController = TextEditingController();
  bool _posting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  TimelineEvent? _findInList(List<TimelineEvent>? list) {
    if (list == null) return null;
    for (final e in list) {
      if (e.id == widget.initialEvent.id) return e;
    }
    return null;
  }

  Future<void> _openEdit(TimelineEvent event) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => TimelineEventEditorScreen(initial: event),
      ),
    );
    if (mounted) ref.invalidate(timelineEventsProvider);
  }

  Future<void> _confirmDelete(TimelineEvent event) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir memória?'),
        content: Text('Remover “${event.title}” para todo mundo?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Excluir')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await ref.read(repositoryProvider).deleteTimelineEvent(event);
      ref.invalidate(timelineEventsProvider);
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Memória excluída.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao excluir: $e')),
      );
    }
  }

  Future<void> _submitComment(String eventId) async {
    final me = ref.read(userProfileProvider);
    if (me == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Escolhe quem és nos ajustes antes de comentar.')),
      );
      return;
    }
    if (ref.read(repositoryProvider) is NoopRepository) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Configura o Supabase para comentários.')),
      );
      return;
    }
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    setState(() => _posting = true);
    try {
      await ref.read(repositoryProvider).addTimelineEventComment(
            timelineEventId: eventId,
            author: me,
            body: text,
          );
      _commentController.clear();
      ref.invalidate(timelineEventCommentsProvider(eventId));
      if (mounted) FocusScope.of(context).unfocus();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _posting = false);
    }
  }

  Future<void> _confirmDeleteComment(TimelineEventComment comment, String eventId) async {
    final me = ref.read(userProfileProvider);
    if (me == null || comment.author != me.storageKey) return;
    if (ref.read(repositoryProvider) is NoopRepository) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Configura o Supabase para apagar comentários.')),
      );
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Apagar comentário?'),
        content: const Text('Remove a mensagem para toda a gente.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Apagar')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await ref.read(repositoryProvider).deleteTimelineEventComment(
            comment: comment,
            deletedBy: me,
          );
      ref.invalidate(timelineEventCommentsProvider(eventId));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Comentário removido.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro: $e')),
      );
    }
  }

  Future<void> _pickReaction(String eventId, JbcProfile me) async {
    if (ref.read(repositoryProvider) is NoopRepository) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Configura o Supabase para reações.')),
      );
      return;
    }
    final emoji = await showTimelineReactionPicker(context);
    if (emoji == null || !mounted) return;
    try {
      await ref.read(repositoryProvider).upsertTimelineEventReaction(
            timelineEventId: eventId,
            profile: me,
            emoji: emoji,
          );
      ref.invalidate(timelineEventReactionsProvider(eventId));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao guardar reação: $e')),
        );
      }
    }
  }

  static int _mapPrimaryIndexToFilteredUrls(TimelineEvent event, List<String> filtered) {
    if (filtered.isEmpty) return 0;
    final raw = event.imageUrls;
    final p = event.primaryImageIndex;
    if (p >= 0 && p < raw.length) {
      final key = raw[p].trim();
      if (key.isEmpty) return 0;
      final i = filtered.indexOf(key);
      if (i >= 0) return i;
    }
    return 0.clamp(0, filtered.length - 1);
  }

  void _openLightbox(List<String> urls, int index) {
    if (urls.isEmpty) return;
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => TimelinePhotoLightbox(
          urls: urls,
          initialIndex: index,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final eventsAsync = ref.watch(timelineEventsProvider);
    final list = eventsAsync.maybeWhen(data: (l) => l, orElse: () => null);
    final removed = list != null && _findInList(list) == null;

    if (removed) {
      return Scaffold(
        appBar: AppBar(title: const Text('Memória')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Esta memória já não existe.',
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Voltar'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final event = _findInList(list) ?? widget.initialEvent;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final dateStr = DateFormat(
      "EEEE, d 'de' MMMM 'de' y",
      'pt_BR',
    ).format(event.occurredAt.toLocal());
    final commentsAsync = ref.watch(timelineEventCommentsProvider(event.id));
    final reactionsAsync = ref.watch(timelineEventReactionsProvider(event.id));
    final me = ref.watch(userProfileProvider);
    final displayPhotoUrls = event.imageUrls
        .where((u) => u.trim().isNotEmpty)
        .map((u) => u.trim())
        .toList();
    final displayPrimaryIndex = _mapPrimaryIndexToFilteredUrls(event, displayPhotoUrls);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: const Color(0xE6FAF6F0),
        foregroundColor: scheme.onSurface,
        iconTheme: IconThemeData(color: scheme.onSurface),
        actionsIconTheme: IconThemeData(color: scheme.onSurface),
        elevation: 0,
        title: Text(
          'Colagem',
          style: TextStyle(color: scheme.onSurface),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Editar memória',
            onPressed: () => _openEdit(event),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Excluir memória',
            onPressed: () => _confirmDelete(event),
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFFDF8F3),
                  Color(0xFFF5EDE6),
                  Color(0xFFF8F2EC),
                ],
              ),
            ),
          ),
          Positioned.fill(
            child: CollageOrnamentsLayer(
              eventId: event.id,
              reduceMotion: reduceMotion,
            ),
          ),
          SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: MediaQuery.paddingOf(context).top + kToolbarHeight + 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _PhotoCollageBlock(
                    eventId: event.id,
                    imageUrls: displayPhotoUrls,
                    primaryIndex: displayPrimaryIndex,
                    reduceMotion: reduceMotion,
                    onOpenPhoto: (i) => _openLightbox(displayPhotoUrls, i),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (event.origin == TimelineEventOrigin.fromHangout)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Chip(
                            avatar: const Icon(Icons.event, size: 18),
                            label: const Text('Vinda de um rolê'),
                            visualDensity: VisualDensity.compact,
                            backgroundColor: scheme.tertiaryContainer.withValues(alpha: 0.85),
                            labelStyle: TextStyle(
                              color: scheme.onTertiaryContainer,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      Text(
                        event.title,
                        style: GoogleFonts.caveat(
                          fontSize: 36,
                          height: 1.15,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF3E2723),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        dateStr,
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: scheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (event.description.trim().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                    child: Material(
                      color: const Color(0xFFFFFDF9),
                      elevation: 1,
                      shadowColor: Colors.black26,
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
                        child: Text(
                          event.description.trim(),
                          style: theme.textTheme.bodyLarge?.copyWith(
                            height: 1.5,
                            color: scheme.onSurface,
                          ),
                        ),
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: reactionsAsync.when(
                    data: (reactions) => _ReactionStrip(
                      reactions: reactions,
                      me: me,
                      onPickMine: me != null ? () => _pickReaction(event.id, me) : null,
                    ),
                    loading: () => const LinearProgressIndicator(minHeight: 2),
                    error: (e, _) => Text('Reações: $e', style: theme.textTheme.bodySmall),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
                  child: Text(
                    'Notas do trio',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                commentsAsync.when(
                  data: (comments) {
                    if (comments.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        child: Text(
                          'Ainda não há notas nesta memória. Escreva a primeira abaixo.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      );
                    }
                    return ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: comments.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 4),
                      itemBuilder: (context, i) {
                        final c = comments[i];
                        return _ScrapCommentTile(
                          comment: c,
                          index: i,
                          reduceMotion: reduceMotion,
                          currentProfile: me,
                          onDelete: () => _confirmDeleteComment(c, event.id),
                        );
                      },
                    );
                  },
                  loading: () => const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (e, _) => Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Text('$e', textAlign: TextAlign.center),
                        FilledButton.icon(
                          onPressed: () => ref.invalidate(timelineEventCommentsProvider(event.id)),
                          icon: const Icon(Icons.refresh),
                          label: const Text('Tentar de novo'),
                        ),
                      ],
                    ),
                  ),
                  skipLoadingOnReload: true,
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    12,
                    16,
                    12,
                    16 + MediaQuery.viewPaddingOf(context).bottom,
                  ),
                  child: Material(
                    color: const Color(0xFFFFFDF9),
                    elevation: 3,
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _commentController,
                              minLines: 1,
                              maxLines: 4,
                              textCapitalization: TextCapitalization.sentences,
                              decoration: const InputDecoration(
                                hintText: 'Deixa uma nota…',
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              ),
                              onSubmitted: _posting ? null : (_) => _submitComment(event.id),
                            ),
                          ),
                          Semantics(
                            label: 'Enviar comentário',
                            button: true,
                            child: IconButton.filled(
                              onPressed: _posting ? null : () => _submitComment(event.id),
                              icon: _posting
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Icon(Icons.send_rounded),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PhotoCollageBlock extends StatelessWidget {
  const _PhotoCollageBlock({
    required this.eventId,
    required this.imageUrls,
    required this.primaryIndex,
    required this.reduceMotion,
    required this.onOpenPhoto,
  });

  final String eventId;
  final List<String> imageUrls;
  final int primaryIndex;
  final bool reduceMotion;
  final void Function(int index) onOpenPhoto;

  @override
  Widget build(BuildContext context) {
    final urls = imageUrls;
    final scheme = Theme.of(context).colorScheme;
    final seed = timelineCollageSeed(eventId);
    final primary = primaryIndex.clamp(0, urls.isEmpty ? 0 : urls.length - 1);

    if (urls.isEmpty) {
      return Semantics(
        label: 'Sem fotos nesta memória',
        child: Material(
          borderRadius: BorderRadius.circular(20),
          color: scheme.surfaceContainerHighest.withValues(alpha: 0.65),
          child: SizedBox(
            height: 200,
            child: Center(
              child: Icon(Icons.photo_library_outlined, size: 72, color: scheme.outline),
            ),
          ),
        ),
      );
    }

    if (urls.length == 1) {
      return _tappablePhoto(
        context,
        urls[0],
        border: Border.all(color: scheme.primary, width: 3),
        onTap: () => onOpenPhoto(0),
        height: 280,
      );
    }

    if (urls.length <= 6) {
      final h = 260.0;
      final n = urls.length;
      return LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          return SizedBox(
            height: h,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                for (var i = 0; i < urls.length; i++)
                  Positioned(
                    left: _collageSpreadLeft(
                      index: i,
                      count: n,
                      width: w,
                      photoWidth: i == primary ? 150.0 : 118.0,
                      seed: seed,
                    ),
                    top: 12 + (i.isEven ? 0.0 : 18.0) + collageOffsetY(seed, i),
                    child: Transform.rotate(
                      angle: collageAngleRad(seed, i, reduceMotion: reduceMotion),
                      child: Material(
                        elevation: i == primary ? 6 : 2,
                        borderRadius: BorderRadius.circular(12),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: () => onOpenPhoto(i),
                          child: Semantics(
                            label: 'Foto ${i + 1} de ${urls.length}, abrir em ecrã completo',
                            button: true,
                            child: Container(
                              width: i == primary ? 150 : 118,
                              height: i == primary ? 190 : 148,
                              decoration: BoxDecoration(
                                border: i == primary
                                    ? Border.all(color: scheme.primary, width: 2.5)
                                    : null,
                              ),
                              child: CachedNetworkImage(
                                imageUrl: urls[i],
                                fit: BoxFit.cover,
                                fadeInDuration: Duration.zero,
                                placeholder: (context, url) => ColoredBox(
                                  color: scheme.surfaceContainerHighest,
                                  child: const Center(
                                    child: SizedBox(
                                      width: 28,
                                      height: 28,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    ),
                                  ),
                                ),
                                errorWidget: (context, url, error) => Icon(
                                  Icons.broken_image_outlined,
                                  color: scheme.outline,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 132,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: urls.length,
            separatorBuilder: (context, index) => const SizedBox(width: 10),
            itemBuilder: (context, i) {
              final isPrimary = i == primary;
              return Material(
                elevation: isPrimary ? 4 : 1,
                borderRadius: BorderRadius.circular(12),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => onOpenPhoto(i),
                  child: Semantics(
                    label: 'Foto ${i + 1} de ${urls.length}',
                    button: true,
                    child: Container(
                      width: isPrimary ? 108 : 96,
                      height: 128,
                      decoration: BoxDecoration(
                        border: isPrimary ? Border.all(color: scheme.primary, width: 2) : null,
                      ),
                      child: CachedNetworkImage(
                        imageUrl: urls[i],
                        fit: BoxFit.cover,
                        fadeInDuration: Duration.zero,
                        placeholder: (context, url) => ColoredBox(color: scheme.surfaceContainerHighest),
                        errorWidget: (context, url, error) =>
                            Icon(Icons.broken_image_outlined, color: scheme.outline),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  /// Distribui os centros das fotos ao longo da largura útil (em vez de empilhar à esquerda).
  static double _collageSpreadLeft({
    required int index,
    required int count,
    required double width,
    required double photoWidth,
    required int seed,
  }) {
    if (count <= 1) return ((width - photoWidth) / 2).clamp(0.0, double.infinity);
    const margin = 4.0;
    final inner = (width - 2 * margin).clamp(48.0, double.infinity);
    final t = count > 1 ? index / (count - 1) : 0.5;
    final cx = margin + inner * t;
    var left = cx - photoWidth / 2 + collageOffsetX(seed, index);
    final maxLeft = (width - photoWidth).clamp(0.0, double.infinity);
    return left.clamp(0.0, maxLeft);
  }

  Widget _tappablePhoto(
    BuildContext context,
    String url, {
    required VoidCallback onTap,
    required double height,
    BoxBorder? border,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Semantics(
          label: 'Foto principal, abrir em ecrã completo',
          button: true,
          child: Container(
            height: height,
            decoration: BoxDecoration(border: border),
            width: double.infinity,
            child: CachedNetworkImage(
              imageUrl: url,
              fit: BoxFit.cover,
              fadeInDuration: Duration.zero,
              placeholder: (context, url) => ColoredBox(
                color: scheme.surfaceContainerHighest,
                child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
              ),
              errorWidget: (context, url, error) => Center(
                child: Icon(Icons.broken_image_outlined, size: 56, color: scheme.outline),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ReactionStrip extends StatelessWidget {
  const _ReactionStrip({
    required this.reactions,
    required this.me,
    required this.onPickMine,
  });

  final List<TimelineEventReaction> reactions;
  final JbcProfile? me;
  final VoidCallback? onPickMine;

  String? _emojiFor(JbcProfile p) {
    for (final r in reactions) {
      if (r.profile == p.storageKey) return r.emoji;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Material(
      color: const Color(0xFFFFFDF9),
      elevation: 2,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Impressões do trio',
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                for (final p in JbcProfile.values) ...[
                  Expanded(
                    child: _ReactionSlot(
                      profile: p,
                      emoji: _emojiFor(p),
                      canEdit: me == p && onPickMine != null,
                      onTap: me == p ? onPickMine : null,
                    ),
                  ),
                  if (p != JbcProfile.values.last) const SizedBox(width: 8),
                ],
              ],
            ),
            if (me != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Clique na sua impressão para mudar o emoji.',
                  style: theme.textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ReactionSlot extends StatelessWidget {
  const _ReactionSlot({
    required this.profile,
    required this.emoji,
    required this.canEdit,
    required this.onTap,
  });

  final JbcProfile profile;
  final String? emoji;
  final bool canEdit;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final label = 'Reação de ${profile.displayName}: ${emoji ?? 'nenhuma'}';
    return Semantics(
      label: label,
      button: canEdit,
      child: Material(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: canEdit ? onTap : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              children: [
                Text(
                  profile.displayName,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  emoji ?? '·',
                  style: TextStyle(
                    fontSize: emoji != null ? 32 : 18,
                    height: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ScrapCommentTile extends StatelessWidget {
  const _ScrapCommentTile({
    required this.comment,
    required this.index,
    required this.reduceMotion,
    required this.currentProfile,
    required this.onDelete,
  });

  final TimelineEventComment comment;
  final int index;
  final bool reduceMotion;
  final JbcProfile? currentProfile;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final name = JbcProfile.displayNameForStorageKey(comment.author);
    final time = DateFormat('dd/MM HH:mm').format(comment.createdAt.toLocal());
    final tilt = reduceMotion ? 0.0 : (index.isEven ? -0.02 : 0.025);
    final align = index.isEven ? CrossAxisAlignment.start : CrossAxisAlignment.end;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        crossAxisAlignment: align,
        children: [
          Transform.rotate(
            angle: tilt,
            child: Material(
              elevation: 2,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(18),
                topRight: const Radius.circular(18),
                bottomLeft: Radius.circular(index.isEven ? 4 : 18),
                bottomRight: Radius.circular(index.isEven ? 18 : 4),
              ),
              color: const Color(0xFFFFFDF9),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.88),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: scheme.primaryContainer,
                            foregroundColor: scheme.onPrimaryContainer,
                            child: Text(
                              name.isNotEmpty ? name[0].toUpperCase() : '?',
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              name,
                              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                            ),
                          ),
                          Text(
                            time,
                            style: theme.textTheme.labelSmall?.copyWith(color: scheme.outline),
                          ),
                          if (comment.author == currentProfile?.storageKey)
                            IconButton(
                              icon: Icon(Icons.close, size: 20, color: scheme.outline),
                              tooltip: 'Apagar a minha nota',
                              onPressed: onDelete,
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(comment.body, style: theme.textTheme.bodyMedium?.copyWith(height: 1.45)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
