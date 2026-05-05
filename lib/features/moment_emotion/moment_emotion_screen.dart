import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/moment_emotion/moment_sticker_catalog.dart';
import '../../core/profile/jbc_profile.dart';
import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/moment_emotion.dart';
import '../../data/repositories/noop_repository.dart';
import 'moment_sticker_picker_sheet.dart';

/// Três cartões: emoção atual por perfil + grade ao tocar no seu (Epic 14).
class MomentEmotionScreen extends ConsumerWidget {
  const MomentEmotionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(momentEmotionsProvider);
    final cache = ref.read(momentEmotionCacheProvider).readSnapshot();

    ref.listen(momentEmotionsProvider, (previous, next) {
      next.whenData((list) {
        unawaited(ref.read(momentEmotionCacheProvider).saveSnapshot(list));
      });
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Emoção do momento'),
        backgroundColor: AppTheme.brandRed,
        foregroundColor: Colors.white,
      ),
      body: ref.watch(repositoryProvider) is NoopRepository
          ? const Center(child: Text('Configure o Supabase para ver o trio.'))
          : async.when(
              loading: () {
                if (cache != null && cache.length == 3) {
                  return Stack(
                    alignment: Alignment.topCenter,
                    children: [
                      _EmotionGrid(slots: cache, interactiveProfile: ref.watch(userProfileProvider)),
                      const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: LinearProgressIndicator(minHeight: 2),
                      ),
                    ],
                  );
                }
                return const Center(child: CircularProgressIndicator());
              },
              error: (e, _) => Center(child: Text('Erro: $e')),
              data: (slots) => _EmotionGrid(
                slots: slots,
                interactiveProfile: ref.watch(userProfileProvider),
              ),
            ),
    );
  }
}

class _EmotionGrid extends ConsumerWidget {
  const _EmotionGrid({
    required this.slots,
    required this.interactiveProfile,
  });

  final List<MomentEmotion?> slots;
  final JbcProfile? interactiveProfile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final fmt = DateFormat("dd/MM 'às' HH:mm");

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      children: [
        Text(
          'Como cada um do trio está agora — atualiza em tempo real.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 20),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < JbcProfile.values.length; i++) ...[
              if (i > 0) const SizedBox(width: 10),
              Expanded(
                child: _ProfileEmotionCard(
                  profile: JbcProfile.values[i],
                  emotion: i < slots.length ? slots[i] : null,
                  isMe: interactiveProfile == JbcProfile.values[i],
                  timeFmt: fmt,
                  onTapMine: interactiveProfile == JbcProfile.values[i]
                      ? () async {
                          final id = await showMomentStickerPicker(context);
                          if (id == null || !context.mounted) return;
                          if (ref.read(repositoryProvider) is NoopRepository) return;
                          try {
                            await ref.read(repositoryProvider).setMomentSticker(
                                  profile: interactiveProfile!,
                                  stickerId: id,
                                );
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('$e')),
                              );
                            }
                          }
                        }
                      : null,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _ProfileEmotionCard extends StatelessWidget {
  const _ProfileEmotionCard({
    required this.profile,
    required this.emotion,
    required this.isMe,
    required this.timeFmt,
    this.onTapMine,
  });

  final JbcProfile profile;
  final MomentEmotion? emotion;
  final bool isMe;
  final DateFormat timeFmt;
  final VoidCallback? onTapMine;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final sticker = emotion != null ? MomentStickerCatalog.tryById(emotion!.stickerId) : null;
    final emoji = sticker?.emoji ?? '·';
    final subtitle = emotion != null
        ? (sticker != null ? sticker.labelPt : 'Sticker')
        : 'Ainda não escolheu';

    return Material(
      color: const Color(0xFFFFF9F4),
      elevation: 2,
      shadowColor: Colors.black12,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTapMine,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 16, 10, 14),
          child: Column(
            children: [
              Text(
                profile.displayName,
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              Semantics(
                label: emotion != null && sticker != null
                    ? '${profile.displayName}: ${sticker.labelPt}'
                    : '${profile.displayName}: ainda sem sticker',
                child: Text(
                  emoji,
                  style: TextStyle(
                    fontSize: emotion != null && sticker != null ? 44 : 28,
                    height: 1,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelMedium?.copyWith(color: scheme.onSurfaceVariant),
              ),
              if (emotion != null) ...[
                const SizedBox(height: 6),
                Text(
                  timeFmt.format(emotion!.updatedAt.toLocal()),
                  style: theme.textTheme.labelSmall?.copyWith(color: scheme.outline),
                ),
              ],
              if (isMe) ...[
                const SizedBox(height: 10),
                Text(
                  'Toque para mudar',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: scheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
