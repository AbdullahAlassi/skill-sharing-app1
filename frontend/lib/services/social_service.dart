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
      (json) => List<Group>.from(json.map((x) => Group.fromJson(x))),
    );
  }

  // Get group by ID
  Future<ApiResponse<Group>> getGroupById(String id) async {
    return await _apiClient.get<Group>(
      'social/groups/$id',
      (json) => Group.fromJson(json),
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
    }, (json) => Group.fromJson(json));
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
    }, (json) => Group.fromJson(json));
  }

  // Join a group
  Future<ApiResponse<Map<String, dynamic>>> joinGroup(String id) async {
    return await _apiClient.post<Map<String, dynamic>>(
      'social/groups/$id/join',
      {},
      (json) => json,
    );
  }

  // Leave a group
  Future<ApiResponse<Map<String, dynamic>>> leaveGroup(String id) async {
    return await _apiClient.delete<Map<String, dynamic>>(
      'social/groups/$id/leave',
      (json) => json,
    );
  }

  // Get discussions for a group
  Future<ApiResponse<List<Discussion>>> getGroupDiscussions(
    String groupId,
  ) async {
    return await _apiClient.get<List<Discussion>>(
      'social/discussions/group/$groupId',
      (json) => List<Discussion>.from(json.map((x) => Discussion.fromJson(x))),
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
    }, (json) => Discussion.fromJson(json));
  }

  // Add a reply to a discussion
  Future<ApiResponse<List<Reply>>> addReply(
    String discussionId,
    String content,
  ) async {
    return await _apiClient.post<List<Reply>>(
      'social/discussions/$discussionId/reply',
      {'content': content},
      (json) => List<Reply>.from(json.map((x) => Reply.fromJson(x))),
    );
  }

  // Get user's friends
  Future<ApiResponse<List<User>>> getFriends() async {
    return await _apiClient.get<List<User>>(
      'social/friends',
      (json) => List<User>.from(json.map((x) => User.fromJson(x))),
    );
  }

  // Add a friend
  Future<ApiResponse<Map<String, dynamic>>> addFriend(String userId) async {
    return await _apiClient.post<Map<String, dynamic>>(
      'social/friends/$userId',
      {},
      (json) => json,
    );
  }

  // Remove a friend
  Future<ApiResponse<Map<String, dynamic>>> removeFriend(String userId) async {
    return await _apiClient.delete<Map<String, dynamic>>(
      'social/friends/$userId',
      (json) => json,
    );
  }
}
