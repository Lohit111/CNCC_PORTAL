abstract class AuthRepository {
  Future<void> login();
  Future<void> logout();
  Future<String?> getIdToken();
  Future<Map<String, dynamic>> getMe();
}
