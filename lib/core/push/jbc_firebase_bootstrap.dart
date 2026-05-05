import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../../data/repositories/jbc_repository.dart';
import '../profile/jbc_profile.dart';

/// Inicialização opcional via `--dart-define` (mesmos valores do Firebase Console / `google-services.json`).
abstract final class JbcFirebaseBootstrap {
  static const _projectId = String.fromEnvironment('FIREBASE_PROJECT_ID', defaultValue: '');
  static const _senderId =
      String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID', defaultValue: '');

  static bool get isAndroidConfigured =>
      _projectId.isNotEmpty &&
      _senderId.isNotEmpty &&
      const String.fromEnvironment('FIREBASE_ANDROID_API_KEY', defaultValue: '').isNotEmpty &&
      const String.fromEnvironment('FIREBASE_ANDROID_APP_ID', defaultValue: '').isNotEmpty;

  static bool get isIosConfigured =>
      _projectId.isNotEmpty &&
      _senderId.isNotEmpty &&
      const String.fromEnvironment('FIREBASE_IOS_API_KEY', defaultValue: '').isNotEmpty &&
      const String.fromEnvironment('FIREBASE_IOS_APP_ID', defaultValue: '').isNotEmpty;

  static Future<void> tryInitialize() async {
    if (kIsWeb) return;
    if (Firebase.apps.isNotEmpty) return;

    if (defaultTargetPlatform == TargetPlatform.android && isAndroidConfigured) {
      await Firebase.initializeApp(
        options: FirebaseOptions(
          apiKey: const String.fromEnvironment('FIREBASE_ANDROID_API_KEY'),
          appId: const String.fromEnvironment('FIREBASE_ANDROID_APP_ID'),
          messagingSenderId: _senderId,
          projectId: _projectId,
          storageBucket: const String.fromEnvironment(
            'FIREBASE_STORAGE_BUCKET',
            defaultValue: '',
          ),
        ),
      );
      return;
    }

    if (defaultTargetPlatform == TargetPlatform.iOS && isIosConfigured) {
      await Firebase.initializeApp(
        options: FirebaseOptions(
          apiKey: const String.fromEnvironment('FIREBASE_IOS_API_KEY'),
          appId: const String.fromEnvironment('FIREBASE_IOS_APP_ID'),
          messagingSenderId: _senderId,
          projectId: _projectId,
          storageBucket: const String.fromEnvironment(
            'FIREBASE_STORAGE_BUCKET',
            defaultValue: '',
          ),
          iosBundleId: const String.fromEnvironment(
            'FIREBASE_IOS_BUNDLE_ID',
            defaultValue: 'com.jbc.app',
          ),
        ),
      );
    }
  }

  /// Regista o token FCM no Supabase para o perfil atual (ignora se Firebase não estiver configurado).
  static Future<void> registerMessagingTokenIfPossible({
    required JbcRepository repository,
    required JbcProfile? profile,
  }) async {
    if (kIsWeb || profile == null) return;
    await tryInitialize();
    if (Firebase.apps.isEmpty) return;

    final messaging = FirebaseMessaging.instance;
    await messaging.setAutoInitEnabled(true);
    final settings = await messaging.requestPermission();
    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      return;
    }

    Future<void> save(String? token) async {
      if (token == null || token.isEmpty) return;
      try {
        await repository.upsertFcmDeviceToken(profile: profile, token: token);
      } catch (_) {
        // Tabela ausente ou rede: não bloqueia o app.
      }
    }

    await save(await messaging.getToken());
    FirebaseMessaging.instance.onTokenRefresh.listen(save);
  }
}
