import 'package:skill_sharing_app/utils/api_response.dart';

import '../models/progress_model.dart';
import 'api_client.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:skill_sharing_app/config/app_config.dart';
import 'package:skill_sharing_app/models/goal_model.dart';
import 'package:skill_sharing_app/utils/token_storage.dart';

class ProgressService {
  final ApiClient _apiClient;
  final String baseUrl = AppConfig.apiBaseUrl;

  ProgressService({required ApiClient apiClient}) : _apiClient = apiClient;

  // Get all progress for current user
  Future<ApiResponse<Map<String, dynamic>>> getUserProgress() async {
    try {
      final token = await TokenStorage.getToken();
      if (token == null) {
        return ApiResponse(
          success: false,
          error: 'Not authenticated',
          message: 'Authentication required',
          statusCode: 401,
        );
      }

      final response = await http.get(
        Uri.parse('$baseUrl/api/progress'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('[DEBUG] Raw progress response: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return ApiResponse(
          success: true,
          data: data,
          message: 'Progress data loaded successfully',
          statusCode: 200,
        );
      } else if (response.statusCode == 404) {
        // Return empty data structure when no progress is found
        return ApiResponse(
          success: true,
          data: {
            'totalProgress': 0.0,
            'skillProgress': [],
            'completedResources': [],
            'practiceHistory': [],
          },
          message: 'No progress found',
          statusCode: 200,
        );
      } else {
        final errorData = json.decode(response.body);
        return ApiResponse(
          success: false,
          error: errorData['message'] ?? 'Failed to load progress data',
          message: 'Failed to load progress data',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      print('Error in getUserProgress: $e');
      return ApiResponse(
        success: false,
        error: e.toString(),
        message: 'Failed to load progress data',
        statusCode: 500,
      );
    }
  }

  // Get progress by ID
  Future<ApiResponse<Progress>> getProgressById(String id) async {
    final response = await _apiClient.get<Progress>(
      'api/progress/$id',
      (json) => Progress.fromJson(json),
    );
    return ApiResponse(
      success: true,
      data: response.data,
      message: 'Progress loaded successfully',
      statusCode: 200,
    );
  }

  // Create a new progress tracking
  Future<ApiResponse<Progress>> createProgress(
    String skillId,
    String goal,
    DateTime? targetDate,
    List<Map<String, dynamic>>? milestones,
  ) async {
    final response = await _apiClient.post<Progress>(
        'api/progress',
        {
          'skillId': skillId,
          'goal': goal,
          'targetDate': targetDate?.toIso8601String(),
          'milestones': milestones,
        },
        (json) => Progress.fromJson(json));
    return ApiResponse(
      success: true,
      data: response.data,
      message: 'Progress created successfully',
      statusCode: 201,
    );
  }

  // Update progress
  Future<ApiResponse<Progress>> updateProgress(
    String id,
    String? goal,
    DateTime? targetDate,
    int? progress,
  ) async {
    final response = await _apiClient.put<Progress>(
        'api/progress/$id',
        {
          if (goal != null) 'goal': goal,
          if (targetDate != null) 'targetDate': targetDate.toIso8601String(),
          if (progress != null) 'progress': progress,
        },
        (json) => Progress.fromJson(json));
    return ApiResponse(
      success: true,
      data: response.data,
      message: 'Progress updated successfully',
      statusCode: 200,
    );
  }

  // Delete progress
  Future<ApiResponse<Map<String, dynamic>>> deleteProgress(String id) async {
    final response = await _apiClient.delete<Map<String, dynamic>>(
      'api/progress/$id',
      (json) => json as Map<String, dynamic>,
    );
    return ApiResponse(
      success: true,
      data: response.data,
      message: 'Progress deleted successfully',
      statusCode: 200,
    );
  }

  // Add milestone to progress
  Future<ApiResponse<List<Milestone>>> addMilestone(
    String id,
    String title,
    String? description,
  ) async {
    final response = await _apiClient.post<List<Milestone>>(
      'api/progress/$id/milestone',
      {'title': title, 'description': description},
      (json) => (json as List).map((x) => Milestone.fromJson(x)).toList(),
    );
    return ApiResponse(
      success: true,
      data: response.data,
      message: 'Milestone added successfully',
      statusCode: 200,
    );
  }

  // Update milestone
  Future<ApiResponse<List<Milestone>>> updateMilestone(
    String progressId,
    String milestoneId,
    String? title,
    String? description,
    bool? completed,
  ) async {
    final response = await _apiClient.put<List<Milestone>>(
      'api/progress/$progressId/milestone/$milestoneId',
      {
        if (title != null) 'title': title,
        if (description != null) 'description': description,
        if (completed != null) 'completed': completed,
      },
      (json) => (json as List).map((x) => Milestone.fromJson(x)).toList(),
    );
    return ApiResponse(
      success: true,
      data: response.data,
      message: 'Milestone updated successfully',
      statusCode: 200,
    );
  }

  Future<Map<String, dynamic>> getGoals() async {
    try {
      final token = await TokenStorage.getToken();
      if (token == null) {
        print('[DEBUG] No token found for goals request');
        return {
          'success': false,
          'error': 'Not authenticated',
        };
      }

      print('[DEBUG] Fetching goals from: $baseUrl/api/progress/goals');
      final response = await http.get(
        Uri.parse('$baseUrl/api/progress/goals'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('[DEBUG] Goals response status: ${response.statusCode}');
      print('[DEBUG] Goals response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('[DEBUG] Decoded goals data: $data');
        return {
          'success': true,
          'data': (data['data'] as List)
              .map((goal) => GoalModel.fromJson(goal))
              .toList(),
        };
      } else {
        print('[DEBUG] Failed to load goals: ${response.statusCode}');
        return {
          'success': false,
          'error': 'Failed to load goals',
        };
      }
    } catch (e) {
      print('[DEBUG] Error fetching goals: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  Future<Map<String, dynamic>> createGoal({
    required String skillId,
    required DateTime targetDate,
  }) async {
    try {
      final token = await TokenStorage.getToken();
      if (token == null) {
        return {
          'success': false,
          'error': 'Not authenticated',
        };
      }

      final response = await http.post(
        Uri.parse('$baseUrl/api/progress/goals'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'skill': skillId,
          'targetDate': targetDate.toIso8601String(),
        }),
      );

      print("🔥 RAW response body: ${response.body}");
      print("🔥 Status Code: ${response.statusCode}");

      if (response.statusCode == 201) {
        try {
          final decoded = json.decode(response.body);
          print("🔥 Decoded: $decoded (${decoded.runtimeType})");
          print(
              "💡 Decoded[\'data\'] runtimeType: ${decoded['data'].runtimeType}");
          return {
            'success': true,
            'data': GoalModel.fromJson(decoded['data']),
          };
        } catch (e) {
          print("❌ JSON decode error: $e");
          return {
            'success': false,
            'error': e.toString(),
          };
        }
      } else {
        return {
          'success': false,
          'error': 'Failed to create goal',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  Future<Map<String, dynamic>> updateGoal({
    required String goalId,
    required double currentProgress,
  }) async {
    try {
      final token = await TokenStorage.getToken();
      if (token == null) {
        return {
          'success': false,
          'error': 'Not authenticated',
        };
      }

      final response = await http.put(
        Uri.parse('$baseUrl/api/progress/goals/$goalId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'currentProgress': currentProgress,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data == null) {
          return {
            'success': false,
            'error': 'Invalid response from server',
          };
        }
        return {
          'success': true,
          'data': GoalModel.fromJson(data['data']),
        };
      } else {
        final errorData = json.decode(response.body);
        return {
          'success': false,
          'error': errorData['message'] ?? 'Failed to update goal',
        };
      }
    } catch (e) {
      print('[ERROR] Failed to update goal: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  Future<Map<String, dynamic>> getAnalytics() async {
    try {
      final token = await TokenStorage.getToken();
      if (token == null) {
        return {
          'success': false,
          'error': 'Not authenticated',
        };
      }

      final response = await http.get(
        Uri.parse('$baseUrl/api/progress/analytics'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'data': data['data'],
        };
      } else {
        return {
          'success': false,
          'error': 'Failed to load analytics',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // Mark a resource as completed
  Future<ApiResponse<void>> markResourceComplete(
      String skillId, String resourceId) async {
    try {
      final token = await TokenStorage.getToken();
      if (token == null) {
        return ApiResponse(
          success: false,
          error: 'Not authenticated',
          message: 'Authentication required',
          statusCode: 401,
        );
      }

      final response = await http.post(
        Uri.parse('$baseUrl/api/progress/$skillId/complete-resource'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'resourceId': resourceId,
        }),
      );

      if (response.statusCode == 200) {
        return ApiResponse(
          success: true,
          data: null,
          message: 'Resource marked as completed',
          statusCode: 200,
        );
      } else {
        final data = json.decode(response.body);
        return ApiResponse(
          success: false,
          error: data['message'] ?? 'Failed to mark resource as completed',
          message: 'Failed to mark resource as completed',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse(
        success: false,
        error: e.toString(),
        message: 'Failed to mark resource as completed',
        statusCode: 500,
      );
    }
  }

  // Unmark a resource as completed
  Future<ApiResponse<void>> unmarkResourceComplete(
      String skillId, String resourceId) async {
    try {
      final token = await TokenStorage.getToken();
      if (token == null) {
        return ApiResponse(
          success: false,
          error: 'Not authenticated',
          message: 'Authentication required',
          statusCode: 401,
        );
      }

      // Corrected API call to use DELETE and the actual backend endpoint
      final response = await _apiClient.delete<void>(
        'api/progress/$skillId/complete-resource/$resourceId',
        (json) => null, // Assuming the response body is not needed
      );

      return response;
    } catch (e) {
      print('Error unmarking resource as completed: $e');
      return ApiResponse(
        success: false,
        error: e.toString(),
        message: 'Failed to unmark resource as completed',
        statusCode: 500,
      );
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> getProgress() async {
    try {
      final token = await TokenStorage.getToken();
      if (token == null) {
        return ApiResponse(
          success: false,
          error: 'Not authenticated',
          message: 'Authentication required',
          statusCode: 401,
        );
      }

      final response = await http.get(
        Uri.parse('$baseUrl/api/progress'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return ApiResponse(
          success: true,
          data: data,
          message: 'Progress data loaded successfully',
          statusCode: 200,
        );
      } else {
        final errorData = json.decode(response.body);
        return ApiResponse(
          success: false,
          error: errorData['message'] ?? 'Failed to load progress data',
          message: 'Failed to load progress data',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      print('Error in getProgress: $e');
      return ApiResponse(
        success: false,
        error: e.toString(),
        message: 'Failed to load progress data',
        statusCode: 500,
      );
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> fetchSkillProgress(
      String skillId) async {
    try {
      final token = await TokenStorage.getToken();
      if (token == null) {
        return ApiResponse(
          success: false,
          error: 'Not authenticated',
          message: 'Authentication required',
          statusCode: 401,
        );
      }

      print('[DEBUG] Fetching skill progress for skillId: $skillId');
      final response = await _apiClient.get<Map<String, dynamic>>(
        'api/progress/skill/$skillId',
        (json) => json, // Pass through the raw JSON
      );

      print('[DEBUG] Response status code: ${response.statusCode}');
      print('[DEBUG] Response data runtimeType: ${response.data.runtimeType}');
      print('[DEBUG] Response data content: ${jsonEncode(response.data)}');

      if (response.statusCode == 200 && response.data != null) {
        // Use direct type casting since response.data is already a Map
        final data = response.data as Map<String, dynamic>;

        return ApiResponse(
          success: true,
          data: data,
          error: null,
          message: 'Skill progress loaded successfully',
          statusCode: 200,
        );
      }

      return ApiResponse(
        success: false,
        data: null,
        error: 'Unexpected response format',
        message: 'Failed to fetch skill progress',
        statusCode: response.statusCode ?? 500,
      );
    } catch (e, st) {
      print('[DEBUG] Error in fetchSkillProgress: $e\n$st');
      return ApiResponse(
        success: false,
        error: e.toString(),
        message: 'Failed to fetch skill progress',
        statusCode: 500,
      );
    }
  }
}
