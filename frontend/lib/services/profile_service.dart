import '../models/user_model.dart';
import 'api_client.dart';
import '../utils/json_parser.dart';
import 'dart:convert';
import 'dart:async';

class ProfileService {
  final ApiClient _apiClient;
  final Duration _timeoutDuration = Duration(seconds: 10);

  ProfileService({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  // Update user profile
  Future<ApiResponse<User>> updateProfile(String name, String bio) async {
    return await _apiClient.put<User>('profile', {'name': name, 'bio': bio}, (
      responseBody,
      _,
    ) {
      // Parse the response body first
      final jsonData = JsonParser.parseNonStandardJson(responseBody);
      return User.fromJson(jsonData);
    });
  }

  // Add skill to user profile
  Future<ApiResponse<User>> addSkill(String skillId, String proficiency) async {
    try {
      final response = await _apiClient
          .post<User>(
            'profile/skills',
            {'skillId': skillId, 'proficiency': proficiency},
            (json, _) {
              if (json is String) {
                final parsedJson = jsonDecode(json);
                if (parsedJson is List && parsedJson.isNotEmpty) {
                  // If the response is a list, take the first item
                  return User.fromJson(
                    parsedJson.first as Map<String, dynamic>,
                  );
                }
              } else if (json is List && json.isNotEmpty) {
                // If the response is already a list, take the first item
                return User.fromJson(json.first as Map<String, dynamic>);
              } else if (json is Map) {
                return User.fromJson(json as Map<String, dynamic>);
              }
              throw Exception('Invalid response format');
            },
          )
          .timeout(_timeoutDuration);

      return response;
    } on TimeoutException {
      return ApiResponse(
        success: false,
        error: 'Request timed out. Please check your internet connection.',
        statusCode: 408,
      );
    } catch (e) {
      print('Error in addSkill: $e');
      return ApiResponse(
        success: false,
        error: 'Failed to add skill: ${e.toString()}',
        statusCode: 500,
      );
    }
  }

  // Remove skill from user profile
  Future<ApiResponse<User>> removeSkill(String skillId) async {
    try {
      final response = await _apiClient
          .delete<User>('profile/skills/$skillId', (json, _) {
            if (json is String) {
              final parsedJson = jsonDecode(json);
              if (parsedJson is List && parsedJson.isNotEmpty) {
                // If the response is a list, take the first item
                return User.fromJson(parsedJson.first as Map<String, dynamic>);
              }
            } else if (json is List && json.isNotEmpty) {
              // If the response is already a list, take the first item
              return User.fromJson(json.first as Map<String, dynamic>);
            } else if (json is Map) {
              return User.fromJson(json as Map<String, dynamic>);
            }
            throw Exception('Invalid response format');
          })
          .timeout(_timeoutDuration);

      return response;
    } on TimeoutException {
      return ApiResponse(
        success: false,
        error: 'Request timed out. Please check your internet connection.',
        statusCode: 408,
      );
    } catch (e) {
      print('Error in removeSkill: $e');
      return ApiResponse(
        success: false,
        error: 'Failed to remove skill: ${e.toString()}',
        statusCode: 500,
      );
    }
  }

  // Update profile picture
  Future<ApiResponse<User>> updateProfilePicture(String imageUrl) async {
    return await _apiClient.put<User>(
      'profile/picture',
      {'profilePicture': imageUrl},
      (responseBody, _) {
        final jsonData = JsonParser.parseNonStandardJson(responseBody);
        return User.fromJson(jsonData);
      },
    );
  }

  // Get user profile
  Future<ApiResponse<User>> getProfile() async {
    return await _apiClient.get<User>('profile', (responseBody, _) {
      final jsonData = JsonParser.parseNonStandardJson(responseBody);
      return User.fromJson(jsonData);
    });
  }
}
