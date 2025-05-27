import 'package:skill_sharing_app/utils/api_response.dart';

import '../models/group_model.dart';
import '../models/discussion_model.dart';
import '../models/user_model.dart';
import 'api_client.dart';
import '../config/app_config.dart';

class SocialService {
  final ApiClient _apiClient;

  SocialService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient(baseUrl: AppConfig.apiBaseUrl);

  // Get all groups
  Future<ApiResponse<List<Group>>> getGroups() async {
    final response = await _apiClient.get<List<Group>>(
      'api/social/groups',
      (json) => (json as List).map((x) => Group.fromJson(x)).toList(),
    );
    return ApiResponse(
      success: true,
      data: response.data,
      message: 'Groups loaded successfully',
      statusCode: 200,
    );
  }

  // Get group by ID
  Future<ApiResponse<Group>> getGroupById(String id) async {
    final response = await _apiClient.get<Group>(
      'api/social/groups/$id',
      (json) => Group.fromJson(json),
    );
    return ApiResponse(
      success: true,
      data: response.data,
      message: 'Group loaded successfully',
      statusCode: 200,
    );
  }

  // Create a new group
  Future<ApiResponse<Group>> createGroup(
    String name,
    String description,
    List<String> relatedSkills,
    bool isPublic,
  ) async {
    final response = await _apiClient.post<Group>(
        'api/social/groups',
        {
          'name': name,
          'description': description,
          'relatedSkills': relatedSkills,
          'isPublic': isPublic,
        },
        (json) => Group.fromJson(json));
    return ApiResponse(
      success: true,
      data: response.data,
      message: 'Group created successfully',
      statusCode: 201,
    );
  }

  // Update a group
  Future<ApiResponse<Group>> updateGroup(
    String id,
    String? name,
    String? description,
    List<String>? relatedSkills,
    bool? isPublic,
  ) async {
    final response = await _apiClient.put<Group>(
        'api/social/groups/$id',
        {
          if (name != null) 'name': name,
          if (description != null) 'description': description,
          if (relatedSkills != null) 'relatedSkills': relatedSkills,
          if (isPublic != null) 'isPublic': isPublic,
        },
        (json) => Group.fromJson(json));
    return ApiResponse(
      success: true,
      data: response.data,
      message: 'Group updated successfully',
      statusCode: 200,
    );
  }

  // Join a group
  Future<ApiResponse<Map<String, dynamic>>> joinGroup(String id) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      'api/social/groups/$id/join',
      {},
      (json) => json as Map<String, dynamic>,
    );
    return ApiResponse(
      success: true,
      data: response.data,
      message: 'Joined group successfully',
      statusCode: 200,
    );
  }

  // Leave a group
  Future<ApiResponse<Map<String, dynamic>>> leaveGroup(String id) async {
    final response = await _apiClient.delete<Map<String, dynamic>>(
      'api/social/groups/$id/leave',
      (json) => json as Map<String, dynamic>,
    );
    return ApiResponse(
      success: true,
      data: response.data,
      message: 'Left group successfully',
      statusCode: 200,
    );
  }

  // Get discussions for a group
  Future<ApiResponse<List<Discussion>>> getGroupDiscussions(
    String groupId,
  ) async {
    final response = await _apiClient.get<List<Discussion>>(
      'api/social/discussions/group/$groupId',
      (json) => (json as List).map((x) => Discussion.fromJson(x)).toList(),
    );
    return ApiResponse(
      success: true,
      data: response.data,
      message: 'Discussions loaded successfully',
      statusCode: 200,
    );
  }

  // Create a new discussion
  Future<ApiResponse<Discussion>> createDiscussion(
    String groupId,
    String title,
    String content,
  ) async {
    final response = await _apiClient.post<Discussion>(
        'api/social/discussions',
        {
          'groupId': groupId,
          'title': title,
          'content': content,
        },
        (json) => Discussion.fromJson(json));
    return ApiResponse(
      success: true,
      data: response.data,
      message: 'Discussion created successfully',
      statusCode: 201,
    );
  }

  // Add a reply to a discussion
  Future<ApiResponse<List<Reply>>> addReply(
    String discussionId,
    String content,
  ) async {
    final response = await _apiClient.post<List<Reply>>(
      'api/social/discussions/$discussionId/reply',
      {'content': content},
      (json) => (json as List).map((x) => Reply.fromJson(x)).toList(),
    );
    return ApiResponse(
      success: true,
      data: response.data,
      message: 'Reply added successfully',
      statusCode: 200,
    );
  }

  // Get user's friends
  Future<ApiResponse<List<User>>> getFriends() async {
    final response = await _apiClient.get<List<User>>(
      'api/social/friends',
      (json) => (json as List).map((x) => User.fromJson(x)).toList(),
    );
    return ApiResponse(
      success: true,
      data: response.data,
      message: 'Friends loaded successfully',
      statusCode: 200,
    );
  }

  // Add a friend
  Future<ApiResponse<Map<String, dynamic>>> addFriend(String userId) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      'api/social/friends/$userId',
      {},
      (json) => json as Map<String, dynamic>,
    );
    return ApiResponse(
      success: true,
      data: response.data,
      message: 'Friend added successfully',
      statusCode: 200,
    );
  }

  // Remove a friend
  Future<ApiResponse<Map<String, dynamic>>> removeFriend(String userId) async {
    final response = await _apiClient.delete<Map<String, dynamic>>(
      'api/social/friends/$userId',
      (json) => json as Map<String, dynamic>,
    );
    return ApiResponse(
      success: true,
      data: response.data,
      message: 'Friend removed successfully',
      statusCode: 200,
    );
  }
}
