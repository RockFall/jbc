import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/profile/jbc_profile.dart';
import '../../core/providers.dart';

Color _profileAccent(JbcProfile p) {
  switch (p) {
    case JbcProfile.caio:
      return const Color(0xFF1B5E20);
    case JbcProfile.jojo:
      return const Color(0xFF00ACC1);
    case JbcProfile.bibi:
      return const Color(0xFF4A148C);
  }
}

String _profileEmoji(JbcProfile p) {
  switch (p) {
    case JbcProfile.caio:
      return '🦎';
    case JbcProfile.jojo:
      return '🐋';
    case JbcProfile.bibi:
      return '🦇';
  }
}

class ProfilePickerScreen extends ConsumerWidget {
  const ProfilePickerScreen({super.key, this.isChangingProfile = false});

  final bool isChangingProfile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isChangingProfile ? 'Trocar perfil' : 'Quem é você neste aparelho?'),
        automaticallyImplyLeading: isChangingProfile,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                isChangingProfile
                    ? 'Escolha de novo quem usa este celular. Isso define o nome em tudo que você criar.'
                    : 'O JBC é só para vocês três. Escolha o seu nome para sabermos quem criou cada coisa.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 28),
              ...JbcProfile.values.map(
                (p) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Material(
                    color: Theme.of(context).colorScheme.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(color: _profileAccent(p), width: 3),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () async {
                        await ref.read(userProfileProvider.notifier).setProfile(p);
                        if (context.mounted && isChangingProfile) {
                          Navigator.of(context).pop();
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
                        child: Row(
                          children: [
                            Text(
                              _profileEmoji(p),
                              style: const TextStyle(fontSize: 36),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                p.displayName,
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: _profileAccent(p),
                                    ),
                              ),
                            ),
                            Icon(Icons.chevron_right, color: _profileAccent(p)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
