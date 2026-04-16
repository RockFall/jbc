import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/profile/jbc_profile.dart';
import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/timeline_event.dart';
import '../../data/models/timeline_event_comment.dart';
import '../../data/repositories/noop_repository.dart';
import 'timeline_event_editor_screen.dart';

class TimelineEventDetailScreen extends ConsumerStatefulWidget {
  const TimelineEventDetailScreen({super.key, required this.initialEvent});

  final TimelineEvent initialEvent;

  @override
  ConsumerState<TimelineEventDetailScreen> createState() =>
      _TimelineEventDetailScreenState();
}

class _TimelineEventDetailScreenState extends ConsumerState<TimelineEventDetailScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final PageController _pageController;
  late final TextEditingController _commentController;
  int _carouselPage = 0;
  bool _posting = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    final urls = widget.initialEvent.imageUrls;
    final initial = urls.isEmpty
        ? 0
        : widget.initialEvent.primaryImageIndex.clamp(0, urls.length - 1);
    _pageController = PageController(initialPage: initial);
    _carouselPage = initial;
    _commentController = TextEditingController();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pageController.dispose();
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
        const SnackBar(content: Text('Escolha quem é você nos ajustes antes de comentar.')),
      );
      return;
    }
    if (ref.read(repositoryProvider) is NoopRepository) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Configure Supabase para enviar comentários.')),
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
        const SnackBar(content: Text('Configure Supabase para apagar comentários.')),
      );
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Apagar comentário?'),
        content: const Text('Isso remove a mensagem para todo mundo.'),
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
                  'Esta memória não existe mais.',
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
    final carouselH = (MediaQuery.sizeOf(context).height * 0.44).clamp(220.0, 520.0);
    final dateStr = DateFormat(
      "EEEE, d 'de' MMMM 'de' y",
      'pt_BR',
    ).format(event.occurredAt.toLocal());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Memória'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.appBarOnBrandForeground,
          unselectedLabelColor: AppTheme.appBarOnBrandForeground.withValues(alpha: 0.65),
          indicatorColor: AppTheme.appBarOnBrandForeground,
          tabs: const [
            Tab(text: 'Detalhes'),
            Tab(text: 'Comentários'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Editar',
            onPressed: () => _openEdit(event),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Excluir',
            onPressed: () => _confirmDelete(event),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDetailsTab(context, theme, scheme, event, carouselH, dateStr),
          _buildCommentsTab(
            context,
            theme,
            scheme,
            event.id,
            ref.watch(userProfileProvider),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsTab(
    BuildContext context,
    ThemeData theme,
    ColorScheme scheme,
    TimelineEvent event,
    double carouselH,
    String dateStr,
  ) {
    final urls = event.imageUrls;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        0,
        0,
        0,
        16 + MediaQuery.viewPaddingOf(context).bottom,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: carouselH,
            child: urls.isEmpty
                ? ColoredBox(
                    color: scheme.surfaceContainerHighest,
                    child: Center(
                      child: Icon(
                        Icons.photo_library_outlined,
                        size: 72,
                        color: scheme.outline,
                      ),
                    ),
                  )
                : Stack(
                    alignment: Alignment.bottomCenter,
                    children: [
                      PageView.builder(
                        controller: _pageController,
                        itemCount: urls.length,
                        onPageChanged: (i) => setState(() => _carouselPage = i),
                        itemBuilder: (context, i) {
                          return CachedNetworkImage(
                            imageUrl: urls[i],
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: carouselH,
                            fadeInDuration: Duration.zero,
                            fadeOutDuration: Duration.zero,
                            placeholder: (context, _) => ColoredBox(
                              color: scheme.surfaceContainerHighest,
                              child: const Center(
                                child: SizedBox(
                                  width: 36,
                                  height: 36,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              ),
                            ),
                            errorWidget: (context, url, error) => ColoredBox(
                              color: scheme.surfaceContainerHighest,
                              child: Icon(
                                Icons.broken_image_outlined,
                                size: 64,
                                color: scheme.outline,
                              ),
                            ),
                          );
                        },
                      ),
                      if (urls.length > 1)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: List.generate(urls.length, (i) {
                              final sel = i == _carouselPage;
                              return Container(
                                width: sel ? 10 : 7,
                                height: sel ? 10 : 7,
                                margin: const EdgeInsets.symmetric(horizontal: 4),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: sel
                                      ? scheme.primary
                                      : scheme.surface.withValues(alpha: 0.65),
                                  border: Border.all(
                                    color: scheme.outline.withValues(alpha: 0.35),
                                  ),
                                ),
                              );
                            }),
                          ),
                        ),
                    ],
                  ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Text(
              event.title,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                height: 1.2,
              ),
            ),
          ),
          if (event.description.trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Text(
                event.description.trim(),
                style: theme.textTheme.bodyLarge?.copyWith(height: 1.45),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
            child: Text(
              dateStr,
              style: theme.textTheme.titleSmall?.copyWith(
                color: scheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (event.origin == TimelineEventOrigin.fromHangout)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Chip(
                  label: const Text('Rolê'),
                  visualDensity: VisualDensity.compact,
                  backgroundColor: scheme.tertiaryContainer,
                  labelStyle: TextStyle(
                    color: scheme.onTertiaryContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCommentsTab(
    BuildContext context,
    ThemeData theme,
    ColorScheme scheme,
    String eventId,
    JbcProfile? currentProfile,
  ) {
    final async = ref.watch(timelineEventCommentsProvider(eventId));

    return Column(
      children: [
        Expanded(
          child: async.when(
            skipLoadingOnReload: true,
            data: (comments) {
              if (comments.isEmpty) {
                return ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    SizedBox(
                      height: MediaQuery.sizeOf(context).height * 0.25,
                      child: Center(
                        child: Text(
                          'Nenhum comentário ainda.\nDigite abaixo para começar.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                itemCount: comments.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final c = comments[i];
                  final name = JbcProfile.displayNameForStorageKey(c.author);
                  final time = DateFormat('dd/MM/yyyy HH:mm').format(c.createdAt.toLocal());
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          backgroundColor: scheme.primaryContainer,
                          foregroundColor: scheme.onPrimaryContainer,
                          child: Text(
                            name.isNotEmpty ? name[0].toUpperCase() : '?',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      name,
                                      style: theme.textTheme.titleSmall?.copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    time,
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: scheme.outline,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(c.body, style: theme.textTheme.bodyMedium),
                            ],
                          ),
                        ),
                        if (currentProfile != null &&
                            c.author == currentProfile.storageKey)
                          IconButton(
                            icon: Icon(
                              Icons.delete_outline,
                              size: 22,
                              color: scheme.outline,
                            ),
                            tooltip: 'Apagar meu comentário',
                            onPressed: () => _confirmDeleteComment(c, eventId),
                          ),
                      ],
                    ),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('$e', textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: () => ref.invalidate(timelineEventCommentsProvider(eventId)),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Tentar de novo'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        Material(
          elevation: 8,
          color: scheme.surface,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              12,
              8,
              12,
              8 + MediaQuery.viewPaddingOf(context).bottom,
            ),
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
                      hintText: 'Escreva um comentário…',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onSubmitted: _posting ? null : (_) => _submitComment(eventId),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _posting ? null : () => _submitComment(eventId),
                  icon: _posting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send_rounded),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
