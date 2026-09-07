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

final GlobalKey<NavigatorState> navigatorKey =
    GlobalKey<NavigatorState>();

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

  static Future<void> dispose() async {
    try {
      await FirebaseMessaging.instance.deleteToken();
    } catch (_) {
      // Non-fatal.
    }
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

    FunctionalHelpers.showNotification(
      title: title,
      body: body,
    );

    FunctionalHelpers.invalidateProviders(_container, message.data);
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

    FunctionalHelpers.showNotification(
      title: title,
      body: body,
    );

    FunctionalHelpers.invalidateProviders(_container, message.data);
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

class FunctionalHelpers {
  static OverlayEntry? _notificationEntry;

  static void showNotification({
    required String title,
    required String body,
  }) {
    final overlay = navigatorKey.currentState?.overlay;
    if (overlay == null) return;

    _notificationEntry?.remove();

    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (context) {
        return Positioned(
          top: MediaQuery.of(context).padding.top + 12,
          left: 16,
          right: 16,
          child: SafeArea(
            bottom: false,
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 500,
                ),
                child: Material(
                  elevation: 8,
                  borderRadius: BorderRadius.circular(16),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () {
                      entry.remove();
                      _notificationEntry = null;
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.notifications_rounded,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'New Notification',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  title,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                if (body.isNotEmpty) ...[
                                  const SizedBox(height: 3),
                                  Text(
                                    body,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              entry.remove();
                              _notificationEntry = null;
                            },
                            icon: const Icon(Icons.close_rounded),
                            visualDensity: VisualDensity.compact,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );

    _notificationEntry = entry;
    overlay.insert(entry);

    Future.delayed(const Duration(seconds: 5), () {
      if (entry.mounted) {
        entry.remove();
        if (_notificationEntry == entry) {
          _notificationEntry = null;
        }
      }
    });
  }

  static void invalidateProviders(
    ProviderContainer? container,
    Map<String, dynamic> data,
  ) {
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
}
