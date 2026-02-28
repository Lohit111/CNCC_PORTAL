import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ticket_management_app/core/network/network_client.dart';
import 'package:ticket_management_app/core/utils/error_handler.dart';
import 'package:ticket_management_app/domain/entities/user_entity.dart';

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
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
