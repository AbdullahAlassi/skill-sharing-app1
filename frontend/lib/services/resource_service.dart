import '../models/resource_model.dart';
import 'api_client.dart';
import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../config/app_config.dart';
import '../utils/token_storage.dart';
import '../utils/api_response.dart';

class ResourceService {
  final ApiClient _apiClient = ApiClient(baseUrl: AppConfig.apiBaseUrl);
  final Duration _timeoutDuration = Duration(seconds: 10);

  ResourceService();

  // Get all resources
  Future<ApiResponse<List<Resource>>> getResources(
      {String? type, String? sort}) async {
    try {
      final queryParams = <String, String>{};
      if (type != null) queryParams['type'] = type;
      if (sort != null) queryParams['sort'] = sort;

      final response = await _apiClient.get<Map<String, dynamic>>(
        'api/resources',
        (json) => json,
      );

      if (response.data != null && response.data!['resources'] != null) {
        final resources = (response.data!['resources'] as List)
            .map((x) => Resource.fromJson(x))
            .toList();
        return ApiResponse(
          success: true,
          data: resources,
          message: 'Resources loaded successfully',
          statusCode: 200,
        );
      } else {
        return ApiResponse(
          success: false,
          error: 'No resources found',
          message: 'No resources available',
          statusCode: 404,
        );
      }
    } catch (e) {
      print('Error in getResources: $e');
      return ApiResponse(
        success: false,
        error: e.toString(),
        message: 'Failed to load resources',
        statusCode: 500,
      );
    }
  }

