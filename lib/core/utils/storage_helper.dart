import 'package:shared_preferences/shared_preferences.dart';

class StorageHelper {
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString("token", token);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("token");
  }

  static Future<void> saveUserId(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setInt("userId", userId);
  }

  static Future<int?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt("userId");
  }

  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.remove("token");
  }

  static Future<void> clearUserId() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.remove("userId");
  }

  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.remove("token");
    prefs.remove("userId");
  }
}
