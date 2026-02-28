import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth_provider.dart';

// User data model
class UserData {
  final String userId;
  final String email;
  final String role;
  final bool isFirstLogin;

  UserData({
    required this.userId,
    required this.email,
    required this.role,
    required this.isFirstLogin,
  });

  factory UserData.fromJson(Map<String, dynamic> json) {
    return UserData(
      userId: json['user_id'] as String,
      email: json['email'] as String,
      role: json['role'] as String,
      isFirstLogin: json['is_first_login'] as bool? ?? false,
    );
  }
}

// Auth state notifier
class AuthUserNotifier extends StateNotifier<AsyncValue<UserData?>> {
  final Ref ref;

  AuthUserNotifier(this.ref) : super(const AsyncValue.loading()) {
    _init();
  }

  void _init() {
    // Listen to Firebase auth state changes
    FirebaseAuth.instance.authStateChanges().listen((User? firebaseUser) {
      if (firebaseUser == null) {
        state = const AsyncValue.data(null);
      } else {
        loadUser();
      }
    });
  }

  Future<void> loadUser() async {
    try {
      state = const AsyncValue.loading();
      final getMe = ref.read(getMeProvider);
      final userData = await getMe();
      state = AsyncValue.data(UserData.fromJson(userData));
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> login() async {
    try {
      state = const AsyncValue.loading();
      final loginWithGoogle = ref.read(loginWithGoogleProvider);
      await loginWithGoogle();
      await loadUser();
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> logout() async {
    try {
      final logoutUser = ref.read(logoutUserProvider);
      await logoutUser();
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> refresh() async {
    await loadUser();
  }
}

final authenticatedUserProvider =
    StateNotifierProvider<AuthUserNotifier, AsyncValue<UserData?>>(
  (ref) => AuthUserNotifier(ref),
);
