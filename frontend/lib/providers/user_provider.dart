import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../models/skill_proficiency_model.dart';
import '../services/profile_service.dart';
import '../config/app_config.dart';
import '../utils/token_storage.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import '../utils/api_response.dart';
import '../services/api_client.dart';
import 'package:provider/provider.dart';
import '../providers/progress_provider.dart';
import 'package:collection/collection.dart';
import '../utils/navigation_service.dart';

class UserProvider with ChangeNotifier {
  User? _user;
  final ProfileService _profileService;
  bool _isLoading = false;
  String? _error;
  final ApiClient _apiClient;

  UserProvider(this._profileService, this._apiClient);

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _user != null;

  // Set user directly (used after token verification)
  void setUser(User user) {
    print('\n[UserProvider] Setting user directly');
    print('[UserProvider] User ID: ${user.id}');
    print('[UserProvider] User email: ${user.email}');
    _user = user;
    _error = null;
    notifyListeners();
  }

  // Clear user data
  void clearUser() {
    print('\n[UserProvider] Clearing user data');
    _user = null;
    _error = null;
    notifyListeners();
  }

  // Load user data
  Future<void> loadUser() async {
    if (_isLoading) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print('\n=== Loading User Data ===');
      final response = await _profileService.getCurrentUser();
      print('[DEBUG] User data response:');
      print('- Success: ${response.success}');
      print('- Status Code: ${response.statusCode}');
      print('- Error: ${response.error}');
      print('- Raw data: ${response.data?.toJson()}');

      if (response.success && response.data != null) {
        print('[DEBUG] Setting user data in provider');
        print('[DEBUG] Skills before setting: ${response.data?.skills}');
        print('[DEBUG] Skills type: ${response.data?.skills.runtimeType}');

        _user = response.data;
        _error = null;

        print('[DEBUG] User data set successfully:');
        print('- User ID: ${_user?.id}');
        print('- User Name: ${_user?.name}');
        print('- Skills count: ${_user?.skills.length}');
        print('- Skills: ${_user?.skills}');

        notifyListeners();
      } else if (response.statusCode == 401) {
        print('[DEBUG] Token is invalid or expired');
        _error = 'Session expired. Please login again.';
        _user = null;
        notifyListeners();
      } else {
        print('[DEBUG] Failed to load user data: ${response.error}');
        _error = response.error ?? 'Failed to load user data';
        _user = null;
        notifyListeners();
      }
    } catch (e) {
      print('[DEBUG] Error loading user data: $e');
      _error = e.toString();
      _user = null;
      notifyListeners();
    } finally {
      _isLoading = false;
      print('=== User Data Loading Complete ===\n');
    }
  }

  // Update user profile
  Future<void> updateProfile(
      {required String name, required String bio}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response =
          await _profileService.updateProfile(name: name, bio: bio);
      if (response.success && response.data != null) {
        _user = response.data;
        _error = null;
      } else {
        _error = response.error ?? 'Failed to update profile';
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateProfilePicture(File photo) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final response = await _profileService.updateProfilePhoto(photo);
      if (response.success && response.data != null) {
        _user = response.data;
        _error = null;
      } else {
        _error = response.error ?? 'Failed to update profile photo';
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update skill proficiency
  Future<bool> updateSkillProficiency(SkillProficiency proficiency) async {
    if (_isLoading) return false;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response =
          await _profileService.updateSkillProficiency(proficiency);

      if (response.success && response.data != null) {
        _user = response.data;
        return true;
      } else {
        _error = response.error ?? 'Failed to update skill proficiency';
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
    try {
      final response = await _profileService.addSkill(skillId, proficiency);
      if (response.success) {
        // Refresh user data to get updated skills
        await loadUser();

        // Get the ProgressProvider from the context
        final progressProvider = Provider.of<ProgressProvider>(
          NavigationService.navigatorKey.currentContext!,
          listen: false,
        );

        // Check if a goal already exists for this skill
        final existingGoal = progressProvider.goals.firstWhereOrNull(
          (goal) => goal.skill.id == skillId,
        );

        if (existingGoal == null) {
          try {
            final goalResult = await progressProvider.createGoal(
              skillId: skillId,
              targetDate: DateTime.now().add(const Duration(days: 7)),
            );
            if (!goalResult['success']) {
              debugPrint(
                  '[DEBUG] auto-create goal failed: ${goalResult['error']}');
            }
            // Refresh goals after creation
            await progressProvider.fetchUserProgress();
          } catch (e) {
            debugPrint('[DEBUG] auto-create goal exception: $e');
          }
        }

        return true;
      } else if (response.statusCode == 400 &&
          response.error?.contains('already added') == true) {
        // Skill is already added, this is not an error
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error adding skill: $e');
      return false;
    }
  }

  // Remove skill from user profile
  Future<bool> removeSkill(String skillId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _profileService.removeSkill(skillId);
      if (response.success) {
        // Refresh user data to get updated skills
        await loadUser();
        return true;
      } else {
        _error = response.error ?? 'Failed to remove skill';
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
    await TokenStorage.clearToken();
    _user = null;
    notifyListeners();
  }

  // Add created skill to user profile
  Future<void> addCreatedSkill(String skillId) async {
    print('\n=== Adding Created Skill ===');
    print('- Skill ID to add: $skillId');
    print('- Current user state:');
    print('  - User ID: ${_user?.id}');
    print('  - User Name: ${_user?.name}');
    print('  - Current created skills: ${_user?.createdSkills}');

    if (_user != null) {
      final updatedCreatedSkills = List<String>.from(_user!.createdSkills);
      print('- Current created skills array: $updatedCreatedSkills');

      if (!updatedCreatedSkills.contains(skillId)) {
        print('- Adding skill ID to created skills array');
        updatedCreatedSkills.add(skillId);
        print('- Updated created skills array: $updatedCreatedSkills');

        _user = User(
          id: _user!.id,
          name: _user!.name,
          email: _user!.email,
          profilePicture: _user!.profilePicture,
          bio: _user!.bio,
          favoriteCategories: _user!.favoriteCategories,
          friends: _user!.friends,
          groups: _user!.groups,
          createdSkills: updatedCreatedSkills,
          skills: _user!.skills,
          skillProficiencies: _user!.skillProficiencies,
          createdAt: _user!.createdAt,
        );
        print('- New user state:');
        print('  - Created skills: ${_user?.createdSkills}');
        notifyListeners();
        print('- Notified listeners of state change');
      } else {
        print('- Skill ID already exists in created skills array');
      }
    } else {
      print('- Error: User is null');
    }
    print('=== Finished Adding Created Skill ===\n');
  }

  // Remove created skill from user profile
  Future<void> removeCreatedSkill(String skillId) async {
    if (_user != null) {
      final updatedCreatedSkills = List<String>.from(_user!.createdSkills);
      updatedCreatedSkills.remove(skillId);
      _user = User(
        id: _user!.id,
        name: _user!.name,
        email: _user!.email,
        profilePicture: _user!.profilePicture,
        bio: _user!.bio,
        favoriteCategories: _user!.favoriteCategories,
        friends: _user!.friends,
        groups: _user!.groups,
        createdSkills: updatedCreatedSkills,
        skills: _user!.skills,
        skillProficiencies: _user!.skillProficiencies,
        createdAt: _user!.createdAt,
      );
      notifyListeners();
    }
  }

  // Load user from token (only called after token is verified)
  Future<void> loadUserFromToken() async {
    setLoading(true);
    try {
      print('\n[UserProvider] Loading user from token');

      // Verify token first
      final token = await TokenStorage.getToken();
      if (token == null) {
        throw Exception('No token available');
      }

      print('[UserProvider] Token verified, fetching user data');
      final response = await _profileService.getCurrentUser();

      if (response.success && response.data != null) {
        print('[UserProvider] User data fetched successfully');
        print('[UserProvider] User ID: ${response.data!.id}');
        print('[UserProvider] User email: ${response.data!.email}');

        _user = response.data;
        _error = null;
        notifyListeners();
      } else {
        throw Exception('Failed to fetch user data');
      }
    } catch (e) {
      print('[UserProvider] Error loading user: $e');
      _error = e.toString();
      _user = null;
      notifyListeners();
    } finally {
      setLoading(false);
    }
  }

  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  // Update user's favorite categories
  Future<void> updateFavoriteCategories(List<String> categories) async {
    print('\n[UserProvider] Updating favorite categories');
    print('[UserProvider] Categories to update: $categories');

    try {
      final response =
          await _profileService.updateFavoriteCategories(categories);
      print('[UserProvider] Update response:');
      print('- Success: ${response.success}');
      print('- Status Code: ${response.statusCode}');
      print('- Data: ${response.data}');
      print('- Error: ${response.error}');

      if (response.success && response.data != null) {
        if (_user != null) {
          print('[UserProvider] Updating user model with new categories');
          print('- Old categories: ${_user!.favoriteCategories}');
          print('- New categories: ${response.data}');

          _user = _user!.copyWith(favoriteCategories: response.data!);
          print('[UserProvider] User model updated');
          print('- Updated categories: ${_user!.favoriteCategories}');

          notifyListeners();
          print('[UserProvider] Notified listeners of update');
        } else {
          print(
              '[UserProvider] Warning: User is null, cannot update categories');
        }
      } else {
        final error = response.error ?? 'Failed to update favorite categories';
        print('[UserProvider] Error: $error');
        throw Exception(error);
      }
    } catch (e) {
      print('[UserProvider] Exception: $e');
      throw Exception('Error updating favorite categories: $e');
    }
  }

  // Update user data
  Future<void> updateUser(User updatedUser) async {
    print('\n=== Updating User ===');
    print('- User ID: ${updatedUser.id}');
    print('- User Name: ${updatedUser.name}');
    print('- Created Skills: ${updatedUser.createdSkills}');

    _user = updatedUser;
    notifyListeners();
    print('=== User Update Complete ===\n');
  }

  // Add a new method to update password via the service
  Future<ApiResponse<void>> updatePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _profileService.updatePassword(
        oldPassword: oldPassword,
        newPassword: newPassword,
      );
      if (response.success) {
        // Optionally reload user if password change affects user data visible elsewhere
        // await loadUser();
        _error = null;
      } else {
        _error = response.error ?? 'Failed to update password';
      }
      return response; // Return the response to the UI for error handling
    } catch (e) {
      _error = e.toString();
      // Wrap the exception in an ApiResponse for consistency
      return ApiResponse.error(e.toString());
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
