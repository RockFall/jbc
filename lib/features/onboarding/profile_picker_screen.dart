import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/profile/jbc_profile.dart';
import '../../core/providers.dart';

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
              const SizedBox(height: 24),
              ...JbcProfile.values.map(
                (p) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: FilledButton.tonal(
                    onPressed: () async {
                      await ref.read(userProfileProvider.notifier).setProfile(p);
                      if (context.mounted) {
                        if (isChangingProfile) {
                          Navigator.of(context).pop();
                        }
                      }
                    },
                    child: Text(p.displayName),
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
