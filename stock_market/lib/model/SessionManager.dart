import 'package:shared_preferences/shared_preferences.dart';

class SessionManager {
  static const _keyLoggedIn = 'isLoggedIn';
  static const _keyUserId = 'userId';
  static const _keyUsername = 'username';
  static const _keyEmail = 'email';
  static Future<void> saveSession({
    required String username,
    required String userId,
    required String email,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool(_keyLoggedIn, true);
    await prefs.setString(_keyUserId, userId);
    await prefs.setString(_keyUsername, username);
    await prefs.setString(_keyEmail, email);
  }

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyLoggedIn) ?? false;
  }

  static Future<String?> getUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUsername);
  }

  static Future<String?> getEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyEmail);
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
