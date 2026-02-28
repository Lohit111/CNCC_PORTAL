import 'package:shared_preferences/shared_preferences.dart';

class TokenManager {
  static const String _tokenKey = 'firebase_token';

  /// Save Firebase ID token
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  /// Get stored token
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  /// Clear token
  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  /// Check if token exists
  static Future<bool> hasToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_tokenKey);
  }
}
