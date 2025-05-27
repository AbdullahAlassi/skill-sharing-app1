import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../utils/token_storage.dart';
import 'dart:convert';
import '../providers/user_provider.dart';
import '../services/api_client.dart';

class AuthProvider with ChangeNotifier {
  User? _user;
  bool _isLoading = false;
  String? _error;
  final AuthService _authService;
  final SharedPreferences _prefs;
  final ApiClient _apiClient;

  AuthProvider(this._authService, this._prefs, this._apiClient) {
    _initializeUser();
  }

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;

  Future<void> _initializeUser() async {
    setLoading(true);
    try {
      print('\n[AuthProvider] Initializing User');
      final token = await TokenStorage.getToken();
      print('[AuthProvider] Token exists: ${token != null}');

      if (token != null) {
        print('[AuthProvider] Validating token...');
        final response = await _authService.validateToken(token);
        print('[AuthProvider] Token validation response:');
        print('- Success: ${response.success}');
        print('- Status Code: ${response.statusCode}');
        print('- Error: ${response.error}');

        if (response.success && response.data != null) {
          print('[AuthProvider] Token valid, setting user...');
          _user = response.data;
          print('[AuthProvider] User set in _initializeUser: ${_user?.id}');
          notifyListeners();
        } else {
          print('[AuthProvider] Token invalid or expired, clearing data...');
          await TokenStorage.clearToken();
          await _prefs.remove('user');
          _user = null;
          print(
              '[AuthProvider] User set to null in _initializeUser (invalid token)');
          notifyListeners();
        }
      } else {
        print('[AuthProvider] No token found, user not authenticated');
        _user = null;
        await _prefs.remove('user');
        print('[AuthProvider] User set to null in _initializeUser (no token)');
        notifyListeners();
      }
    } catch (e) {
      print('[AuthProvider] Error during initialization: $e');
      await TokenStorage.clearToken();
      await _prefs.remove('user');
      _user = null;
      print('[AuthProvider] User set to null in _initializeUser (error)');
      notifyListeners();
    } finally {
      setLoading(false);
      print(
          '[AuthProvider] Initialization complete. isAuthenticated: ${isAuthenticated}, User ID: ${_user?.id}');
    }
  }

  Future<void> login(
      String email, String password, BuildContext context) async {
    setLoading(true);
    setError(null);
    try {
      print('\n[AuthProvider] Starting Login Process');
      print('[AuthProvider] Email: $email');

      // Clear any existing data before login
      print('[AuthProvider] Clearing existing token and user data...');
      final clearResult = await TokenStorage.clearToken();
      print('[AuthProvider] Token clear result: $clearResult');

      await _prefs.remove('user');
      _user = null;

      final response = await _authService.login(email, password);
      print('[AuthProvider] Login response:');
      print('- Success: ${response.success}');
      print('- Status Code: ${response.statusCode}');

      if (response.success && response.data != null) {
        print('[AuthProvider] Login successful, saving token...');
        final data = response.data!;
        final token = data['token'] as String;
        final userId = data['user']['id'] as String;

        // Save the new token
        final tokenSaved = await TokenStorage.saveToken(token, userId);
        if (!tokenSaved) {
          throw Exception('Failed to save token');
        }

        // Verify token was saved
        final savedToken = await TokenStorage.getToken();
        print('[AuthProvider] Token saved successfully: ${savedToken != null}');
        print('[AuthProvider] Saved token matches: ${savedToken == token}');

        if (savedToken == null || savedToken != token) {
          throw Exception('Token verification failed');
        }

        // Wait a moment to ensure token is properly saved
        await Future.delayed(const Duration(milliseconds: 100));

        // Verify token with debug endpoint
        print('[AuthProvider] Verifying token with debug endpoint...');
        final debugResponse = await _apiClient.debugTokenCheck();
        print('[AuthProvider] Debug token response: $debugResponse');

        print('[AuthProvider] Fetching user data with new token...');
        final userResponse = await _authService.getCurrentUser();

        if (userResponse.success && userResponse.data != null) {
          print('[AuthProvider] User data fetched successfully');
          _user = userResponse.data;

          // Update UserProvider only after token is saved and verified
          if (context.mounted) {
            final userProvider =
                Provider.of<UserProvider>(context, listen: false);
            userProvider.clearUser(); // Clear any existing user data
            userProvider.setUser(_user!); // Set the new user data
          }

          notifyListeners();
        } else {
          setError('Failed to fetch user data after login');
          // Clear token if user data fetch fails
          await TokenStorage.clearToken();
        }
      } else {
        setError(response.error ?? 'Login failed');
      }
    } catch (e) {
      print('[AuthProvider] Login error: $e');
      setError(e.toString());
      // Ensure token is cleared on error
      await TokenStorage.clearToken();
    } finally {
      setLoading(false);
    }
  }

  Future<void> logout(BuildContext context) async {
    setLoading(true);
    try {
      print('\n[AuthProvider] Logging Out');

      // Clear token and user data from storage
      print('[AuthProvider] Clearing token...');
      final clearResult = await TokenStorage.clearToken();
      print('[AuthProvider] Token clear result: $clearResult');

      // Verify token was cleared
      final tokenAfterClear = await TokenStorage.getToken();
      print(
          '[AuthProvider] Token cleared successfully: ${tokenAfterClear == null}');

      if (tokenAfterClear != null) {
        print('[AuthProvider] Warning: Token still exists after clear attempt');
        // Try clearing again
        await TokenStorage.clearToken();
      }

      await _prefs.remove('user');

      // Clear user state
      _user = null;
      _error = null;

      // Clear UserProvider state
      if (context.mounted) {
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        userProvider.clearUser();
      }

      // Notify listeners of the change
      notifyListeners();

      print('[AuthProvider] Logout completed successfully');
    } catch (e) {
      print('[AuthProvider] Logout error: $e');
      setError('Failed to logout: ${e.toString()}');
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
