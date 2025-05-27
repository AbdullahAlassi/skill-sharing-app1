import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/notification_model.dart';
import '../utils/token_storage.dart';

class NotificationService {
  final String baseUrl;
  final http.Client _client;

  NotificationService({
    required this.baseUrl,
    http.Client? client,
  }) : _client = client ?? http.Client();

  Future<Map<String, String>> _getHeaders() async {
    final token = await TokenStorage.getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<List<NotificationModel>> fetchNotifications() async {
    try {
      final headers = await _getHeaders();
      final response = await _client.get(
        Uri.parse('$baseUrl/api/notifications'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final dynamic responseData = json.decode(response.body);

        // Handle both array and object responses
        List<dynamic> notifications;
        if (responseData is List) {
          notifications = responseData;
        } else if (responseData is Map && responseData.containsKey('data')) {
          notifications = responseData['data'] as List;
        } else {
          print('Unexpected response format: $responseData');
          return [];
        }

        return notifications
            .map((json) {
              try {
                return NotificationModel.fromJson(json);
              } catch (e) {
                print('Error parsing notification: $e');
                print('Problematic JSON: $json');
                return null;
              }
            })
            .whereType<NotificationModel>()
            .toList();
      } else {
        print('Failed to fetch notifications. Status: ${response.statusCode}');
        print('Response body: ${response.body}');
        throw Exception('Failed to fetch notifications: ${response.body}');
      }
    } catch (e) {
      print('Error in fetchNotifications: $e');
      throw Exception('Error fetching notifications: $e');
    }
  }

  Future<int> fetchUnreadCount() async {
    try {
      final headers = await _getHeaders();
      final response = await _client.get(
        Uri.parse('$baseUrl/api/notifications/unread/count'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['count'] as int;
      } else {
        throw Exception('Failed to fetch unread count: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error fetching unread count: $e');
    }
  }

  Future<bool> markAsRead(String notificationId) async {
    try {
      final headers = await _getHeaders();
      final response = await _client.patch(
        Uri.parse('$baseUrl/api/notifications/$notificationId/read'),
        headers: headers,
      );

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Error marking notification as read: $e');
    }
  }

  Future<bool> markAllAsRead() async {
    try {
      final headers = await _getHeaders();
      final response = await _client.patch(
        Uri.parse('$baseUrl/api/notifications/read-all'),
        headers: headers,
      );

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Error marking all notifications as read: $e');
    }
  }

  Future<bool> deleteNotification(String notificationId) async {
    try {
      final headers = await _getHeaders();
      final response = await _client.delete(
        Uri.parse('$baseUrl/api/notifications/$notificationId'),
        headers: headers,
      );

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Error deleting notification: $e');
    }
  }

  Future<void> scheduleGoalReminder(dynamic goal) async {
    try {
      final headers = await _getHeaders();
      await _client.post(
        Uri.parse('$baseUrl/api/notifications/goal-reminder'),
        headers: headers,
        body: json.encode(goal.toJson()),
      );
    } catch (e) {
      throw Exception('Error scheduling goal reminder: $e');
    }
  }

  Future<void> cancelGoalReminder(String goalId) async {
    try {
      final headers = await _getHeaders();
      await _client.delete(
        Uri.parse('$baseUrl/api/notifications/goal-reminder/$goalId'),
        headers: headers,
      );
    } catch (e) {
      throw Exception('Error canceling goal reminder: $e');
    }
  }

  void dispose() {
    _client.close();
  }
}
