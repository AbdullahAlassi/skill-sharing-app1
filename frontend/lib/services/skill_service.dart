import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:skill_sharing_app/main.dart';
import 'package:skill_sharing_app/utils/api_response.dart';
import 'dart:async';
import '../models/skill_model.dart';
import '../models/skill_category.dart';
import '../config/app_config.dart';
import '../utils/token_storage.dart';
import 'api_client.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import 'package:flutter/material.dart';

class SkillService {
  final ApiClient _apiClient;
  final String baseUrl;

  SkillService({ApiClient? apiClient, String? baseUrl})
      : _apiClient = apiClient ?? ApiClient(baseUrl: AppConfig.apiBaseUrl),
        baseUrl = baseUrl ?? AppConfig.apiBaseUrl;

  // Search skills with filters
  Future<ApiResponse<List<Skill>>> searchSkills({
    String? query,
    String? category,
    String? level,
  }) async {
    try {
      // Build query parameters
      final queryParams = <String, String>{};
      if (query != null && query.isNotEmpty) queryParams['query'] = query;
      if (category != null && category.isNotEmpty)
        queryParams['category'] = category;
      if (level != null && level.isNotEmpty) queryParams['level'] = level;

      // Build the endpoint URL with query parameters
      final queryString = queryParams.entries
          .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
          .join('&');
      final endpoint =
          'api/skills/search${queryString.isNotEmpty ? '?$queryString' : ''}';

      final response = await _apiClient.get(endpoint, (json) => json);
      if (response != null && response is ApiResponse) {
        final body = response.data;
        if (body is Map<String, dynamic> && body['data'] is List) {
          final skills =
              body['data'].map((item) => Skill.fromJson(item)).toList();
          return ApiResponse(
            success: true,
            data: List<Skill>.from(skills),
            message: 'Skills loaded successfully',
            statusCode: response.statusCode,
          );
        } else if (body is List) {
          final skills = body.map((item) => Skill.fromJson(item)).toList();
          return ApiResponse(
            success: true,
            data: List<Skill>.from(skills),
            message: 'Skills loaded successfully',
            statusCode: response.statusCode,
          );
        } else {
          return ApiResponse(
            success: false,
            error: 'Invalid response format',
            message: 'Invalid response format',
            statusCode: response.statusCode,
          );
        }
      } else {
        return ApiResponse(
          success: false,
          error: 'Failed to get skills',
          message: 'Failed to get skills',
          statusCode: 500,
        );
      }
    } catch (e) {
      print('Error in searchSkills: $e');
      return ApiResponse(
        success: false,
        error: e.toString(),
        message: 'Failed to search skills',
        statusCode: 500,
      );
    }
  }

