import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/notifications/jbc_notification_types.dart';
import '../../core/profile/jbc_profile.dart';
import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/jbc_app_notification.dart';
import '../../data/repositories/noop_repository.dart';
import '../conchinha/conchinha_match_result_screen.dart';
import '../conchinha/conchinha_request_detail_screen.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(jbcAppNotificationsProvider);
    final repo = ref.watch(repositoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificações'),
        actions: [
          TextButton(
            style: AppTheme.appBarActionTextButtonStyle,
            onPressed: repo is NoopRepository
                ? null
                : () async {
                    try {
                      await ref
                          .read(repositoryProvider)
                          .markAllJbcNotificationsRead();
                      ref.invalidate(jbcAppNotificationsProvider);
                    } catch (_) {}
                  },
            child: const Text('Marcar todas'),
          ),
        ],
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro: $e')),
        data: (list) {
          if (repo is NoopRepository) {
            return const Center(
              child: Text('Configure o Supabase para ver notificações.'),
            );
          }
          if (list.isEmpty) {
            return const Center(child: Text('Nada por aqui ainda.'));
          }
          final fmt = DateFormat('dd/MM HH:mm');
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: list.length,
            separatorBuilder: (_, unused) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final n = list[i];
              return _NotificationTile(
                ref: ref,
                n: n,
                subtitleTime: fmt.format(n.createdAt.toLocal()),
                onTap: () async {
                  if (!n.isRead) {
                    try {
                      await ref.read(repositoryProvider).markJbcNotificationRead(n.id);
                      ref.invalidate(jbcAppNotificationsProvider);
                    } catch (_) {}
                  }
                  final isMatch = n.eventType == JbcNotificationTypes.conchinhaMatchDual ||
                      n.eventType == JbcNotificationTypes.conchinhaMatchSupreme ||
                      n.eventType == JbcNotificationTypes.conchinhaMatchSupremeUpgrade;
                  if (isMatch && context.mounted) {
                    final wave = n.entityId ?? (n.payload['conchinha_wave_id'] as String?);
                    if (wave != null && wave.isNotEmpty) {
                      final supreme = n.eventType != JbcNotificationTypes.conchinhaMatchDual;
                      await Navigator.of(context).push<void>(
                        MaterialPageRoute<void>(
                          builder: (_) => ConchinhaMatchResultScreen(
                            waveId: wave,
                            isSupreme: supreme,
                          ),
                        ),
                      );
                    }
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.ref,
    required this.n,
    required this.subtitleTime,
    required this.onTap,
  });

  final WidgetRef ref;
  final JbcAppNotification n;
  final String subtitleTime;
  final Future<void> Function() onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final module = n.moduleEnum;
    final actorName = JbcProfile.displayNameForStorageKey(n.actorKey);
    final profile = ref.watch(userProfileProvider);
    final showConchinhaActions = n.eventType == JbcNotificationTypes.conchinhaRequestCreated &&
        (n.entityId ?? '').isNotEmpty &&
        profile != null &&
        profile.storageKey != n.actorKey;
    return ListTile(
      tileColor: n.isRead ? null : theme.colorScheme.primaryContainer.withValues(alpha: 0.25),
      leading: Icon(
        n.isRead ? Icons.notifications_none_outlined : Icons.notifications_active_outlined,
        color: n.isRead ? theme.colorScheme.outline : theme.colorScheme.primary,
      ),
      title: Text(
        n.title,
        style: theme.textTheme.bodyLarge?.copyWith(
          fontWeight: n.isRead ? FontWeight.normal : FontWeight.w600,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(actorName, style: theme.textTheme.labelMedium),
              if (module != null)
                Chip(
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  label: Text(module.displayLabelPt, style: theme.textTheme.labelSmall),
                ),
              Text(subtitleTime, style: theme.textTheme.labelSmall),
            ],
          ),
          if (n.body != null && n.body!.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(n.body!, style: theme.textTheme.bodySmall),
          ],
          if (showConchinhaActions) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                FilledButton.tonal(
                  onPressed: () async {
                    final id = n.entityId!;
                    try {
                      await ref.read(repositoryProvider).acceptConchinhaRequest(
                            requestId: id,
                            profile: profile,
                          );
                      await onTap();
                      ref.invalidate(jbcAppNotificationsProvider);
                      if (context.mounted) {
                        await Navigator.of(context).push<void>(
                          MaterialPageRoute<void>(
                            builder: (_) => ConchinhaRequestDetailScreen(requestId: id),
                          ),
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
                  child: const Text('Aceitar'),
                ),
                OutlinedButton(
                  onPressed: () async {
                    await onTap();
                  },
                  child: const Text('Recusar'),
                ),
              ],
            ),
          ],
        ],
      ),
      onTap: () => unawaited(onTap()),
    );
  }
}
