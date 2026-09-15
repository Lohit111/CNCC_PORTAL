import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cncc_portal/core/network/network_client.dart';

class NotificationNotifier extends StateNotifier<void> {
  final _client = NetworkClient();

  NotificationNotifier() : super(null);

  Future<bool> sendBroadcast(
    String title,
    String body, {
    Map<String, String>? data,
  }) async {
    try {
      await _client.post(
        '/notifications/broadcast',
        data: {
          'title': title,
          'body': body,
          if (data != null) 'data': data,
        },
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> sendToRole(
    String role,
    String title,
    String body, {
    Map<String, String>? data,
  }) async {
    try {
      await _client.post(
        '/notifications/role',
        data: {
          'role': role,
          'title': title,
          'body': body,
          if (data != null) 'data': data,
        },
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> sendToUser(
    String userId,
    String title,
    String body, {
    Map<String, String>? data,
  }) async {
    try {
      await _client.post(
        '/notifications/$userId',
        data: {
          'title': title,
          'body': body,
          if (data != null) 'data': data,
        },
      );
      return true;
    } catch (_) {
      return false;
    }
  }
}

/// Usage: ref.read(notificationProvider.notifier).sendBroadcast(...)
final notificationProvider =
    StateNotifierProvider<NotificationNotifier, void>((ref) {
  return NotificationNotifier();
});
