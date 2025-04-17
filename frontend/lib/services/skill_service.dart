import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:async';
import '../models/skill_model.dart';
import '../config/app_config.dart';
import '../utils/token_storage.dart';
import 'api_client.dart';

class SkillService {
  final ApiClient _apiClient;
  final String baseUrl;

  SkillService({ApiClient? apiClient, String? baseUrl})
      : _apiClient = apiClient ?? ApiClient(),
        baseUrl = baseUrl ?? AppConfig.apiBaseUrl;

  // Default categories that will be used if API returns empty list or fails
  static const List<String> defaultCategories = [
    'Programming',
    'Design',
    'Marketing',
    'Art',
    'Music',
    'Language',
    'Business',
    'Science',
    'Health',
    'Sports',
    'Cooking',
    'Other',
  ];

  // Get all skills
  Future<ApiResponse<List<Skill>>> getSkills() async {
    try {
      final token = await TokenStorage.getToken();
      if (token == null) {
        return ApiResponse(
          success: false,
          error: 'No authentication token found',
          statusCode: 401,
        );
      }

      final response = await http.get(
        Uri.parse('${baseUrl}/skills'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) {
          final skills = data.map((item) => Skill.fromJson(item)).toList();
          return ApiResponse(
            success: true,
            data: skills,
            statusCode: response.statusCode,
          );
        } else {
          return ApiResponse(
            success: false,
            error: 'Invalid response format',
            statusCode: response.statusCode,
          );
        }
      } else {
        final data = jsonDecode(response.body);
        return ApiResponse(
          success: false,
          error: data['message'] ?? 'Failed to get skills',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse(success: false, error: e.toString(), statusCode: 0);
    }
  }

  // Get skill by ID
  Future<ApiResponse<Skill>> getSkillById(String id) async {
    try {
      final token = await TokenStorage.getToken();
      if (token == null) {
        return ApiResponse(
          success: false,
          error: 'No authentication token found',
          statusCode: 401,
        );
      }

      final response = await http.get(
        Uri.parse('${baseUrl}/skills/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ApiResponse(
          success: true,
          data: Skill.fromJson(data),
          statusCode: response.statusCode,
        );
      } else {
        final data = jsonDecode(response.body);
        return ApiResponse(
          success: false,
          error: data['message'] ?? 'Failed to get skill',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse(success: false, error: e.toString(), statusCode: 0);
    }
  }

  // Create a new skill
  Future<ApiResponse<Skill>> createSkill(
    String name,
    String category,
    String description,
    List<String> relatedSkills,
    String proficiency,
  ) async {
    try {
      final token = await TokenStorage.getToken();
      if (token == null) {
        return ApiResponse(
          success: false,
          error: 'No authentication token found',
          statusCode: 401,
        );
      }

      final response = await http.post(
        Uri.parse('${baseUrl}/skills'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'name': name,
          'category': category,
          'description': description,
          'relatedSkills': relatedSkills,
          'proficiency': proficiency,
        }),
      );

      print('Create Skill Response: ${response.statusCode}');
      print('Create Skill Body: ${response.body}');

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return ApiResponse(
          success: true,
          data: Skill.fromJson(data),
          statusCode: response.statusCode,
        );
      } else {
        final data = jsonDecode(response.body);
        return ApiResponse(
          success: false,
          error: data['message'] ?? 'Failed to create skill',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      print('Create Skill Error: $e');
      return ApiResponse(success: false, error: e.toString(), statusCode: 0);
    }
  }

  // Update a skill
  Future<ApiResponse<Skill>> updateSkill(
    String id,
    String name,
    String category,
    String description,
    List<String> relatedSkills,
    String proficiency,
  ) async {
    try {
      final token = await TokenStorage.getToken();
      if (token == null) {
        return ApiResponse(
          success: false,
          error: 'No authentication token found',
          statusCode: 401,
        );
      }

      final response = await http.put(
        Uri.parse('${baseUrl}/skills/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'name': name,
          'category': category,
          'description': description,
          'relatedSkills': relatedSkills,
          'proficiency': proficiency,
        }),
      );

      print('Update Skill Response: ${response.statusCode}');
      print('Update Skill Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ApiResponse(
          success: true,
          data: Skill.fromJson(data),
          statusCode: response.statusCode,
        );
      } else {
        final data = jsonDecode(response.body);
        return ApiResponse(
          success: false,
          error: data['message'] ?? 'Failed to update skill',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      print('Update Skill Error: $e');
      return ApiResponse(success: false, error: e.toString(), statusCode: 0);
    }
  }

  // Get all skill categories
  Future<ApiResponse<List<String>>> getCategories() async {
    try {
      final token = await TokenStorage.getToken();
      if (token == null) {
        return ApiResponse(
          success: false,
          error: 'No authentication token found',
          statusCode: 401,
        );
      }

      final response = await http.get(
        Uri.parse('${baseUrl}/skills/categories'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) {
          final apiCategories = data.map((item) => item.toString()).toList();
          final allCategories = [...defaultCategories];
          for (final category in apiCategories) {
            if (!allCategories.contains(category)) {
              allCategories.add(category);
            }
          }
          return ApiResponse(
            success: true,
            data: allCategories,
            statusCode: response.statusCode,
          );
        } else {
          return ApiResponse(
            success: true,
            data: defaultCategories,
            statusCode: response.statusCode,
          );
        }
      } else {
        return ApiResponse(
          success: true,
          data: defaultCategories,
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse(success: true, data: defaultCategories, statusCode: 0);
    }
  }

  // Get skill recommendations for user
  Future<ApiResponse<List<Skill>>> getRecommendations() async {
    try {
      final response = await _apiClient
          .get<List<Skill>>('skills/recommendations', (json, _) {
        if (json is String) {
          final parsedJson = jsonDecode(json);
          if (parsedJson is List) {
            return parsedJson.map((x) => Skill.fromJson(x)).toList();
          }
        } else if (json is List) {
          return json.map((x) => Skill.fromJson(x)).toList();
        }
        return [];
      }).timeout(const Duration(seconds: 10));

      return response;
    } on TimeoutException {
      return ApiResponse(
        success: false,
        error: 'Request timed out. Please check your internet connection.',
        statusCode: 408,
      );
    } catch (e) {
      print('Error in getRecommendations: $e');
      return ApiResponse(
        success: false,
        error: 'Failed to get recommendations: ${e.toString()}',
        statusCode: 500,
      );
    }
  }

  // Get skills for a specific user
  Future<ApiResponse<List<Skill>>> getUserSkills(String userId) async {
    return await _apiClient.get<List<Skill>>(
      'skills/user/$userId',
      (json, _) => (json as List).map((x) => Skill.fromJson(x)).toList(),
    );
  }
}
