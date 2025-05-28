import '../models/chat_message_model.dart';
import '../utils/api_response.dart';
import 'api_client.dart';
import '../config/app_config.dart';

class ChatService {
  final ApiClient _apiClient;

  ChatService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient(baseUrl: AppConfig.apiBaseUrl);

  // Get chat history with a friend
  Future<ApiResponse<List<ChatMessage>>> getChatHistory(String friendId) async {
    try {
      final response = await _apiClient.get<List<ChatMessage>>(
        'api/social/chat/$friendId',
        (json) => (json as List).map((x) => ChatMessage.fromJson(x)).toList(),
      );
      return response;
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }

  // Send a message to a friend
  Future<ApiResponse<ChatMessage>> sendMessage(
      String friendId, String content) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        'api/social/chat/$friendId',
        {'content': content},
        (json) => json as Map<String, dynamic>,
      );

      if (response.success && response.data != null) {
        final messageData = response.data!['data'];
        if (messageData != null) {
          return ApiResponse.success(
            data: ChatMessage.fromJson(messageData),
            message: response.data!['message'] ?? 'Message sent successfully',
          );
        }
      }
      return ApiResponse.error(response.message ?? 'Failed to send message');
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }

  // Mark messages as read
  Future<ApiResponse<void>> markMessagesAsRead(String friendId) async {
    try {
      final response = await _apiClient.put<void>(
        'api/social/chat/$friendId/read',
        {},
        (json) => null,
      );
      return response;
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }

  // Delete a message
  Future<ApiResponse<void>> deleteMessage(String messageId) async {
    try {
      final response = await _apiClient.delete<void>(
        'api/social/chat/messages/$messageId',
        (json) => null,
      );
      return response;
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }
}
