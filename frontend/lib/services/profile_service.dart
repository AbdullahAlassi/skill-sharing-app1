import '../models/user_model.dart';
import 'api_client.dart';
import '../utils/json_parser.dart';
import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../models/skill_proficiency_model.dart';
import '../utils/token_storage.dart';
import '../config/app_config.dart';
import 'dart:io';
import 'package:http_parser/http_parser.dart';
import '../utils/api_response.dart';

class ProfileService {
  final ApiClient _apiClient;
  final Duration _timeoutDuration = Duration(seconds: 10);
  final String baseUrl;

  ProfileService(this._apiClient, {this.baseUrl = AppConfig.apiBaseUrl});

  // Get current user profile
  Future<ApiResponse<User>> getCurrentUser() async {
    try {
      final response = await _apiClient.get<User>(
        'api/users/me',
        (json) => User.fromJson(json),
      );
      return response;
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }

  // Update user profile
  Future<ApiResponse<User>> updateProfile(
      {required String name, required String bio}) async {
    try {
      final response = await _apiClient.put<User>(
        'api/users/me',
        {'name': name, 'bio': bio},
        (json) => User.fromJson(json),
      );
      return response;
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }

  // Add a new method to update password
  Future<ApiResponse<void>> updatePassword(
      {required String oldPassword, required String newPassword}) async {
    try {
      final response = await _apiClient.put<void>(
        'api/users/me/password',
        {'oldPassword': oldPassword, 'newPassword': newPassword},
        (json) => null, // No data is expected in the success response body
      );
      return response;
    } catch (e) {
      // Handle potential errors like incorrect old password
      if (e is http.Response) {
        final data = jsonDecode(e.body);
        return ApiResponse.error(
          data['message'] ?? 'Failed to update password',
          statusCode: e.statusCode,
        );
      }
      return ApiResponse.error(e.toString());
    }
  }

  // Update profile photo
  Future<ApiResponse<User>> updateProfilePhoto(File photo) async {
    try {
      final request = http.MultipartRequest(
        'PUT',
        Uri.parse('$baseUrl/api/users/me/photo'),
      );

      // Add authorization header
      final token = await _apiClient.getToken();
      request.headers['Authorization'] = 'Bearer $token';

      // Add photo file
      final fileStream = http.ByteStream(photo.openRead());
      final fileLength = await photo.length();
      final multipartFile = http.MultipartFile(
        'photo',
        fileStream,
        fileLength,
        filename: photo.path.split('/').last,
        contentType: MediaType('image', 'jpeg'),
      );
      request.files.add(multipartFile);

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final jsonData = jsonDecode(response.body);
        return ApiResponse.success(
          data: User.fromJson(jsonData['data'] ?? jsonData),
          statusCode: response.statusCode,
        );
      } else {
        return ApiResponse.error(
          'Failed to update profile photo',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      print('Error updating profile photo: $e');
      return ApiResponse.error(e.toString());
    }
  }

  // Add skill to user profile
  Future<ApiResponse<List<dynamic>>> addSkill(
      String skillId, String proficiency) async {
    try {
      final response = await _apiClient.post<List<dynamic>>(
        'api/profile/skills',
        {
          'skillId': skillId,
          'proficiency': proficiency,
        },
        (json) => json as List<dynamic>,
      );
      return response;
    } catch (e) {
      if (e is http.Response) {
        final data = jsonDecode(e.body);
        return ApiResponse.error(
          data['message'] ?? 'Failed to add skill',
          statusCode: e.statusCode,
        );
      }
      return ApiResponse.error(e.toString());
    }
  }

  // Remove skill from user profile
  Future<ApiResponse<List<dynamic>>> removeSkill(String skillId) async {
    try {
      final response = await _apiClient.delete<List<dynamic>>(
        'api/profile/skills/$skillId',
        (json) => json as List<dynamic>,
      );
      return response;
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }

  // Update profile picture
  Future<ApiResponse<User>> updateProfilePicture(File photo) async {
    try {
      final request = http.MultipartRequest(
        'PUT',
        Uri.parse('$baseUrl/api/users/me/photo'),
      );

      // Add authorization header
      final token = await _apiClient.getToken();
      request.headers['Authorization'] = 'Bearer $token';

      // Add photo file
      final fileStream = http.ByteStream(photo.openRead());
      final fileLength = await photo.length();
      final multipartFile = http.MultipartFile(
        'photo',
        fileStream,
        fileLength,
        filename: photo.path.split('/').last,
        contentType: MediaType('image', 'jpeg'),
      );
      request.files.add(multipartFile);

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final jsonData = jsonDecode(response.body);
        return ApiResponse.success(
          data: User.fromJson(jsonData['data'] ?? jsonData),
          statusCode: response.statusCode,
        );
      } else {
        return ApiResponse.error(
          'Failed to update profile photo',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }

  Future<ApiResponse<User>> updateSkillProficiency(
      SkillProficiency proficiency) async {
    try {
      final response = await _apiClient.put<User>(
        'api/users/me/skills/${proficiency.skillId}/proficiency',
        proficiency.toJson(),
        (json) => User.fromJson(json),
      );
      return response;
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }

  Future<ApiResponse<List<dynamic>>> getUserSkills() async {
    try {
      final response = await _apiClient.get<List<dynamic>>(
        'api/users/me/skills',
        (json) {
          if (json is Map<String, dynamic> && json.containsKey('data')) {
            return json['data'] as List<dynamic>;
          }
          return json as List<dynamic>;
        },
      );
      return response;
    } catch (e) {
      print('Error in getUserSkills: $e');
      return ApiResponse.error(e.toString());
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> updatePreferences(
      Map<String, dynamic> preferences) async {
    try {
      final response = await _apiClient.put<Map<String, dynamic>>(
        'api/users/preferences',
        preferences,
        (json) => json as Map<String, dynamic>,
      );
      return response;
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> getPreferences() async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        'api/users/preferences',
        (json) => json as Map<String, dynamic>,
      );
      return response;
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }

  Future<ApiResponse<List<String>>> updateFavoriteCategories(
      List<String> categories) async {
    try {
      final response = await _apiClient.rawPut(
        'api/users/preferences',
        {'favoriteCategories': categories},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> parsed = jsonDecode(response.body);
        if (parsed['success'] == true && parsed['data'] is List) {
          final list = List<String>.from(parsed['data']);
          return ApiResponse.success(
              data: list, statusCode: 200, message: 'Updated successfully');
        } else {
          return ApiResponse.error(parsed['message'] ?? 'Failed',
              statusCode: 200);
        }
      } else {
        return ApiResponse.error('Request failed',
            statusCode: response.statusCode);
      }
    } catch (e) {
      return ApiResponse.error(e.toString(), statusCode: 500);
    }
  }
}
