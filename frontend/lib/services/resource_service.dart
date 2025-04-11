import '../models/resource_model.dart';
import 'api_client.dart';
import 'dart:convert';
import 'dart:async';

class ResourceService {
  final ApiClient _apiClient;
  final Duration _timeoutDuration = Duration(seconds: 10);

  ResourceService({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  // Get all resources
  Future<ApiResponse<List<Resource>>> getResources() async {
    return await _apiClient.get<List<Resource>>(
      'resources',
      (json, _) => (json as List).map((x) => Resource.fromJson(x)).toList(),
    );
  }

  // Get resource by ID
  Future<ApiResponse<Resource>> getResourceById(String id) async {
    return await _apiClient.get<Resource>(
      'resources/$id',
      (json, _) => Resource.fromJson(json),
    );
  }

  // Create a new resource
  Future<ApiResponse<Resource>> createResource(
    String title,
    String description,
    String link,
    String type,
    String skillId,
  ) async {
    return await _apiClient.post<Resource>('resources', {
      'title': title,
      'description': description,
      'link': link,
      'type': type,
      'skillId': skillId,
    }, (json, _) => Resource.fromJson(json));
  }

  // Update a resource
  Future<ApiResponse<Resource>> updateResource(
    String id,
    String title,
    String description,
    String link,
    String type,
  ) async {
    return await _apiClient.put<Resource>('resources/$id', {
      'title': title,
      'description': description,
      'link': link,
      'type': type,
    }, (json, _) => Resource.fromJson(json));
  }

  // Delete a resource
  Future<ApiResponse<Map<String, dynamic>>> deleteResource(String id) async {
    return await _apiClient.delete<Map<String, dynamic>>(
      'resources/$id',
      (json, _) => json as Map<String, dynamic>,
    );
  }

  // Get resources by skill ID
  Future<ApiResponse<List<Resource>>> getResourcesBySkill(
    String skillId,
  ) async {
    try {
      final response = await _apiClient
          .get<List<Resource>>('resources/skill/$skillId', (json, _) {
            if (json is String) {
              final parsedJson = jsonDecode(json);
              if (parsedJson is List) {
                return parsedJson.map((x) => Resource.fromJson(x)).toList();
              }
            } else if (json is List) {
              return json.map((x) => Resource.fromJson(x)).toList();
            }
            return [];
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
      print('Error in getResourcesBySkill: $e');
      return ApiResponse(
        success: false,
        error: 'Failed to load resources: ${e.toString()}',
        statusCode: 500,
      );
    }
  }

  // Add a review to a resource
  Future<ApiResponse<List<Review>>> addReview(
    String id,
    int rating,
    String comment,
  ) async {
    return await _apiClient.post<List<Review>>(
      'resources/$id/review',
      {'rating': rating, 'comment': comment},
      (json, _) => (json as List).map((x) => Review.fromJson(x)).toList(),
    );
  }
}
