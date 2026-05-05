import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/providers.dart';
import 'core/push/jbc_firebase_bootstrap.dart';
import 'core/theme/app_theme.dart';
import 'features/conchinha/conchinha_match_result_screen.dart';
import 'features/conchinha/conchinha_request_detail_screen.dart';
import 'features/onboarding/profile_picker_screen.dart';
import 'features/shell/shell_screen.dart';

final GlobalKey<NavigatorState> jbcRootNavigatorKey = GlobalKey<NavigatorState>();

class JbcApp extends ConsumerStatefulWidget {
  const JbcApp({super.key});

  @override
  ConsumerState<JbcApp> createState() => _JbcAppState();
}

class _JbcAppState extends ConsumerState<JbcApp> {
  StreamSubscription<RemoteMessage>? _openedSub;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      _openedSub = FirebaseMessaging.onMessageOpenedApp.listen(_handlePushData);
      WidgetsBinding.instance.addPostFrameCallback((_) => _openFromColdStartIfAny());
    }
  }

  Future<void> _openFromColdStartIfAny() async {
    if (kIsWeb) return;
    await JbcFirebaseBootstrap.tryInitialize();
    if (Firebase.apps.isEmpty) return;
    final msg = await FirebaseMessaging.instance.getInitialMessage();
    if (msg != null) _handlePushData(msg);
  }

  void _handlePushData(RemoteMessage msg) {
    final data = msg.data;
    final waveId = data['conchinha_wave_id'];
    if (waveId != null && waveId.isNotEmpty) {
      final nav = jbcRootNavigatorKey.currentState;
      if (nav == null) return;
      final tier = data['event_type'] ?? '';
      final isSupreme = tier.contains('supreme');
      nav.push<void>(
        MaterialPageRoute<void>(
          builder: (_) => ConchinhaMatchResultScreen(
            waveId: waveId,
            isSupreme: isSupreme,
          ),
        ),
      );
      return;
    }
    final id = data['conchinha_request_id'];
    if (id == null || id.isEmpty) return;
    final nav = jbcRootNavigatorKey.currentState;
    if (nav == null) return;
    nav.push<void>(
      MaterialPageRoute<void>(
        builder: (_) => ConchinhaRequestDetailScreen(requestId: id),
      ),
    );
  }

  @override
  void dispose() {
    _openedSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(userProfileProvider);
    return MaterialApp(
      navigatorKey: jbcRootNavigatorKey,
      title: 'JBC',
      theme: AppTheme.light(),
      home: profile == null ? const ProfilePickerScreen() : const ShellScreen(),
    );
  }
}
