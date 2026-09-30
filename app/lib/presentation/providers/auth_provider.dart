import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cncc_portal/core/network/network_client.dart';
import 'package:cncc_portal/services/notification_service.dart';
import 'package:cncc_portal/domain/entities/user_entity.dart';
import 'package:dio/dio.dart';

class AuthState {
  final User? user;
  final bool isLoading;
  final String? error;

  AuthState({
    this.user,
    this.isLoading = false,
    this.error,
  });

  AuthState copyWith({
    User? user,
    bool? isLoading,
    String? error,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final NetworkClient _networkClient = NetworkClient();
  final fb.FirebaseAuth _firebaseAuth = fb.FirebaseAuth.instance;

  AuthNotifier() : super(AuthState(isLoading: true)) {
    print('AUTH: AuthNotifier CREATED');
    _init();
  }

  void _init() {
    print('AUTH: _init START');

    _firebaseAuth.authStateChanges().listen((fbUser) {
      print('AUTH: authStateChanges emitted: ${fbUser?.uid}');

      if (fbUser == null) {
        state = AuthState(
          user: null,
          isLoading: false,
        );
      } else {
        _fetchUserProfile();
      }
    });

    print('AUTH: listener attached');
  }

  Future<void> _fetchUserProfile() async {
    try {
      print('AUTH: fetching /users/me');

      final response = await _networkClient.get('/users/me');

      print('AUTH: /users/me = ${response.statusCode}');

      final user = User.fromJson(response.data);

      state = AuthState(
        user: user,
        isLoading: false,
      );

      print('AUTH: profile loaded');

      try {
        await NotificationService.registerToken();
        print('AUTH: notification token registered');
      } catch (e, st) {
        print('AUTH: notification registration FAILED: $e');
        print(st);
      }
    } catch (e, st) {
      print('AUTH: /users/me FAILED: $e');
      print(st);

      final appError = ErrorHandler.handle(e);

      state = AuthState(
        user: null,
        isLoading: false,
        error: appError.message,
      );
    }
  }

  Future<void> refresh() async {
    await _fetchUserProfile();
  }

  Future<void> logout() async {
    await NotificationService.dispose();
    await _firebaseAuth.signOut();
    state = AuthState(user: null, isLoading: false);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});

class AppException implements Exception {
  final String message;
  AppException(this.message);

  @override
  String toString() => message;
}

class ErrorHandler {
  static AppException handle(dynamic error) {
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return AppException('Connection timeout. Please try again.');
        case DioExceptionType.badResponse:
          return _handleResponseError(error.response);
        case DioExceptionType.cancel:
          return AppException('Request cancelled');
        default:
          return AppException('Network error. Please check your connection.');
      }
    }
    return AppException(error.toString());
  }

  static AppException _handleResponseError(Response? response) {
    if (response == null) {
      return AppException('Unknown error occurred');
    }

    final statusCode = response.statusCode;
    final data = response.data;

    String message = 'An error occurred';
    if (data is Map && data.containsKey('detail')) {
      message = data['detail'].toString();
    }

    switch (statusCode) {
      case 400:
        return AppException('Bad request: $message');
      case 401:
        return AppException('Unauthorized: $message');
      case 403:
        return AppException('Access denied: $message');
      case 404:
        return AppException('Not found: $message');
      case 409:
        return AppException('Conflict: $message');
      case 500:
        return AppException('Server error: $message');
      default:
        return AppException(message);
    }
  }
}
