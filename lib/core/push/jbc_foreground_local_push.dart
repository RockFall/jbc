import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Mostra na barra do sistema as mensagens FCM com payload `notification` enquanto a app está em primeiro plano.
abstract final class JbcForegroundLocalPush {
  static final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  static const _channelId = 'jbc_fcm_foreground';
  static const _channelName = 'JBC';
  static const _channelDescription = 'Avisos quando a app está aberta.';
  static int _nextId = 0;
  static bool _ready = false;
  // Mantém o listener ativo durante toda a vida da app.
  // ignore: unused_field
  static StreamSubscription<RemoteMessage>? _foregroundSub;

  static Future<void> ensureReady() async {
    if (kIsWeb || _ready) return;
    if (Firebase.apps.isEmpty) return;

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    await _plugin.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
    );

    const channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDescription,
      importance: Importance.high,
    );
    final androidImpl =
        _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await androidImpl?.createNotificationChannel(channel);
    if (defaultTargetPlatform == TargetPlatform.android) {
      await androidImpl?.requestNotificationsPermission();
    }

    _foregroundSub = FirebaseMessaging.onMessage.listen(_onRemoteMessage);
    _ready = true;
  }

  static Future<void> _onRemoteMessage(RemoteMessage msg) async {
    final n = msg.notification;
    final title = (n?.title ?? '').trim();
    final body = (n?.body ?? '').trim();
    if (title.isEmpty && body.isEmpty) return;

    await _plugin.show(
      _nextId = (_nextId + 1) % 0x3fffffff,
      title.isEmpty ? 'JBC' : title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }
}
