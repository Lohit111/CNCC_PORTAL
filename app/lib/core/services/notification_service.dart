import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:cncc_portal/core/network/network_client.dart';
import 'package:cncc_portal/firebase_options.dart';

// Top-level background handler — must be outside the class and annotated so
// the Dart AOT compiler keeps it. Registered in main() before runApp().
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Re-initialise Firebase in the separate background isolate.
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() => _instance;

  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final NetworkClient _networkClient = NetworkClient();

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const _androidChannel = AndroidNotificationChannel(
    'cncc_high_importance',
    'CNCC Notifications',
    description: 'General notifications from the CNCC Portal',
    importance: Importance.high,
  );

  bool _initialized = false;
  bool _tokenRefreshListenerRegistered = false;

  /// Initialise local notifications, request permission, and start listening
  /// for foreground messages. Call once in main() after Firebase.initializeApp.
  Future<void> init() async {
    if (kIsWeb) return;
    if (_initialized) return;

    // Registered here — before runApp is called — so the background isolate
    // can find it via its vm:entry-point annotation.
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    await _initLocalNotifications();

    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      _initialized = true;
      return;
    }

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _handleForegroundMessage(message);
    });

    _initialized = true;
  }

  Future<void> _initLocalNotifications() async {
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_androidChannel);

    const initSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );

    await _localNotifications.initialize(initSettings);
  }

  void _handleForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _androidChannel.id,
          _androidChannel.name,
          channelDescription: _androidChannel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(),
      ),
    );
  }

  /// Fetch the FCM token and sync it with the backend. Call after the user
  /// is authenticated. Safe to call multiple times.
  Future<void> registerToken() async {
    if (kIsWeb) return;
    final token = await _messaging.getToken();
    if (token == null) return;

    await _upsertToken(token);

    if (!_tokenRefreshListenerRegistered) {
      _messaging.onTokenRefresh.listen((newToken) async {
        await _upsertToken(newToken);
      });
      _tokenRefreshListenerRegistered = true;
    }
  }

  Future<void> _upsertToken(String token) async {
    final platform = Platform.isAndroid
        ? 'android'
        : Platform.isIOS
            ? 'ios'
            : 'unknown';
    try {
      await _networkClient.post(
        '/users/fcm_token',
        data: {'fcm_token': token, 'platform': platform},
      );
    } catch (_) {
      // Non-fatal — token will be retried on next login or token refresh.
    }
  }
}
