import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Padrão único de carregamento, vazio, erro e retry para listas assíncronas.
class AsyncListBody<T> extends ConsumerWidget {
  const AsyncListBody({
    super.key,
    required this.asyncValue,
    required this.itemCount,
    required this.itemBuilder,
    required this.emptyMessage,
    required this.onRetry,
  });

  final AsyncValue<List<T>> asyncValue;
  final int Function(List<T> data) itemCount;
  final Widget Function(BuildContext context, List<T> data, int index) itemBuilder;
  final String emptyMessage;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return asyncValue.when(
      skipLoadingOnReload: true,
      data: (data) {
        if (data.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                emptyMessage,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          );
        }
        final n = itemCount(data);
        return ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          itemCount: n,
          separatorBuilder: (context, index) => const SizedBox(height: 8),
          itemBuilder: (context, index) => itemBuilder(context, data, index),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Não foi possível carregar.',
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
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Tentar de novo'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
