import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:jwt_decoder/jwt_decoder.dart';

class TokenStorage {
  static const String _tokenKey = 'auth_token';
  static const String _userIdKey = 'user_id';

  // Save token and user ID
  static Future<void> saveToken(String token, String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_userIdKey, userId);
  }

  // Get token
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  // Get user ID
  static Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userIdKey);
  }

  // Clear token and user ID
  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userIdKey);
  }

  // Check if user is logged in
  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  static Future<bool> isTokenExpired(String token) async {
    try {
      // Decode the JWT token
      final decodedToken = JwtDecoder.decode(token);

      // Get the expiration time from the token
      final expirationTime = decodedToken['exp'] as int?;

      if (expirationTime == null) {
        return true; // If no expiration time, consider it expired
      }

      // Convert expiration time to DateTime
      final expirationDate = DateTime.fromMillisecondsSinceEpoch(
        expirationTime * 1000,
      );

      // Check if token is expired
      return DateTime.now().isAfter(expirationDate);
    } catch (e) {
      print('Error checking token expiration: $e');
      return true; // If there's an error, consider it expired
    }
  }
}
