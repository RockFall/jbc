import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/profile/jbc_profile.dart';
import '../../core/providers.dart';
import '../../data/models/idea.dart';
import 'idea_detail_screen.dart';
import 'ideas_labels.dart';

enum IdeaListFilter {
  active,
  done,
  archived,
}

class IdeasScreen extends ConsumerStatefulWidget {
  const IdeasScreen({super.key});

  @override
  ConsumerState<IdeasScreen> createState() => _IdeasScreenState();
}

class _IdeasScreenState extends ConsumerState<IdeasScreen> {
  IdeaListFilter _filter = IdeaListFilter.active;
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(ideasProvider);
    final query = _searchController.text.trim().toLowerCase();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: SegmentedButton<IdeaListFilter>(
            segments: const [
              ButtonSegment(
                value: IdeaListFilter.active,
                label: Text('Ativas'),
                icon: Icon(Icons.lightbulb_outline, size: 18),
              ),
              ButtonSegment(
                value: IdeaListFilter.done,
                label: Text('Realizadas'),
                icon: Icon(Icons.check_circle_outline, size: 18),
              ),
              ButtonSegment(
                value: IdeaListFilter.archived,
                label: Text('Arquivadas'),
                icon: Icon(Icons.archive_outlined, size: 18),
              ),
            ],
            selected: {_filter},
            onSelectionChanged: (s) {
              setState(() => _filter = s.first);
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Buscar por título',
              prefixIcon: const Icon(Icons.search),
              border: const OutlineInputBorder(),
              isDense: true,
              suffixIcon: query.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {});
                      },
                    )
                  : null,
            ),
            onChanged: (_) => setState(() {}),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: async.when(
            skipLoadingOnReload: true,
            data: (all) {
              var list = all.where(_matchesFilter).toList();
              if (query.isNotEmpty) {
                list = list
                    .where((i) => i.title.toLowerCase().contains(query))
                    .toList();
              }
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
                              query.isNotEmpty
                                  ? 'Nenhuma ideia com esse título nesta lista.'
                                  : _filter == IdeaListFilter.active
                                      ? 'Nenhuma ideia ativa.\nToque em + para registrar a primeira.'
                                      : _filter == IdeaListFilter.done
                                          ? 'Nenhuma ideia realizada por enquanto.'
                                          : 'Nada no arquivo.',
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
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  itemCount: list.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final idea = list[index];
                    return Card(
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () {
                          Navigator.of(context).push<void>(
                            MaterialPageRoute<void>(
                              builder: (_) => IdeaDetailScreen(idea: idea),
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Text(
                                      idea.title,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                  Chip(
                                    label: Text(
                                      ideaStatusLabelPt(idea.status),
                                      style: Theme.of(context).textTheme.labelSmall,
                                    ),
                                    visualDensity: VisualDensity.compact,
                                    padding: EdgeInsets.zero,
                                  ),
                                ],
                              ),
                              if (idea.category != null) ...[
                                const SizedBox(height: 6),
                                Text(
                                  ideaCategoryLabelPt(idea.category!),
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: Theme.of(context).colorScheme.primary,
                                      ),
                                ),
                              ],
                              const SizedBox(height: 4),
                              Text(
                                JbcProfile.displayNameForStorageKey(idea.createdBy),
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                      color: Theme.of(context).colorScheme.outline,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
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
