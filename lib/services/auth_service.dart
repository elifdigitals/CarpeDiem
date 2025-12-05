import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const _keyUserId = "user_id";
  static const _keyToken = "auth_token";

  Future<SharedPreferences> getPrefs() async {
    return await SharedPreferences.getInstance();
  }

  Future<void> saveSession(int userId, String token) async {
    final prefs = await getPrefs();
    prefs.setInt("user_id", userId);
    prefs.setString("access_token", token);
  }

  Future<int?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyUserId);
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyToken);
  }

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyUserId) != null;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
