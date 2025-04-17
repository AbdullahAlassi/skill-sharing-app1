import '../models/user_model.dart';
import 'api_client.dart';
import '../utils/json_parser.dart';
import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../models/skill_proficiency_model.dart';
import '../utils/token_storage.dart';
import '../config/app_config.dart';

class ProfileService {
  final ApiClient _apiClient;
  final Duration _timeoutDuration = Duration(seconds: 10);
  final String baseUrl;

  ProfileService({ApiClient? apiClient, this.baseUrl = AppConfig.apiBaseUrl})
      : _apiClient = apiClient ?? ApiClient();

  // Update user profile
  Future<ApiResponse<User>> updateProfile(String name, String bio) async {
    try {
      final token = await TokenStorage.getToken();
      if (token == null) {
        return ApiResponse(success: false, error: 'Not authenticated');
      }

      final response = await http.put(
        Uri.parse('$baseUrl/users/me'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'name': name,
          'bio': bio,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ApiResponse(
          success: true,
          data: User.fromJson(data),
        );
      } else {
        return ApiResponse(
          success: false,
          error: 'Failed to update profile',
        );
      }
    } catch (e) {
      return ApiResponse(
        success: false,
        error: e.toString(),
      );
    }
  }

  // Add skill to user profile
  Future<ApiResponse<User>> addSkill(String skillId, String proficiency) async {
    try {
      print(
          '1. Starting addSkill with skillId: $skillId, proficiency: $proficiency');

      final token = await TokenStorage.getToken();
      if (token == null) {
        print('2. No token found');
        return ApiResponse(
          success: false,
          error: 'No authentication token found',
          statusCode: 401,
        );
      }
      print('3. Token found, making POST request to add skill');

      final response = await http.post(
        Uri.parse('$baseUrl/profile/skills'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'skillId': skillId,
          'proficiency': proficiency,
        }),
      );

      print('4. Add Skill API Response Status: ${response.statusCode}');
      print('5. Add Skill API Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('6. Skill added successfully, fetching updated user data');

        final userResponse = await http.get(
          Uri.parse('$baseUrl/users/me'),
          headers: {
            'Authorization': 'Bearer $token',
          },
        );

        print('7. User API Response Status: ${userResponse.statusCode}');
        print('8. User API Response Body: ${userResponse.body}');

        if (userResponse.statusCode == 200) {
          try {
            print('9. Attempting to parse user data');
            final userData = json.decode(userResponse.body);
            print('10. Parsed user data type: ${userData.runtimeType}');
            print('11. Parsed user data: $userData');

            if (userData is Map<String, dynamic>) {
              print('12. User data is Map, creating User object');
              final user = User.fromJson(userData);
              print('13. User object created successfully');
              return ApiResponse(
                success: true,
                data: user,
                statusCode: response.statusCode,
              );
            } else {
              print(
                  '14. User data is not a Map, actual type: ${userData.runtimeType}');
              return ApiResponse(
                success: false,
                error: 'Invalid user data format: ${userData.runtimeType}',
                statusCode: 500,
              );
            }
          } catch (e, stackTrace) {
            print('15. Error parsing user data: $e');
            print('16. Stack trace: $stackTrace');
            return ApiResponse(
              success: false,
              error: 'Failed to parse user data: $e',
              statusCode: 500,
            );
          }
        } else {
          print(
              '17. Failed to get user data, status: ${userResponse.statusCode}');
          return ApiResponse(
            success: false,
            error: 'Failed to get updated user data',
            statusCode: userResponse.statusCode,
          );
        }
      } else {
        try {
          print('18. Skill addition failed, parsing error response');
          final errorData = json.decode(response.body);
          print('19. Error data: $errorData');
          return ApiResponse(
            success: false,
            error: errorData['message'] ?? 'Failed to add skill',
            statusCode: response.statusCode,
          );
        } catch (e) {
          print('20. Error parsing error response: $e');
          return ApiResponse(
            success: false,
            error: 'Failed to add skill: ${response.body}',
            statusCode: response.statusCode,
          );
        }
      }
    } catch (e, stackTrace) {
      print('21. Unexpected error in addSkill: $e');
      print('22. Stack trace: $stackTrace');
      return ApiResponse(
        success: false,
        error: 'Failed to add skill: $e',
        statusCode: 500,
      );
    }
  }

  // Remove skill from user profile
  Future<ApiResponse<User>> removeSkill(String skillId) async {
    try {
      final token = await TokenStorage.getToken();
      if (token == null) {
        return ApiResponse(success: false, error: 'Not authenticated');
      }

      final response = await http.delete(
        Uri.parse('$baseUrl/users/skills/$skillId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ApiResponse(
          success: true,
          data: User.fromJson(data),
        );
      } else {
        return ApiResponse(
          success: false,
          error: 'Failed to remove skill',
        );
      }
    } catch (e) {
      return ApiResponse(
        success: false,
        error: e.toString(),
      );
    }
  }

  // Update profile picture
  Future<ApiResponse<User>> updateProfilePicture(String imageUrl) async {
    try {
      final token = await TokenStorage.getToken();
      if (token == null) {
        return ApiResponse(success: false, error: 'Not authenticated');
      }

      final response = await http.put(
        Uri.parse('$baseUrl/users/profile/picture'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'profilePicture': imageUrl}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ApiResponse(
          success: true,
          data: User.fromJson(data),
        );
      } else {
        return ApiResponse(
          success: false,
          error: 'Failed to update profile picture',
        );
      }
    } catch (e) {
      return ApiResponse(
        success: false,
        error: e.toString(),
      );
    }
  }

  // Get user profile
  Future<ApiResponse<User>> getProfile() async {
    try {
      final token = await TokenStorage.getToken();
      if (token == null) {
        return ApiResponse(success: false, error: 'Not authenticated');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/users/me'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ApiResponse(
          success: true,
          data: User.fromJson(data),
        );
      } else {
        return ApiResponse(
          success: false,
          error: 'Failed to get profile',
        );
      }
    } catch (e) {
      return ApiResponse(
        success: false,
        error: e.toString(),
      );
    }
  }

  Future<ApiResponse<User>> updateSkillProficiency(
      SkillProficiency proficiency) async {
    try {
      final token = await TokenStorage.getToken();
      if (token == null) {
        return ApiResponse(success: false, error: 'Not authenticated');
      }

      final response = await http.put(
        Uri.parse('$baseUrl/users/skills/${proficiency.skillId}/proficiency'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(proficiency.toJson()),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ApiResponse(
          success: true,
          data: User.fromJson(data),
        );
      } else {
        return ApiResponse(
          success: false,
          error: 'Failed to update skill proficiency',
        );
      }
    } catch (e) {
      return ApiResponse(
        success: false,
        error: e.toString(),
      );
    }
  }
}

class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? error;
  final int? statusCode;

  ApiResponse({
    required this.success,
    this.data,
    this.error,
    this.statusCode,
  });
}