  // Get resource by ID
  Future<ApiResponse<Resource>> getResourceById(String id) async {
    final response = await _apiClient.get<Resource>(
      'api/resources/$id',
      (json) => Resource.fromJson(json),
    );
    return ApiResponse(
      success: true,
      data: response.data,
      message: 'Resource loaded successfully',
      statusCode: 200,
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
    try {
      final response = await _apiClient.post<Resource>(
          'api/resources',
          {
            'title': title,
            'description': description,
            'link': link,
            'type': type,
            'skill': skillId,
            'category': 'Learning',
          },
          (json) => Resource.fromJson(json));
      return ApiResponse(
        success: true,
        data: response.data,
        message: 'Resource created successfully',
        statusCode: 201,
      );
    } catch (e) {
      print('Error creating resource: $e');
      return ApiResponse(
        success: false,
        error: e.toString(),
        message: 'Failed to create resource',
        statusCode: 500,
      );
    }
  }

  // Upload a resource file
  Future<ApiResponse<Resource>> uploadResource({
    required String title,
    required String description,
    required String type,
    required String skillId,
    required File file,
  }) async {
    try {
      final token = await TokenStorage.getToken();
      if (token == null) {
        return Future.value(ApiResponse(
          success: false,
          error: 'Not authenticated',
          message: 'Authentication required',
          statusCode: 401,
        ));
      }

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${_apiClient.baseUrl}/api/resources'),
      );

      // Add file
      final fileStream = http.ByteStream(file.openRead());
      final fileLength = await file.length();
      final contentType = type.toLowerCase() == 'image'
          ? MediaType('image', 'jpeg')
          : type.toLowerCase() == 'video'
              ? MediaType('video', 'mp4')
              : type.toLowerCase() == 'pdf'
                  ? MediaType('application', 'pdf')
                  : MediaType('application', 'octet-stream');
      final multipartFile = http.MultipartFile(
        'file',
        fileStream,
        fileLength,
        filename: file.path.split('/').last,
        contentType: contentType,
      );
      request.files.add(multipartFile);

      // Add other fields
      request.fields['title'] = title;
      request.fields['description'] = description;
      request.fields['type'] = type;
      request.fields['skill'] = skillId;
      request.fields['category'] = 'Learning';
      request.fields['link'] = '';

      // Add auth header
      request.headers['Authorization'] = 'Bearer $token';

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonData = jsonDecode(response.body);
        final resource = Resource.fromJson(jsonData);
        return Future.value(ApiResponse(
          success: true,
          data: resource,
          message: 'Resource uploaded successfully',
          statusCode: response.statusCode,
        ));
      }

      return Future.value(ApiResponse(
        success: false,
        error: response.body,
        message: 'Failed to upload resource',
        statusCode: response.statusCode,
      ));
    } catch (e) {
      return Future.value(ApiResponse(
        success: false,
        error: e.toString(),
        message: 'Failed to upload resource',
        statusCode: 500,
      ));
    }
  }

  // Update a resource
  Future<ApiResponse<Resource>> updateResource(
    String id,
    String title,
    String description,
    String link,
    String type,
  ) async {
    final response = await _apiClient.put<Resource>(
        'api/resources/$id',
        {
          'title': title,
          'description': description,
          'link': link,
          'type': type,
        },
        (json) => Resource.fromJson(json));
    return ApiResponse(
      success: true,
      data: response.data,
      message: 'Resource updated successfully',
      statusCode: 200,
    );
  }

  // Delete a resource
  Future<ApiResponse<void>> deleteResource(String id) async {
    try {
      await _apiClient.delete<void>(
        'api/resources/$id',
        (json) => null,
      );
      return ApiResponse(
        success: true,
        data: null,
        message: 'Resource deleted successfully',
        statusCode: 200,
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        error: e.toString(),
        message: 'Failed to delete resource',
        statusCode: 500,
      );
    }
  }

  // Get resources by skill ID
  Future<ApiResponse<List<Resource>>> getResourcesBySkill(
      String skillId) async {
    try {
      final response = await _apiClient
          .get<List<Resource>>('api/resources/skill/$skillId', (json) {
        if (json is String) {
          final parsedJson = jsonDecode(json);
          if (parsedJson is List) {
            return parsedJson.map((x) => Resource.fromJson(x)).toList();
          }
        } else if (json is List) {
          return json.map((x) => Resource.fromJson(x)).toList();
        }
        return [];
      }).timeout(_timeoutDuration);

      if (response.data != null) {
        print('Resources loaded for skill $skillId: ${response.data!.length}');
        return ApiResponse(
          success: true,
          data: response.data,
          message: 'Resources loaded successfully',
          statusCode: 200,
        );
      } else {
        print('No resources found for skill $skillId');
        return ApiResponse(
          success: false,
          error: 'No resources found',
          message: 'No resources found for this skill',
          statusCode: 404,
        );
      }
    } on TimeoutException {
      print('Timeout while loading resources for skill $skillId');
      return ApiResponse(
        success: false,
        error: 'Request timed out',
        message: 'Request timed out. Please try again.',
        statusCode: 408,
      );
    } catch (e) {
      print('Error in getResourcesBySkill for skill $skillId: $e');
      return ApiResponse(
        success: false,
        error: e.toString(),
        message: 'Failed to load resources',
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
    final response = await _apiClient.post<List<Review>>(
      'api/esources/$id/review',
      {'rating': rating, 'comment': comment},
      (json) => (json as List).map((x) => Review.fromJson(x)).toList(),
    );
    return ApiResponse(
      success: true,
      data: response.data,
      message: 'Review added successfully',
      statusCode: 200,
    );
  }

  // Flag a resource for moderation
  Future<ApiResponse<Resource>> flagResource(String id) async {
    try {
      final response = await _apiClient.put<Resource>(
        'api/resources/$id/flag',
        {},
        (json) => Resource.fromJson(json),
      );
      return ApiResponse(
        success: true,
        data: response.data,
        message: 'Resource flagged successfully',
        statusCode: 200,
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        error: e.toString(),
        message: 'Failed to flag resource',
        statusCode: 500,
      );
    }
  }

  Future<ApiResponse<void>> forceDeleteResource(String id) async {
    try {
      await _apiClient.delete<void>(
        'api/resources/$id/force',
        (json) => null,
      );
      return ApiResponse(
        success: true,
        data: null,
        message: 'Resource deleted successfully',
        statusCode: 200,
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        error: e.toString(),
        message: 'Failed to delete resource',
        statusCode: 500,
      );
    }
  }

  // Get reviews for a resource
  Future<ApiResponse<List<Review>>> getReviews(String resourceId) async {
    try {
      final response = await _apiClient.get<List<Review>>(
        'api/resources/$resourceId/reviews',
        (json) => (json as List).map((x) => Review.fromJson(x)).toList(),
      );
      return ApiResponse(
        success: true,
        data: response.data,
        message: 'Reviews loaded successfully',
        statusCode: 200,
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        error: e.toString(),
        message: 'Failed to load reviews',
        statusCode: 500,
      );
    }
  }

  // Submit a review for a resource
  Future<ApiResponse<Review>> submitReview(
    String resourceId,
    int rating,
    String comment,
  ) async {
    try {
      final response = await _apiClient.post<Review>(
        'api/resources/$resourceId/reviews',
        {
          'rating': rating,
          'comment': comment,
        },
        (json) => Review.fromJson(json),
      );
      return ApiResponse(
        success: true,
        data: response.data,
        message: 'Review submitted successfully',
        statusCode: 201,
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        error: e.toString(),
        message: 'Failed to submit review',
        statusCode: 500,
      );
    }
  }

  // Get recommended resources
  Future<ApiResponse<List<Resource>>> getRecommendedResources() async {
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
        Uri.parse('${_apiClient.baseUrl}/api/resources/recommended'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) {
          final resources =
              data.map((item) => Resource.fromJson(item)).toList();
          return ApiResponse(
            success: true,
            data: resources,
            message: 'Recommended resources loaded successfully',
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
          error: data['message'] ?? 'Failed to get recommended resources',
          message: 'Failed to get recommended resources',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse(
        success: false,
        error: e.toString(),
        message: 'Failed to get recommended resources',
        statusCode: 0,
      );
    }
  }

  // Get resources by user's skills
  Future<ApiResponse<List<Resource>>> getResourcesByUserSkills({
    String? type,
    String? sort,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (type != null) queryParams['type'] = type;
      if (sort != null) queryParams['sort'] = sort;

      final queryString = queryParams.entries
          .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
          .join('&');
      final endpoint =
          'api/resources/user-skills${queryString.isNotEmpty ? '?$queryString' : ''}';

      final response = await _apiClient.get<dynamic>(
        endpoint,
        (json) {
          // Safely handle the response whether it's a List or something else
          if (json is List) {
            return json.map((x) => Resource.fromJson(x)).toList();
          } else {
            print(
                '[ERROR] Unexpected response format for user-skills: ${json.runtimeType}');
            return []; // Return empty list for unexpected format
          }
        },
      ).timeout(_timeoutDuration);

      if (response.data != null) {
        return ApiResponse<List<Resource>>(
          success: true,
          data: List<Resource>.from(response.data),
          message: 'Resources loaded successfully',
          statusCode: 200,
        );
      } else {
        return ApiResponse<List<Resource>>(
          success: false,
          error: 'No resources found',
          message: 'No resources available',
          statusCode: 404,
        );
      }
    } on TimeoutException {
      return ApiResponse<List<Resource>>(
        success: false,
        error: 'Request timed out',
        message: 'Request timed out. Please try again.',
        statusCode: 408,
      );
    } catch (e) {
      print('Error in getResourcesByUserSkills: $e');
      return ApiResponse<List<Resource>>(
        success: false,
        error: e.toString(),
        message: 'Failed to load resources',
        statusCode: 500,
      );
    }
  }

  // Get resources by user's created skills
  Future<ApiResponse<List<Resource>>> getResourcesByCreatedSkills({
    String? type,
    String? sort,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (type != null) queryParams['type'] = type;
      if (sort != null) queryParams['sort'] = sort;

      final queryString = queryParams.entries
          .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
          .join('&');
      final endpoint =
          'api/resources/created-skills${queryString.isNotEmpty ? '?$queryString' : ''}';

      final response = await _apiClient.get<dynamic>(
        endpoint,
        (json) {
          // Safely handle the response whether it's a List or something else
          if (json is List) {
            return json.map((x) => Resource.fromJson(x)).toList();
          } else {
            print(
                '[ERROR] Unexpected response format for created-skills: ${json.runtimeType}');
            return []; // Return empty list for unexpected format
          }
        },
      ).timeout(_timeoutDuration);

      if (response.data != null) {
        return ApiResponse<List<Resource>>(
          success: true,
          data: List<Resource>.from(response.data),
          message: 'Resources loaded successfully',
          statusCode: 200,
        );
      } else {
        return ApiResponse<List<Resource>>(
          success: false,
          error: 'No resources found',
          message: 'No resources available',
          statusCode: 404,
        );
      }
    } on TimeoutException {
      return ApiResponse<List<Resource>>(
        success: false,
        error: 'Request timed out',
        message: 'Request timed out. Please try again.',
        statusCode: 408,
      );
    } catch (e) {
      print('Error in getResourcesByCreatedSkills: $e');
      return ApiResponse<List<Resource>>(
        success: false,
        error: e.toString(),
        message: 'Failed to load resources',
        statusCode: 500,
      );
    }
  }

  Future<ApiResponse<List<Resource>>> getResourcesByFavoriteCategories() async {
    try {
      print('[DEBUG] Getting resources by favorite categories');
      final token = await TokenStorage.getToken();
      if (token == null) {
        print('[DEBUG] No authentication token found');
        return ApiResponse(
            success: false,
            error: 'Not authenticated',
            message: 'Authentication required');
      }
      print('[DEBUG] Authentication token found');

      final url = '${_apiClient.baseUrl}/api/resources/by-user-categories';
      print('[DEBUG] Making request to: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      print('[DEBUG] Response status code: ${response.statusCode}');
      print('[DEBUG] Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('[DEBUG] Parsed response data: $data');

        if (data['success'] == true && data['data'] != null) {
          final List<dynamic> resourcesJson = data['data'];
          print('[DEBUG] Found ${resourcesJson.length} resources in response');

          final resources =
              resourcesJson.map((json) => Resource.fromJson(json)).toList();
          print('[DEBUG] Successfully parsed ${resources.length} resources');

          return ApiResponse(
              success: true,
              data: resources,
              message: 'Resources loaded successfully');
        }
        print('[DEBUG] Response indicates failure or no data');
        return ApiResponse(
            success: false,
            error: data['message'] ?? 'Failed to load resources',
            message: data['message'] ?? 'Failed to load resources');
      }

      print('[DEBUG] Request failed with status code: ${response.statusCode}');
      return ApiResponse(
          success: false,
          error: 'Failed to load resources',
          message: 'Failed to load resources');
    } catch (e) {
      print('[DEBUG] Exception in getResourcesByFavoriteCategories: $e');
      return ApiResponse(
          success: false,
          error: e.toString(),
          message: 'Failed to load resources');
    }
  }
}
