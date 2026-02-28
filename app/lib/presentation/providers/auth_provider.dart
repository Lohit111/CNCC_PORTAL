import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/auth/login_with_google.dart';
import '../../domain/usecases/auth/logout_user.dart';
import '../../domain/usecases/auth/get_me.dart';
import '../../core/network/api_service.dart';

// AuthRepository provider
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final firebaseAuth = FirebaseAuth.instance;
  final googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);
  final apiService = ApiService();
  return AuthRepositoryImpl(firebaseAuth, googleSignIn, apiService);
});

// Use case providers
final loginWithGoogleProvider = Provider((ref) {
  final repository = ref.read(authRepositoryProvider);
  return LoginWithGoogle(repository);
});

final logoutUserProvider = Provider((ref) {
  final repository = ref.read(authRepositoryProvider);
  return LogoutUser(repository);
});

final getMeProvider = Provider((ref) {
  final repository = ref.read(authRepositoryProvider);
  return GetMe(repository);
});
