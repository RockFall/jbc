import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/places/google_places_client.dart';
import '../../core/profile/jbc_profile.dart';
import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/conchinha_request.dart';
import '../../data/repositories/noop_repository.dart';

/// Detalhe do pedido: mapa/resumo, aceites em tempo real, concluir/cancelar (solicitante).
class ConchinhaRequestDetailScreen extends ConsumerWidget {
  const ConchinhaRequestDetailScreen({super.key, required this.requestId});

  final String requestId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider);
    final repo = ref.watch(repositoryProvider);
    final reqAsync = ref.watch(conchinhaRequestProvider(requestId));
    final accAsync = ref.watch(conchinhaAcceptancesProvider(requestId));

    if (repo is NoopRepository) {
      return Scaffold(
        appBar: AppBar(title: const Text('Conchinha')),
        body: const Center(child: Text('Configure o Supabase para ver os pedidos.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pedido de conchinha'),
        backgroundColor: AppTheme.brandRed,
        foregroundColor: Colors.white,
      ),
      body: reqAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro: $e')),
        data: (req) {
          if (req == null) {
            return const Center(child: Text('Pedido não encontrado ou já foi removido.'));
          }
          final isMine = profile?.storageKey == req.requesterKey;
          final fmt = DateFormat('dd/MM HH:mm');
          return accAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Erro: $e')),
            data: (acceptances) {
              final myKey = profile?.storageKey;
              final iAccepted =
                  myKey != null && acceptances.any((a) => a.profileKey == myKey);
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Card(
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (req.address.lat != null &&
                            req.address.lng != null &&
                            GooglePlacesClient.staticMapUrl(
                                  lat: req.address.lat!,
                                  lng: req.address.lng!,
                                ) !=
                                null)
                          AspectRatio(
                            aspectRatio: 16 / 9,
                            child: Image.network(
                              GooglePlacesClient.staticMapUrl(
                                lat: req.address.lat!,
                                lng: req.address.lng!,
                              )!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => Container(
                                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                alignment: Alignment.center,
                                child: Icon(
                                  Icons.place,
                                  size: 48,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ),
                          )
                        else
                          Container(
                            height: 160,
                            color: Theme.of(context).colorScheme.surfaceContainerHighest,
                            alignment: Alignment.center,
                            child: Icon(
                              Icons.place_outlined,
                              size: 56,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                req.address.label,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _statusLabelBr(req.status),
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              Text(
                                'Pedido por ${JbcProfile.displayNameForStorageKey(req.requesterKey)} · '
                                '${fmt.format(req.createdAt.toLocal())}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Quem aceitou',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 8),
                  if (acceptances.isEmpty)
                    Text(
                      req.status == ConchinhaRequestStatus.open
                          ? 'Ninguém aceitou ainda...'
                          : 'Nenhum aceite registrado.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    )
                  else
                    ...acceptances.map(
                      (a) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          child: Text(
                            ConchinhaRequestDetailScreen._initial(
                              JbcProfile.displayNameForStorageKey(a.profileKey),
                            ),
                          ),
                        ),
                        title: Text(JbcProfile.displayNameForStorageKey(a.profileKey)),
                        subtitle: Text(fmt.format(a.createdAt.toLocal())),
                      ),
                    ),
                  if (profile != null && req.status == ConchinhaRequestStatus.open) ...[
                    const SizedBox(height: 24),
                    if (isMine) ...[
                      FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppTheme.brandRed,
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(48),
                        ),
                        onPressed: () async {
                          try {
                            await ref.read(repositoryProvider).completeConchinhaRequest(
                                  requestId: requestId,
                                  requester: profile,
                                );
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Pedido de conchinha concluído.')),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('$e')),
                              );
                            }
                          }
                        },
                        child: const Text('Concluir pedido de conchinha'),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: () async {
                          final ok = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Cancelar conchinha?'),
                              content: const Text(
                                'Os resto do trio deixa de ver este pedido como aberto.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: const Text('Não'),
                                ),
                                FilledButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  child: const Text('Cancelar'),
                                ),
                              ],
                            ),
                          );
                          if (ok != true || !context.mounted) return;
                          try {
                            await ref.read(repositoryProvider).cancelConchinhaRequest(
                                  requestId: requestId,
                                  requester: profile,
                                );
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Pedido cancelado.')),
                              );
                              Navigator.of(context).pop();
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('$e')),
                              );
                            }
                          }
                        },
                        child: const Text('Cancelar pedido'),
                      ),
                    ] else if (!iAccepted) ...[
                      FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppTheme.brandRed,
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(48),
                        ),
                        onPressed: () async {
                          try {
                            await ref.read(repositoryProvider).acceptConchinhaRequest(
                                  requestId: requestId,
                                  profile: profile,
                                );
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Você aceitou!!')),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('$e')),
                              );
                            }
                          }
                        },
                        child: const Text('Aceitar conchinha'),
                      ),
                    ] else
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          'Você já tinha aceito este pedido.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                  ],
                ],
              );
            },
          );
        },
      ),
    );
  }

  static String _initial(String name) {
    final t = name.trim();
    if (t.isEmpty) return '?';
    return t.substring(0, 1).toUpperCase();
  }

  static String _statusLabelBr(ConchinhaRequestStatus s) {
    switch (s) {
      case ConchinhaRequestStatus.open:
        return 'Status: aberto';
      case ConchinhaRequestStatus.completed:
        return 'Status: concluído';
      case ConchinhaRequestStatus.cancelled:
        return 'Status: cancelado';
    }
  }
}
