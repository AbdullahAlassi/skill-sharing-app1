import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/app_config.dart';
import '../models/user_model.dart';
import '../utils/token_storage.dart';
import 'api_client.dart';

class ProfileService {
  final ApiClient _apiClient;

  ProfileService({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  // Get user profile
  Future<ApiResponse<User>> getUserProfile() async {
    return await _apiClient.get<User>('profile', (json) => User.fromJson(json));
  }

  // Update user profile
  Future<ApiResponse<User>> updateProfile(String name, String bio) async {
    return await _apiClient.put<User>('profile', {
      'name': name,
      'bio': bio,
    }, (json) => User.fromJson(json));
  }

  // Add skill to user profile
  Future<ApiResponse<List<UserSkill>>> addSkill(
    String skillId,
    String proficiency,
  ) async {
    return await _apiClient.post<List<UserSkill>>(
      'profile/skills',
      {'skillId': skillId, 'proficiency': proficiency},
      (json) => List<UserSkill>.from(json.map((x) => UserSkill.fromJson(x))),
    );
  }

  // Remove skill from user profile
  Future<ApiResponse<List<UserSkill>>> removeSkill(String skillId) async {
    return await _apiClient.delete<List<UserSkill>>(
      'profile/skills/$skillId',
      (json) => List<UserSkill>.from(json.map((x) => UserSkill.fromJson(x))),
    );
  }

  // Add interest to user profile
  Future<ApiResponse<List<dynamic>>> addInterest(String skillId) async {
    return await _apiClient.post<List<dynamic>>('profile/interests', {
      'skillId': skillId,
    }, (json) => json);
  }

  // Remove interest from user profile
  Future<ApiResponse<List<dynamic>>> removeInterest(String skillId) async {
    return await _apiClient.delete<List<dynamic>>(
      'profile/interests/$skillId',
      (json) => json,
    );
  }

  // Upload profile picture
  Future<ApiResponse<Map<String, dynamic>>> uploadProfilePicture(
    File image,
  ) async {
    try {
      final token = await TokenStorage.getToken();

      if (token == null) {
        return ApiResponse.error('Not authenticated');
      }

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${AppConfig.apiBaseUrl}/profile/picture'),
      );

      request.headers.addAll({'Authorization': 'Bearer $token'});

      request.files.add(
        await http.MultipartFile.fromPath('profilePicture', image.path),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        return ApiResponse.success(
          Map<String, dynamic>.from(jsonDecode(response.body)),
        );
      } else {
        final error = jsonDecode(response.body)['message'] ?? 'Upload failed';
        return ApiResponse.error(error);
      }
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }
}
