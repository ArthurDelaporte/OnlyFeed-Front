import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class TokenManager {
  static const _key = 'access_token';

  static Future<void> save(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, token);
  }

  static Future<String?> get() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_key);
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }

  static Future<bool> isValid() async {
    final token = await get();
    if (token == null || token.isEmpty) return false;

    final parts = token.split('.');
    if (parts.length != 3) return false;

    try {
      final payload = base64.normalize(parts[1]);
      final decoded = utf8.decode(base64.decode(payload));
      final payloadMap = json.decode(decoded);

      final exp = payloadMap['exp'];
      final expiryDate = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
      return expiryDate.isAfter(DateTime.now());
    } catch (_) {
      return false;
    }
  }
}
