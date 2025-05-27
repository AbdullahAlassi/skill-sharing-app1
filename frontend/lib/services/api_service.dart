import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/chat_message_model.dart';
import '../utils/api_response.dart';

class ApiService {
  final String baseUrl;
  final http.Client _client;

  ApiService({
    required this.baseUrl,
    http.Client? client,
  }) : _client = client ?? http.Client();

  // Get chat history with a friend
  Future<List<ChatMessage>> getChatHistory(String friendId) async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/chat/history/$friendId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => ChatMessage.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load chat history');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  // Send a message to a friend
  Future<ChatMessage> sendMessage(String friendId, String content) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/chat/send'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'friendId': friendId,
          'content': content,
        }),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return ChatMessage.fromJson(data);
      } else {
        throw Exception('Failed to send message');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  // Mark messages as read
  Future<ApiResponse> markMessagesAsRead(String friendId) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/chat/mark-read/$friendId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return ApiResponse(
          success: true,
          message: 'Messages marked as read',
        );
      } else {
        return ApiResponse(
          success: false,
          message: 'Failed to mark messages as read',
        );
      }
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Error: $e',
      );
    }
  }

  // Delete a message
  Future<ApiResponse> deleteMessage(String messageId) async {
    try {
      final response = await _client.delete(
        Uri.parse('$baseUrl/chat/message/$messageId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return ApiResponse(
          success: true,
          message: 'Message deleted successfully',
        );
      } else {
        return ApiResponse(
          success: false,
          message: 'Failed to delete message',
        );
      }
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Error: $e',
      );
    }
  }

  void dispose() {
    _client.close();
  }
}