  // Get all skills
  Future<ApiResponse<List<Skill>>> getSkills() async {
    try {
      final token = await TokenStorage.getToken();
      if (token == null) {
        return ApiResponse(
          success: false,
          error: 'No authentication token found',
          message: 'Authentication required',
          statusCode: 401,
        );
      }

      final response = await http.get(
        Uri.parse('${baseUrl}/api/skills'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body is Map<String, dynamic> && body['data'] is List) {
          final skills =
              body['data'].map((item) => Skill.fromJson(item)).toList();
          return ApiResponse(
            success: true,
            data: List<Skill>.from(skills),
            message: 'Skills loaded successfully',
            statusCode: response.statusCode,
          );
        } else if (body is List) {
          final skills = body.map((item) => Skill.fromJson(item)).toList();
          return ApiResponse(
            success: true,
            data: List<Skill>.from(skills),
            message: 'Skills loaded successfully',
            statusCode: response.statusCode,
          );
        } else {
          return ApiResponse(
            success: false,
            error: 'Invalid response format',
            message: 'Invalid response format',
            statusCode: response.statusCode,
          );
        }
      } else {
        final data = jsonDecode(response.body);
        return ApiResponse(
          success: false,
          error: data['message'] ?? 'Failed to get skills',
          message: 'Failed to get skills',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse(
        success: false,
        error: e.toString(),
        message: 'Operation failed',
        statusCode: 0,
      );
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
          message: 'Authentication required',
          statusCode: 401,
        );
      }

      final response = await http.get(
        Uri.parse('${baseUrl}/api/skills/$id'),
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
          message: 'Skill loaded successfully',
          statusCode: response.statusCode,
        );
      } else {
        final data = jsonDecode(response.body);
        return ApiResponse(
          success: false,
          error: data['message'] ?? 'Failed to get skill',
          message: 'Failed to get skill',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse(
        success: false,
        error: e.toString(),
        message: 'Operation failed',
        statusCode: 0,
      );
    }
  }

  // Get skills by category
  Future<ApiResponse<List<Skill>>> getSkillsByCategory(
      String categoryName) async {
    try {
      final token = await TokenStorage.getToken();
      if (token == null) {
        return ApiResponse(
          success: false,
          error: 'No authentication token found',
          message: 'Authentication required',
          statusCode: 401,
        );
      }

      final uri = Uri.parse('${baseUrl}/api/skills/category/${categoryName}');

      final response = await http.get(
        uri,
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
            message: 'Skills loaded successfully for category',
            statusCode: response.statusCode,
          );
        } else {
          return ApiResponse(
            success: false,
            error: 'Invalid response format',
            message: 'Invalid response format',
            statusCode: response.statusCode,
          );
        }
      } else {
        final data = jsonDecode(response.body);
        return ApiResponse(
          success: false,
          error: data['message'] ?? 'Failed to get skills by category',
          message: 'Failed to get skills by category',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse(
        success: false,
        error: e.toString(),
        message: 'Operation failed',
        statusCode: 0,
      );
    }
  }

  // Create a new skill
  Future<ApiResponse<Skill>> createSkill(
    String name,
    String category,
    String description,
    List<String> relatedSkills,
    String proficiency,
    String difficultyLevel,
  ) async {
    try {
      final token = await TokenStorage.getToken();
      if (token == null) {
        return ApiResponse(
          success: false,
          error: 'No authentication token found',
          message: 'Authentication required',
          statusCode: 401,
        );
      }

      // Get current user ID
      final userProvider = Provider.of<UserProvider>(
          navigatorKey.currentContext!,
          listen: false);
      final currentUser = userProvider.user;

      if (currentUser == null) {
        return ApiResponse(
          success: false,
          error: 'User not found',
          message: 'User not found',
          statusCode: 401,
        );
      }

      // Validate related skills
      final validRelatedSkills = <String>[];
      for (final skillId in relatedSkills) {
        // Check if the skill exists
        final skillResponse = await getSkillById(skillId);
        if (skillResponse.success && skillResponse.data != null) {
          validRelatedSkills.add(skillId);
        }
      }

      final response = await http.post(
        Uri.parse('${baseUrl}/api/skills'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'name': name,
          'category': category,
          'description': description,
          'relatedSkills': validRelatedSkills,
          'proficiency': proficiency,
          'difficultyLevel': difficultyLevel,
          'createdBy': currentUser.id,
        }),
      );

      print('Create Skill Response: ${response.statusCode}');
      print('Create Skill Body: ${response.body}');

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);

        // Convert relatedSkills from objects to IDs if needed
        if (data['relatedSkills'] != null && data['relatedSkills'] is List) {
          data['relatedSkills'] = (data['relatedSkills'] as List).map((skill) {
            if (skill is Map) {
              return skill['_id'] ?? skill['id'];
            }
            return skill;
          }).toList();
        }

        final skill = Skill.fromJson(data);

        // Add skill ID to user's createdSkills
        if (skill.id.isNotEmpty) {
          print('=== Adding Created Skill ===');
          print('- Skill ID to add: ${skill.id}');
          print('- Current user state:');
          print('  - User ID: ${currentUser.id}');
          print('  - User Name: ${currentUser.name}');
          print('  - Current created skills: ${currentUser.createdSkills}');

          // Create a new list with the new skill ID
          final updatedCreatedSkills =
              List<String>.from(currentUser.createdSkills);
          updatedCreatedSkills.add(skill.id);

          // Update the user with the new list
          final updatedUser =
              currentUser.copyWith(createdSkills: updatedCreatedSkills);
          await userProvider.updateUser(updatedUser);
        }

        return ApiResponse(
          success: true,
          data: skill,
          message: 'Skill created successfully',
          statusCode: response.statusCode,
        );
      } else {
        final data = jsonDecode(response.body);
        return ApiResponse(
          success: false,
          error: data['message'] ?? 'Failed to create skill',
          message: 'Failed to create skill',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      print('Create Skill Error: $e');
      return ApiResponse(
        success: false,
        error: e.toString(),
        message: 'Failed to create skill',
        statusCode: 0,
      );
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
          message: 'Authentication required',
          statusCode: 401,
        );
      }

