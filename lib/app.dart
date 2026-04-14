import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/providers.dart';
import 'core/theme/app_theme.dart';
import 'features/onboarding/profile_picker_screen.dart';
import 'features/shell/shell_screen.dart';

class JbcApp extends ConsumerWidget {
  const JbcApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider);
    return MaterialApp(
      title: 'JBC',
      theme: AppTheme.light(),
      home: profile == null ? const ProfilePickerScreen() : const ShellScreen(),
    );
  }
}
