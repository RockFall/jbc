import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/profile/jbc_profile.dart';
import '../../core/providers.dart';
import '../onboarding/profile_picker_screen.dart';
import 'developer_settings_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Ajustes')),
      body: ListView(
        children: [
          ListTile(
            title: const Text('Quem é você'),
            subtitle: Text(profile?.displayName ?? '—'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const ProfilePickerScreen(isChangingProfile: true),
                ),
              );
            },
          ),
          if (profile == JbcProfile.caio)
            ListTile(
              leading: const Icon(Icons.developer_mode_outlined),
              title: const Text('Ajustes de Desenvolvedor'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const DeveloperSettingsScreen(),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
