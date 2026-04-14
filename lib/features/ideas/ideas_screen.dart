import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

import '../../core/profile/jbc_profile.dart';
import '../../core/providers.dart';
import '../../data/models/idea.dart';
import 'idea_category_style.dart';
import 'idea_detail_screen.dart';
import 'ideas_labels.dart';

enum IdeaListFilter {
  active,
  done,
  archived,
}

/// Filtro “sem categoria” nas tags (multiselect).
const Object _kUncategorized = Object();

class IdeasScreen extends ConsumerStatefulWidget {
  const IdeasScreen({super.key});

  @override
  ConsumerState<IdeasScreen> createState() => _IdeasScreenState();
}

class _IdeasScreenState extends ConsumerState<IdeasScreen> {
  IdeaListFilter _filter = IdeaListFilter.active;
  final Set<Object> _categoryKeys = {};

  bool _matchesFilter(Idea i) {
    switch (_filter) {
      case IdeaListFilter.active:
        return i.status == IdeaStatus.active;
      case IdeaListFilter.done:
        return i.status == IdeaStatus.done;
      case IdeaListFilter.archived:
        return i.status == IdeaStatus.archived;
    }
  }

  bool _matchesCategory(Idea i) {
    if (_categoryKeys.isEmpty) return true;
    if (_categoryKeys.contains(_kUncategorized) && i.category == null) {
      return true;
    }
    if (i.category != null && _categoryKeys.contains(i.category)) {
      return true;
    }
    return false;
  }

  void _toggleCategory(Object key) {
    setState(() {
      if (_categoryKeys.contains(key)) {
        _categoryKeys.remove(key);
      } else {
        _categoryKeys.add(key);
      }
    });
  }

  static const _filters = [
    IdeaListFilter.active,
    IdeaListFilter.done,
    IdeaListFilter.archived,
  ];

  String _filterLabel(IdeaListFilter f) {
    switch (f) {
      case IdeaListFilter.active:
        return 'A fazer';
      case IdeaListFilter.done:
        return 'Já fizemos';
      case IdeaListFilter.archived:
        return 'Odiei';
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(ideasProvider);
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
          child: Row(
            children: _filters.map((f) {
              final sel = _filter == f;
              return Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => setState(() => _filter = f),
                    borderRadius: BorderRadius.circular(12),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: sel ? scheme.primary : Colors.transparent,
                            width: sel ? 2.5 : 0,
                          ),
                        ),
                      ),
                      child: Text(
                        _filterLabel(f),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: sel ? FontWeight.w800 : FontWeight.w500,
                          color: sel ? scheme.primary : scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        SizedBox(
          height: 48,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            children: [
              _CategoryFilterChip(
                label: 'Sem categoria',
                icon: Icons.inbox_outlined,
                selected: _categoryKeys.contains(_kUncategorized),
                color: ideaCategoryColor(null, scheme),
                onTap: () => _toggleCategory(_kUncategorized),
              ),
              ...ideaCategoryPickerOrder().map(
                (c) => _CategoryFilterChip(
                  label: ideaCategoryLabelPt(c),
                  icon: ideaCategoryIcon(c),
                  selected: _categoryKeys.contains(c),
                  color: ideaCategoryColor(c, scheme),
                  onTap: () => _toggleCategory(c),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Expanded(
          child: async.when(
            skipLoadingOnReload: true,
            data: (all) {
              var list = all.where(_matchesFilter).where(_matchesCategory).toList();
              Future<void> onRefresh() async {
                ref.invalidate(ideasProvider);
                await Future<void>.delayed(const Duration(milliseconds: 400));
              }

              if (list.isEmpty) {
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
                              _categoryKeys.isNotEmpty
                                  ? 'Nenhuma ideia com essas categorias.'
                                  : _filter == IdeaListFilter.active
                                      ? 'Nada por aqui ainda.\nToque em + para a primeira ideia.'
                                      : _filter == IdeaListFilter.done
                                          ? 'Ainda não marcamos nada como “já fizemos”.'
                                          : 'Nada em “Odiei”.',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyLarge,
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
                child: MasonryGridView.count(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 88),
                  crossAxisCount: 2,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  itemCount: list.length,
                  itemBuilder: (context, index) {
                    final idea = list[index];
                    return _IdeaGridTile(idea: idea, filter: _filter);
                  },
                ),
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
                      onPressed: () => ref.invalidate(ideasProvider),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Tentar de novo'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CategoryFilterChip extends StatelessWidget {
  const _CategoryFilterChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fg = selected ? scheme.onPrimary : scheme.onSurface;
    final bg = selected ? scheme.primary : color.withValues(alpha: 0.22);
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 18, color: selected ? fg : color),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: selected ? fg : scheme.onSurface,
                        fontWeight: FontWeight.w600,
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

class _IdeaGridTile extends StatelessWidget {
  const _IdeaGridTile({
    required this.idea,
    required this.filter,
  });

  final Idea idea;
  final IdeaListFilter filter;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final cat = idea.category;
    final base = ideaCategoryColor(cat, scheme);
    final onCard = ThemeData.estimateBrightnessForColor(base) == Brightness.dark
        ? Colors.white
        : scheme.onSurface;
    final subtitle = Theme.of(context).textTheme.labelSmall?.copyWith(
          color: onCard.withValues(alpha: 0.85),
        );

    final extraLines = (idea.title.length / 28).floor().clamp(0, 6);
    final minHeight = 96.0 + extraLines * 18.0;

    return Material(
      color: base,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.of(context).push<void>(
            MaterialPageRoute<void>(
              builder: (_) => IdeaDetailScreen(idea: idea),
            ),
          );
        },
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: minHeight),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 10, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(ideaCategoryIcon(cat), size: 20, color: onCard.withValues(alpha: 0.9)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        idea.title,
                        maxLines: 5,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: onCard,
                          fontWeight: FontWeight.w800,
                          height: 1.2,
                        ),
                      ),
                    ),
                  ],
                ),
                if (filter == IdeaListFilter.archived &&
                    idea.archivedBy != null &&
                    idea.archivedBy!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Odiado por: ${JbcProfile.displayNameForStorageKey(idea.archivedBy!)}',
                    style: subtitle,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
