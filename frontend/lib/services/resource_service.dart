import '../models/resource_model.dart';
import 'api_client.dart';

class ResourceService {
  final ApiClient _apiClient;

  ResourceService({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  // Get all resources
  Future<ApiResponse<List<Resource>>> getResources() async {
    return await _apiClient.get<List<Resource>>(
      'resources',
      (json) => List<Resource>.from(json.map((x) => Resource.fromJson(x))),
    );
  }

  // Get resource by ID
  Future<ApiResponse<Resource>> getResourceById(String id) async {
    return await _apiClient.get<Resource>(
      'resources/$id',
      (json) => Resource.fromJson(json),
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
    }, (json) => Resource.fromJson(json));
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
    }, (json) => Resource.fromJson(json));
  }

  // Delete a resource
  Future<ApiResponse<Map<String, dynamic>>> deleteResource(String id) async {
    return await _apiClient.delete<Map<String, dynamic>>(
      'resources/$id',
      (json) => json,
    );
  }

  // Get resources by skill ID
  Future<ApiResponse<List<Resource>>> getResourcesBySkill(
    String skillId,
  ) async {
    return await _apiClient.get<List<Resource>>(
      'resources/skill/$skillId',
      (json) => List<Resource>.from(json.map((x) => Resource.fromJson(x))),
    );
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
      (json) => List<Review>.from(json.map((x) => Review.fromJson(x))),
    );
  }
}
