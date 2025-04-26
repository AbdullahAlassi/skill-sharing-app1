import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../utils/token_storage.dart';
import 'dart:convert';

class AuthProvider with ChangeNotifier {
  User? _user;
  bool _isLoading = false;
  String? _error;
  final AuthService _authService = AuthService(baseUrl: 'http://10.0.2.2:5000');
  final SharedPreferences _prefs;

  AuthProvider(this._prefs) {
    _initializeUser();
  }

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;

  Future<void> _initializeUser() async {
    setLoading(true);
    try {
      final token = await TokenStorage.getToken();
      print('=== Checking Token ===');
      print('Token exists: ${token != null}');

      if (token != null) {
        print('Validating token...');
        final response = await _authService.validateToken(token);
        print('Token validation response:');
        print('- Success: ${response.success}');
        print('- Status Code: ${response.statusCode}');
        print('- Error: ${response.error}');

        if (response.success && response.data != null) {
          print('Token valid, setting user...');
          _user = response.data;
          notifyListeners();
        } else if (response.statusCode == 503) {
          // Server is unavailable, keep the user logged in but show a warning
          print('Server is temporarily unavailable, keeping user logged in');
          _user = await _getStoredUser();
          notifyListeners();
        } else {
          print('Token invalid or expired, logging out...');
          await TokenStorage.clearToken();
          _user = null;
          notifyListeners();
        }
      } else {
        print('No token found, user not authenticated');
        _user = null;
        notifyListeners();
      }
    } catch (e) {
      print('Error during initialization: $e');
      // On error, try to get stored user data
      _user = await _getStoredUser();
      notifyListeners();
    } finally {
      setLoading(false);
    }
  }

  Future<User?> _getStoredUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString('user');
      if (userJson != null) {
        final userMap = json.decode(userJson);
        return User.fromJson(userMap);
      }
    } catch (e) {
      print('Error getting stored user: $e');
    }
    return null;
  }

  Future<void> login(String email, String password) async {
    setLoading(true);
    setError(null);
    try {
      print('=== Starting Login Process ===');
      final response = await _authService.login(email, password);
      print('Login response:');
      print('- Success: ${response.success}');
      print('- Status Code: ${response.statusCode}');

      if (response.success && response.data != null) {
        print('Login successful, saving token and user data...');
        final token = response.data!['token'];
        await _prefs.setString('token', token);
        _user = User.fromJson(response.data!['user']);
        // Store user data
        await _prefs.setString('user', json.encode(response.data!['user']));
        notifyListeners();
      } else {
        setError(response.error ?? 'Login failed');
      }
    } catch (e) {
      print('Login error: $e');
      setError(e.toString());
    } finally {
      setLoading(false);
    }
  }

  Future<void> logout() async {
    setLoading(true);
    try {
      print('=== Logging Out ===');
      await _prefs.remove('token');
      _user = null;
      notifyListeners();
    } catch (e) {
      print('Logout error: $e');
    } finally {
      setLoading(false);
    }
  }

  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void setError(String? value) {
    _error = value;
    notifyListeners();
  }
}
