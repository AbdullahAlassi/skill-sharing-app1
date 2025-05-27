import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:jwt_decoder/jwt_decoder.dart';

class TokenStorage {
  static const String _tokenKey = 'auth_token';
  static const String _userIdKey = 'user_id';
  static String? _cachedToken; // For debugging only

  // Save token and user ID
  static Future<bool> saveToken(String token, String userId) async {
    try {
      print('\n=== Saving Token ===');
      print('Token to save: $token');
      print('User ID to save: $userId');

      final prefs = await SharedPreferences.getInstance();
      final tokenSaved = await prefs.setString(_tokenKey, token);
      final userIdSaved = await prefs.setString(_userIdKey, userId);

      // Verify save was successful
      final savedToken = prefs.getString(_tokenKey);
      final savedUserId = prefs.getString(_userIdKey);

      print('Token save result: $tokenSaved');
      print('User ID save result: $userIdSaved');
      print('Verified saved token: $savedToken');
      print('Verified saved user ID: $savedUserId');

      // Update cache for debugging
      _cachedToken = token;

      return tokenSaved && userIdSaved;
    } catch (e) {
      print('Error saving token: $e');
      return false;
    }
  }

  // Get token
  static Future<String?> getToken() async {
    try {
      print('\n=== Fetching Token from Storage ===');
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_tokenKey);

      print('Raw token from storage: $token');
      print('Cached token: $_cachedToken');

      if (token != null) {
        // Verify token is valid
        try {
          final decoded = JwtDecoder.decode(token);
          print('Token decoded successfully');
          print('Token payload: $decoded');
          return token;
        } catch (e) {
          print('Error decoding token: $e');
          await clearToken(); // Clear invalid token
          return null;
        }
      }

      return null;
    } catch (e) {
      print('Error getting token: $e');
      return null;
    }
  }

  // Get user ID
  static Future<String?> getUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_userIdKey);
    } catch (e) {
      print('Error getting user ID: $e');
      return null;
    }
  }

  // Clear token and user ID
  static Future<bool> clearToken() async {
    try {
      print('\n=== Clearing Token ===');
      final prefs = await SharedPreferences.getInstance();

      // Get current values for debugging
      final currentToken = prefs.getString(_tokenKey);
      final currentUserId = prefs.getString(_userIdKey);

      print('Current token before clear: $currentToken');
      print('Current user ID before clear: $currentUserId');

      // Clear values
      final tokenCleared = await prefs.remove(_tokenKey);
      final userIdCleared = await prefs.remove(_userIdKey);

      // Verify clear was successful
      final tokenAfterClear = prefs.getString(_tokenKey);
      final userIdAfterClear = prefs.getString(_userIdKey);

      print('Token clear result: $tokenCleared');
      print('User ID clear result: $userIdCleared');
      print('Token after clear: $tokenAfterClear');
      print('User ID after clear: $userIdAfterClear');

      // Clear cache
      _cachedToken = null;

      return tokenCleared && userIdCleared;
    } catch (e) {
      print('Error clearing token: $e');
      return false;
    }
  }

  // Check if user is logged in
  static Future<bool> isLoggedIn() async {
    try {
      final token = await getToken();
      if (token == null) return false;

      // Check if token is expired
      return !await isTokenExpired(token);
    } catch (e) {
      print('Error checking login status: $e');
      return false;
    }
  }

  // Check if token is expired
  static Future<bool> isTokenExpired(String token) async {
    try {
      final decodedToken = JwtDecoder.decode(token);
      final expirationTime = decodedToken['exp'] as int?;

      if (expirationTime == null) {
        print('Token has no expiration time');
        return true;
      }

      final expirationDate = DateTime.fromMillisecondsSinceEpoch(
        expirationTime * 1000,
      );

      final isExpired = DateTime.now().isAfter(expirationDate);
      print('Token expiration check:');
      print('- Expiration date: $expirationDate');
      print('- Current date: ${DateTime.now()}');
      print('- Is expired: $isExpired');

      return isExpired;
    } catch (e) {
      print('Error checking token expiration: $e');
      return true;
    }
  }
}
