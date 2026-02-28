import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:google_sign_in/google_sign_in.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../core/network/api_service.dart';
import '../../core/auth/token_manager.dart';

class AuthRepositoryImpl implements AuthRepository {
  final fb.FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;
  final ApiService _apiService;

  AuthRepositoryImpl(
    this._firebaseAuth,
    this._googleSignIn,
    this._apiService,
  );

  @override
  Future<void> login() async {
    try {
      // Trigger the Google Sign-In flow
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw Exception("Google sign-in was cancelled");
      }

      // Obtain the auth details from the request
      final googleAuth = await googleUser.authentication;

      // Create a new credential
      final credential = fb.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      final userCredential = await _firebaseAuth.signInWithCredential(
        credential,
      );

      final fbUser = userCredential.user;
      if (fbUser == null) {
        throw Exception("Authentication failed");
      }

      // Save the Firebase ID token
      final idToken = await fbUser.getIdToken();
      if (idToken != null) {
        await TokenManager.saveToken(idToken);
      }
    } catch (error) {
      rethrow;
    }
  }

  @override
  Future<void> logout() async {
    try {
      await _firebaseAuth.signOut();
      await _googleSignIn.signOut();
      await TokenManager.clearToken();
    } catch (error) {
      rethrow;
    }
  }

  @override
  Future<String?> getIdToken() async {
    try {
      final fbUser = _firebaseAuth.currentUser;
      return fbUser?.getIdToken();
    } catch (error) {
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>> getMe() async {
    try {
      return await _apiService.getCurrentUser();
    } catch (error) {
      rethrow;
    }
  }
}
