import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cncc_portal/core/network/network_client.dart';
import 'package:cncc_portal/firebase_options.dart';

import 'package:cncc_portal/presentation/providers/admin_provider.dart';
import 'package:cncc_portal/presentation/providers/my_requests_provider.dart';
import 'package:cncc_portal/presentation/providers/staff_provider.dart';
import 'package:cncc_portal/presentation/providers/store_provider.dart';

final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

// ============================================================
// Public notification service
// ============================================================

class NotificationService {
  static final MobileNotificationService mobile = MobileNotificationService();

  static final WebNotificationService web = WebNotificationService();

  static Future<void> init(
    ProviderContainer container,
  ) {
    if (kIsWeb) {
      return web.init(container);
    }

    return mobile.init(container);
  }

  static Future<void> registerToken() {
    if (kIsWeb) {
      return web.registerToken();
    }

    return mobile.registerToken();
  }
}

// ============================================================
// Mobile
// ============================================================

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(
  RemoteMessage message,
) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
}

class MobileNotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  final NetworkClient _networkClient = NetworkClient();

  ProviderContainer? _container;

  bool _initialized = false;
  bool _tokenRefreshListenerRegistered = false;

  Future<void> init(
    ProviderContainer container,
  ) async {
    if (_initialized) return;

    _container = container;

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

    FirebaseMessaging.onMessage.listen(
      _handleForegroundMessage,
    );

    _initialized = true;
  }

  void _handleForegroundMessage(
    RemoteMessage message,
  ) {
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

    _invalidateProviders(message.data);
  }

  void _invalidateProviders(
    Map<String, dynamic> data,
  ) {
    final container = _container;

    if (container == null) return;

    if (data.containsKey('my_requests')) {
      final category = data['my_requests'];

      if (category != null && category.isNotEmpty) {
        container.invalidate(
          myRequestsProvider(category),
        );
      }
    } else if (data.containsKey('admin')) {
      final category = data['admin'];

      if (category != null && category.isNotEmpty) {
        container.invalidate(
          adminProvider(category),
        );
      }
    } else if (data.containsKey('staff')) {
      final category = data['staff'];

      if (category != null && category.isNotEmpty) {
        container.invalidate(
          staffProvider(category),
        );
      }
    } else if (data.containsKey('store')) {
      final category = data['store'];

      if (category != null && category.isNotEmpty) {
        container.invalidate(
          storeProvider(category),
        );
      }
    }
  }

  Future<void> registerToken() async {
    final token = await _messaging.getToken();

    if (token == null) return;

    await _upsertToken(token);

    if (_tokenRefreshListenerRegistered) {
      return;
    }

    _messaging.onTokenRefresh.listen(
      (newToken) async {
        await _upsertToken(newToken);
      },
    );

    _tokenRefreshListenerRegistered = true;
  }

  Future<void> _upsertToken(
    String token,
  ) async {
    final platform = defaultTargetPlatform == TargetPlatform.android
        ? 'android'
        : defaultTargetPlatform == TargetPlatform.iOS
            ? 'ios'
            : 'unknown';

    try {
      await _networkClient.post(
        '/users/upsert_fcm_token',
        data: {
          'fcm_token': token,
          'platform': platform,
        },
      );
    } catch (_) {
      // Non-fatal.
    }
  }
}

// ============================================================
// Web
// ============================================================

class WebNotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  final NetworkClient _networkClient = NetworkClient();

  ProviderContainer? _container;

  bool _initialized = false;
  bool _tokenRefreshListenerRegistered = false;

  static const String _vapidKey =
      'BDWi7zZw9gBK8IUpGqys3M6X-X0jrU6H4mxLdi7hhlfCmsNWN6Dy3FSZmbqQHLt2-Rpl91yw6whGsnm2hUy0IV0';

  Future<void> init(
    ProviderContainer container,
  ) async {
    if (_initialized) return;

    _container = container;

    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    debugPrint(
      'Web notification permission: '
      '${settings.authorizationStatus}',
    );

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      _initialized = true;
      return;
    }

    // Foreground notifications only.
    FirebaseMessaging.onMessage.listen(
      _handleForegroundMessage,
    );

    _initialized = true;
  }

  void _handleForegroundMessage(
    RemoteMessage message,
  ) {
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

    _invalidateProviders(message.data);
  }

  void _invalidateProviders(
    Map<String, dynamic> data,
  ) {
    final container = _container;

    if (container == null) return;

    if (data.containsKey('my_requests')) {
      final category = data['my_requests'];

      if (category != null && category.isNotEmpty) {
        container.invalidate(
          myRequestsProvider(category),
        );
      }
    } else if (data.containsKey('admin')) {
      final category = data['admin'];

      if (category != null && category.isNotEmpty) {
        container.invalidate(
          adminProvider(category),
        );
      }
    } else if (data.containsKey('staff')) {
      final category = data['staff'];

      if (category != null && category.isNotEmpty) {
        container.invalidate(
          staffProvider(category),
        );
      }
    } else if (data.containsKey('store')) {
      final category = data['store'];

      if (category != null && category.isNotEmpty) {
        container.invalidate(
          storeProvider(category),
        );
      }
    }
  }

  Future<void> registerToken() async {
    try {
      final token = await _messaging.getToken(
        vapidKey: _vapidKey,
      );

      if (token == null) {
        debugPrint('FCM Web token was null');
        return;
      }

      debugPrint('FCM Web token obtained');

      await _upsertToken(token);

      if (_tokenRefreshListenerRegistered) {
        return;
      }

      _messaging.onTokenRefresh.listen(
        (newToken) async {
          await _upsertToken(newToken);
        },
      );

      _tokenRefreshListenerRegistered = true;
    } catch (e) {
      debugPrint(
        'Failed to register Web FCM token: $e',
      );
    }
  }

  Future<void> _upsertToken(
    String token,
  ) async {
    try {
      await _networkClient.post(
        '/users/upsert_fcm_token',
        data: {
          'fcm_token': token,
          'platform': 'web',
        },
      );
    } catch (e) {
      debugPrint(
        'Failed to register Web FCM token: $e',
      );
    }
  }
}
