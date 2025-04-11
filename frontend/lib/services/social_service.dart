import '../models/group_model.dart';
import '../models/discussion_model.dart';
import '../models/user_model.dart';
import 'api_client.dart';

class SocialService {
  final ApiClient _apiClient;

  SocialService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  // Get all groups
  Future<ApiResponse<List<Group>>> getGroups() async {
    return await _apiClient.get<List<Group>>(
      'social/groups',
      (json, _) => (json as List).map((x) => Group.fromJson(x)).toList(),
    );
  }

  // Get group by ID
  Future<ApiResponse<Group>> getGroupById(String id) async {
    return await _apiClient.get<Group>(
      'social/groups/$id',
      (json, _) => Group.fromJson(json),
    );
  }

  // Create a new group
  Future<ApiResponse<Group>> createGroup(
    String name,
    String description,
    List<String> relatedSkills,
    bool isPublic,
  ) async {
    return await _apiClient.post<Group>('social/groups', {
      'name': name,
      'description': description,
      'relatedSkills': relatedSkills,
      'isPublic': isPublic,
    }, (json, _) => Group.fromJson(json));
  }

  // Update a group
  Future<ApiResponse<Group>> updateGroup(
    String id,
    String? name,
    String? description,
    List<String>? relatedSkills,
    bool? isPublic,
  ) async {
    return await _apiClient.put<Group>('social/groups/$id', {
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (relatedSkills != null) 'relatedSkills': relatedSkills,
      if (isPublic != null) 'isPublic': isPublic,
    }, (json, _) => Group.fromJson(json));
  }

  // Join a group
  Future<ApiResponse<Map<String, dynamic>>> joinGroup(String id) async {
    return await _apiClient.post<Map<String, dynamic>>(
      'social/groups/$id/join',
      {},
      (json, _) => json as Map<String, dynamic>,
    );
  }

  // Leave a group
  Future<ApiResponse<Map<String, dynamic>>> leaveGroup(String id) async {
    return await _apiClient.delete<Map<String, dynamic>>(
      'social/groups/$id/leave',
      (json, _) => json as Map<String, dynamic>,
    );
  }

  // Get discussions for a group
  Future<ApiResponse<List<Discussion>>> getGroupDiscussions(
    String groupId,
  ) async {
    return await _apiClient.get<List<Discussion>>(
      'social/discussions/group/$groupId',
      (json, _) => (json as List).map((x) => Discussion.fromJson(x)).toList(),
    );
  }

  // Create a new discussion
  Future<ApiResponse<Discussion>> createDiscussion(
    String groupId,
    String title,
    String content,
  ) async {
    return await _apiClient.post<Discussion>('social/discussions', {
      'groupId': groupId,
      'title': title,
      'content': content,
    }, (json, _) => Discussion.fromJson(json));
  }

  // Add a reply to a discussion
  Future<ApiResponse<List<Reply>>> addReply(
    String discussionId,
    String content,
  ) async {
    return await _apiClient.post<List<Reply>>(
      'social/discussions/$discussionId/reply',
      {'content': content},
      (json, _) => (json as List).map((x) => Reply.fromJson(x)).toList(),
    );
  }

  // Get user's friends
  Future<ApiResponse<List<User>>> getFriends() async {
    return await _apiClient.get<List<User>>(
      'social/friends',
      (json, _) => (json as List).map((x) => User.fromJson(x)).toList(),
    );
  }

  // Add a friend
  Future<ApiResponse<Map<String, dynamic>>> addFriend(String userId) async {
    return await _apiClient.post<Map<String, dynamic>>(
      'social/friends/$userId',
      {},
      (json, _) => json as Map<String, dynamic>,
    );
  }

  // Remove a friend
  Future<ApiResponse<Map<String, dynamic>>> removeFriend(String userId) async {
    return await _apiClient.delete<Map<String, dynamic>>(
      'social/friends/$userId',
      (json, _) => json as Map<String, dynamic>,
    );
  }
}
