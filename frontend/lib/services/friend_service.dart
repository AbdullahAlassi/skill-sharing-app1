import '../models/user_model.dart';
import '../models/friend_request.dart';
import '../utils/api_response.dart';
import 'api_client.dart';
import '../config/app_config.dart';

class FriendService {
  final ApiClient _apiClient;

  FriendService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient(baseUrl: AppConfig.apiBaseUrl);

  // Get all friends
  Future<ApiResponse<List<User>>> getFriends() async {
    try {
      final response = await _apiClient.get<List<dynamic>>(
        'api/social/friends',
        (json) => (json as List<dynamic>)
            .map((item) => User.fromJson(item as Map<String, dynamic>))
            .toList(),
      );
      return ApiResponse(
        success: response.success,
        data: response.data?.cast<User>() ?? [],
        message: response.message,
      );
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }

  // Get friend requests
  Future<ApiResponse<FriendRequestResponse>> getFriendRequests() async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        'api/social/friend-requests',
        (json) => json as Map<String, dynamic>,
      );

      if (response.success && response.data != null) {
        final friendRequestResponse =
            FriendRequestResponse.fromJson(response.data!);
        return ApiResponse(
          success: true,
          data: friendRequestResponse,
          message: 'Friend requests loaded successfully',
        );
      }
      return ApiResponse.error(
          response.message ?? 'Failed to load friend requests');
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }

  // Send friend request
  Future<ApiResponse<FriendRequest>> sendFriendRequest(String userId) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        'api/social/send-request',
        {'receiverId': userId},
        (json) => json as Map<String, dynamic>,
      );

      if (response.success && response.data != null) {
        final friendRequestData = response.data!['friendRequest'];
        if (friendRequestData != null) {
          return ApiResponse.success(
              data: FriendRequest.fromJson(friendRequestData),
              message: response.data!['message'] ??
                  'Friend request sent successfully');
        }
      }
      return ApiResponse.error(
          response.message ?? 'Failed to send friend request');
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }

  // Accept friend request
  Future<ApiResponse<FriendRequest>> acceptFriendRequest(
      String requestId) async {
    try {
      final response = await _apiClient.put<FriendRequest>(
        'api/social/friend-requests/$requestId/accept',
        {},
        (json) => FriendRequest.fromJson(json),
      );
      return response;
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }

  // Reject friend request
  Future<ApiResponse<FriendRequest>> rejectFriendRequest(
      String requestId) async {
    try {
      final response = await _apiClient.put<FriendRequest>(
        'api/social/friend-requests/$requestId/reject',
        {},
        (json) => FriendRequest.fromJson(json),
      );
      return response;
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }

  // Remove friend
  Future<ApiResponse<Map<String, dynamic>>> removeFriend(String userId) async {
    try {
      final response = await _apiClient.delete<Map<String, dynamic>>(
        'api/social/friends/$userId',
        (json) => json as Map<String, dynamic>,
      );
      return response;
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }

  // Search users
  Future<ApiResponse<List<User>>> searchUsers(String query) async {
    try {
      print('\n=== FriendService.searchUsers Debug ===');
      print('Query: $query');

      final response = await _apiClient.get<List<dynamic>>(
        'api/social/users/search?q=$query',
        (json) {
          if (json is! List) {
            throw Exception(
                'Expected list in searchUsers but got ${json.runtimeType}');
          }

          return json.map<User>((item) {
            if (item is! Map<String, dynamic>) {
              throw Exception('Item is not a map: ${item.runtimeType}');
            }

            // Convert _id to id for User.fromJson
            final userData = Map<String, dynamic>.from(item);
            if (userData.containsKey('_id')) {
              userData['id'] = userData['_id'];
              userData.remove('_id');
            }

            final user = User.fromJson(userData);
            print('✅ Created User: ${user.name} (${user.id})');
            return user;
          }).toList();
        },
      );

      print('\n✅ Final users list: ${response.data?.length}');
      return ApiResponse<List<User>>(
        success: response.success,
        data: response.data
            ?.map((item) => User.fromJson(item as Map<String, dynamic>))
            .toList(),
        message: response.message,
      );
    } catch (e, stackTrace) {
      print('\n❌ Error in searchUsers: $e');
      print('StackTrace: $stackTrace');
      return ApiResponse.error(e.toString());
    } finally {
      print('=== End FriendService.searchUsers Debug ===\n');
    }
  }
}
