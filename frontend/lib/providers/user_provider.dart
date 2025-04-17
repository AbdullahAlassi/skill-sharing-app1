import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../models/skill_proficiency_model.dart';
import '../services/auth_service.dart';
import '../services/profile_service.dart';
import '../config/app_config.dart';
import '../utils/token_storage.dart';

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
    if (_isLoading) return;

    _isLoading = true;
    _error = null;
    _notifyListeners();

    try {
      // Check if user is logged in
      final isLoggedIn = await TokenStorage.isLoggedIn();
      print('Is logged in: $isLoggedIn');

      if (!isLoggedIn) {
        _user = null;
        _error = 'Not authenticated';
        _isLoading = false;
        _notifyListeners();
        return;
      }

      // Get token and check expiration
      final token = await TokenStorage.getToken();
      print('Token: $token');

      if (token == null) {
        _user = null;
        _error = 'No authentication token found';
        _isLoading = false;
        _notifyListeners();
        return;
      }

      // Check token expiration
      final isExpired = await TokenStorage.isTokenExpired(token);
      print('Is token expired: $isExpired');

      if (isExpired) {
        await TokenStorage.clearToken();
        _user = null;
        _error = 'Session expired. Please login again.';
        _isLoading = false;
        _notifyListeners();
        return;
      }

      final response = await _authService.getCurrentUser();
      print('API Response: ${response.success}');
      print('API Error: ${response.error}');
      print('API Status Code: ${response.statusCode}');
      print('User Data: ${response.data}');

      if (response.success) {
        _user = response.data;
      } else {
        _error = response.error;
        if (response.statusCode == 401) {
          // Token expired or invalid, clear user
          _user = null;
          await TokenStorage.clearToken();
        }
      }
    } catch (e) {
      print('Error loading user: $e');
      _error = e.toString();
      _user = null;
    } finally {
      _isLoading = false;
      _notifyListeners();
    }
  }

  // Update user profile
  Future<bool> updateProfile(String name, String bio) async {
    if (_isLoading) return false;

    _isLoading = true;
    _error = null;
    _notifyListeners();

    try {
      final response = await _profileService.updateProfile(name, bio);

      if (response.success) {
        _user = response.data;
        _notifyListeners();
        return true;
      } else {
        _error = response.error;
        _notifyListeners();
        return false;
      }
    } catch (e) {
      _error = e.toString();
      _notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      _notifyListeners();
    }
  }

  // Update skill proficiency
  Future<bool> updateSkillProficiency(SkillProficiency proficiency) async {
    if (_isLoading) return false;

    _isLoading = true;
    _error = null;
    _notifyListeners();

    try {
      final response =
          await _profileService.updateSkillProficiency(proficiency);

      if (response.success) {
        // Update the user's skill proficiencies
        final updatedProficiencies =
            List<SkillProficiency>.from(_user?.skillProficiencies ?? []);

        final existingIndex = updatedProficiencies.indexWhere(
          (p) => p.skillId == proficiency.skillId,
        );

        if (existingIndex >= 0) {
          updatedProficiencies[existingIndex] = proficiency;
        } else {
          updatedProficiencies.add(proficiency);
        }

        _user = User(
          id: _user!.id,
          name: _user!.name,
          email: _user!.email,
          profilePicture: _user!.profilePicture,
          bio: _user!.bio,
          favoriteCategories: _user!.favoriteCategories,
          friends: _user!.friends,
          groups: _user!.groups,
          createdSkills: _user!.createdSkills,
          skills: _user!.skills,
          skillProficiencies: updatedProficiencies,
          createdAt: _user!.createdAt,
        );

        _notifyListeners();
        return true;
      } else {
        _error = response.error;
        _notifyListeners();
        return false;
      }
    } catch (e) {
      _error = e.toString();
      _notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      _notifyListeners();
    }
  }

  // Add skill to user profile
  Future<bool> addSkill(String skillId, String proficiency) async {
    if (_isLoading) return false;

    _isLoading = true;
    _error = null;
    _notifyListeners();

    try {
      final response = await _profileService.addSkill(skillId, proficiency);

      if (response.success && _user != null) {
        // Reload user to get updated skills
        await loadUser();
        return true;
      } else {
        _error = response.error;
        _notifyListeners();
        return false;
      }
    } catch (e) {
      _error = e.toString();
      _notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      _notifyListeners();
    }
  }

  // Remove skill from user profile
  Future<bool> removeSkill(String skillId) async {
    if (_isLoading) return false;

    _isLoading = true;
    _error = null;
    _notifyListeners();

    try {
      final response = await _profileService.removeSkill(skillId);

      if (response.success && _user != null) {
        // Reload user to get updated skills
        await loadUser();
        return true;
      } else {
        _error = response.error;
        _notifyListeners();
        return false;
      }
    } catch (e) {
      _error = e.toString();
      _notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      _notifyListeners();
    }
  }

  // Logout
  Future<void> logout() async {
    await _authService.logout();
    _user = null;
    _notifyListeners();
  }

  // Helper method to safely notify listeners
  void _notifyListeners() {
    if (!_isLoading) {
      notifyListeners();
    }
  }
}
