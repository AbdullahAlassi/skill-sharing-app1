import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/profile_service.dart';
import '../config/app_config.dart';

class UserProvider with ChangeNotifier {
  User? _user;
  bool _isLoading = false;
  String? _error;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _user != null;

  final AuthService _authService = AuthService(baseUrl: AppConfig.apiBaseUrl);
  final ProfileService _profileService = ProfileService();

  // Load user data
  Future<void> loadUser() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _authService.getCurrentUser();

      if (response.success) {
        _user = response.data;
      } else {
        _error = response.error;
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update user profile
  Future<bool> updateProfile(String name, String bio) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _profileService.updateProfile(name, bio);

      if (response.success) {
        _user = response.data;
        notifyListeners();
        return true;
      } else {
        _error = response.error;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Add skill to user profile
  Future<bool> addSkill(String skillId, String proficiency) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _profileService.addSkill(skillId, proficiency);

      if (response.success && _user != null) {
        // Reload user to get updated skills
        await loadUser();
        return true;
      } else {
        _error = response.error;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Remove skill from user profile
  Future<bool> removeSkill(String skillId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _profileService.removeSkill(skillId);

      if (response.success && _user != null) {
        // Reload user to get updated skills
        await loadUser();
        return true;
      } else {
        _error = response.error;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Logout
  Future<void> logout() async {
    await _authService.logout();
    _user = null;
    notifyListeners();
  }
}
