import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cncc_portal/core/network/network_client.dart';
import 'package:cncc_portal/firebase_options.dart';

/// Global key used to display SnackBars from the notification service.
final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

/// Top-level background handler.
///
/// Must be outside the class and annotated so the Dart AOT compiler keeps it.
/// Registered before runApp().
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(
  RemoteMessage message,
) async {
  // Re-initialise Firebase in the separate background isolate.
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
}

class NotificationService {
  static final NotificationService _instance =
      NotificationService._internal();

  factory NotificationService() => _instance;

  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final NetworkClient _networkClient = NetworkClient();

  bool _initialized = false;
  bool _tokenRefreshListenerRegistered = false;

  /// Initialise Firebase Messaging.
  ///
  /// - Registers the background handler.
  /// - Requests notification permission.
  /// - Listens for foreground messages.
  ///
  /// Call once in main() after Firebase.initializeApp().
  Future<void> init() async {
    if (kIsWeb) return;
    if (_initialized) return;

    // Register the background handler.
    FirebaseMessaging.onBackgroundMessage(
      firebaseMessagingBackgroundHandler,
    );

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

    // Foreground messages are handled manually using a SnackBar.
    FirebaseMessaging.onMessage.listen(
      _handleForegroundMessage,
    );

    _initialized = true;
  }

  /// Handles notifications received while the app is in the foreground.
  ///
  /// Instead of showing a system notification, a SnackBar is displayed
  /// inside the application.
  void _handleForegroundMessage(RemoteMessage message) {
    final notification = message.notification;

    if (notification == null) return;

    final title = notification.title ?? 'Notification';
    final body = notification.body ?? '';

    scaffoldMessengerKey.currentState?.hideCurrentSnackBar();

    scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            if (body.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(body),
            ],
          ],
        ),
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
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
        '/users/upsert_fcm_token',
        data: {'fcm_token': token, 'platform': platform},
      );
    } catch (_) {
      // Non-fatal — token will be retried on next login or token refresh.
    }
  }
}