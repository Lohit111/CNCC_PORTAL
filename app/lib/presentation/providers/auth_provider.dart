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
    _init();
  }

  void _init() {
    _firebaseAuth.authStateChanges().listen((fbUser) {
      if (fbUser == null) {
        state = AuthState(user: null, isLoading: false);
      } else {
        _fetchUserProfile();
      }
    });
  }

  Future<void> _fetchUserProfile() async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final response = await _networkClient.get('/users/me');
      final user = User.fromJson(response.data);

      state = AuthState(user: user, isLoading: false);
      await NotificationService.registerToken();
    } catch (error) {
      final appError = ErrorHandler.handle(error);
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