      final response = await http.put(
        Uri.parse('${baseUrl}/api/skills/$id'),
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
          message: 'Skill updated successfully',
          statusCode: response.statusCode,
        );
      } else {
        final data = jsonDecode(response.body);
        return ApiResponse(
          success: false,
          error: data['message'] ?? 'Failed to update skill',
          message: 'Failed to update skill',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      print('Update Skill Error: $e');
      return ApiResponse(
        success: false,
        error: e.toString(),
        message: 'Failed to update skill',
        statusCode: 0,
      );
    }
  }

  // Get all categories
  Future<ApiResponse<List<SkillCategory>>> getCategories() async {
    try {
      final token = await TokenStorage.getToken();
      if (token == null) {
        return ApiResponse(
          success: false,
          error: 'No authentication token found',
          message: 'Authentication required',
          statusCode: 401,
        );
      }

      final response = await http.get(
        Uri.parse('${baseUrl}/api/skill-categories'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) {
          final categories =
              data.map((item) => SkillCategory.fromJson(item)).toList();
          return ApiResponse(
            success: true,
            data: categories,
            message: 'Categories loaded successfully',
            statusCode: response.statusCode,
          );
        } else {
          return ApiResponse(
            success: false,
            error: 'Invalid response format',
            message: 'Invalid response format',
            statusCode: response.statusCode,
          );
        }
      } else {
        final data = jsonDecode(response.body);
        return ApiResponse(
          success: false,
          error: data['message'] ?? 'Failed to get categories',
          message: 'Failed to get categories',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse(
        success: false,
        error: e.toString(),
        message: 'Operation failed',
        statusCode: 0,
      );
    }
  }

  // Get skill recommendations for user
  Future<ApiResponse<List<Skill>>> getRecommendations() async {
    try {
      final response = await _apiClient
          .get<Map<String, dynamic>>('api/skills/recommendations', (json) {
        if (json is String) {
          final parsedJson = jsonDecode(json) as Map<String, dynamic>;
          if (parsedJson['recommendations'] is List) {
            return parsedJson;
          }
        } else if (json is Map<String, dynamic> &&
            json['recommendations'] is List) {
          return json;
        }
        return <String, dynamic>{'recommendations': []};
      }).timeout(const Duration(seconds: 10));

      if (response.data != null && response.data!['recommendations'] is List) {
        final recommendations = (response.data!['recommendations'] as List)
            .map((x) => Skill.fromJson(x as Map<String, dynamic>))
            .toList();

        return ApiResponse(
          success: true,
          data: recommendations,
          message: 'Recommendations loaded successfully',
          statusCode: 200,
        );
      }

      return ApiResponse(
        success: false,
        error: 'Invalid response format',
        message: 'Invalid response format',
        statusCode: 500,
      );
    } on TimeoutException {
      return ApiResponse(
        success: false,
        error: 'Request timed out. Please check your internet connection.',
        message: 'Request timed out',
        statusCode: 408,
      );
    } catch (e) {
      print('Error in getRecommendations: $e');
      return ApiResponse(
        success: false,
        error: 'Failed to get recommendations: ${e.toString()}',
        message: 'Failed to get recommendations',
        statusCode: 500,
      );
    }
  }

  // Get skills for a specific user
  Future<ApiResponse<List<Skill>>> getUserSkills(String userId) async {
    try {
      final token = await TokenStorage.getToken();
      if (token == null) {
        return ApiResponse(
          success: false,
          error: 'No authentication token found',
          message: 'Authentication required',
          statusCode: 401,
        );
      }

      final response = await http.get(
        Uri.parse('${baseUrl}/api/users/me/skills'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['skills'] != null && data['skills'] is List) {
          final skills = (data['skills'] as List)
              .map((skillObj) => Skill.fromJson(skillObj['skill']))
              .toList();
          return ApiResponse(
            success: true,
            data: skills,
            message: 'User skills loaded successfully',
            statusCode: response.statusCode,
          );
        }
        return ApiResponse(
          success: true,
          data: [],
          message: 'No skills found',
          statusCode: response.statusCode,
        );
      } else {
        final data = jsonDecode(response.body);
        return ApiResponse(
          success: false,
          error: data['message'] ?? 'Failed to get user skills',
          message: 'Failed to get user skills',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse(
        success: false,
        error: e.toString(),
        message: 'Failed to get user skills',
        statusCode: 0,
      );
    }
  }

  // Get skill roadmap
  Future<ApiResponse<Map<String, dynamic>>> getSkillRoadmap(
      String skillId) async {
    try {
      final token = await TokenStorage.getToken();
      if (token == null) {
        return ApiResponse(
          success: false,
          error: 'No authentication token found',
          message: 'Authentication required',
          statusCode: 401,
        );
      }

      final response = await http.get(
        Uri.parse('${baseUrl}/api/skills/$skillId/roadmap'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ApiResponse(
          success: true,
          data: data,
          message: 'Skill roadmap loaded successfully',
          statusCode: response.statusCode,
        );
      } else {
        final data = jsonDecode(response.body);
        return ApiResponse(
          success: false,
          error: data['message'] ?? 'Failed to get skill roadmap',
          message: 'Failed to get skill roadmap',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse(
        success: false,
        error: e.toString(),
        message: 'Failed to get skill roadmap',
        statusCode: 0,
      );
    }
  }

  // Get skills created by the current user
  Future<ApiResponse<List<Skill>>> getMyCreatedSkills(
      {String? category}) async {
    try {
      final token = await TokenStorage.getToken();
      if (token == null) {
        return ApiResponse(
          success: false,
          error: 'No authentication token found',
          message: 'Authentication required',
          statusCode: 401,
        );
      }

      final queryParams = <String, String>{};
      if (category != null && category.isNotEmpty) {
        queryParams['category'] = category;
      }

      final uri = Uri.parse('${baseUrl}/api/skills/my')
          .replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('created skills loaded');
      print(response.body);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) {
          // Process each skill to convert relatedSkills from objects to IDs
          final skills = data.map((item) {
            if (item['relatedSkills'] != null &&
                item['relatedSkills'] is List) {
              item['relatedSkills'] =
                  (item['relatedSkills'] as List).map((skill) {
                if (skill is Map) {
                  return skill['_id'] ?? skill['id'];
                }
                return skill;
              }).toList();
            }
            return Skill.fromJson(item);
          }).toList();

          return ApiResponse(
            success: true,
            data: skills,
            message: 'Created skills loaded successfully',
            statusCode: response.statusCode,
          );
        } else {
          return ApiResponse(
            success: false,
            error: 'Invalid response format',
            message: 'Invalid response format',
            statusCode: response.statusCode,
          );
        }
      } else {
        final data = jsonDecode(response.body);
        return ApiResponse(
          success: false,
          error: data['message'] ?? 'Failed to get created skills',
          message: 'Failed to get created skills',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      print('Get My Created Skills Error: $e');
      return ApiResponse(
        success: false,
        error: e.toString(),
        message: 'Failed to get created skills',
        statusCode: 0,
      );
    }
  }
}
