import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  bool _isAuthenticated = false;

  bool get isAuthenticated => _isAuthenticated;

  Future<bool> signup(String name, String email, String password) async {
    bool success = await AuthService.signup(name, email, password);
    return success;
  }

  Future<bool> login(String email, String password) async {
    bool success = await AuthService.login(email, password);
    if (success) {
      _isAuthenticated = true;
      notifyListeners();
    }
    return success;
  }

  Future<void> logout() async {
    await AuthService.logout();
    _isAuthenticated = false;
    notifyListeners();
  }

  Future<void> checkLoginStatus() async {
    _isAuthenticated = await AuthService.isLoggedIn();
    notifyListeners();
  }
}
