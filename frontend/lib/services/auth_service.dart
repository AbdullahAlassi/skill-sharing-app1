import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/user_model.dart';
import '../utils/token_storage.dart';
import 'api_client.dart';

class AuthService {
  final ApiClient _apiClient;
  final String baseUrl;

  AuthService({ApiClient? apiClient, required String baseUrl})
      : _apiClient = apiClient ?? ApiClient(),
        baseUrl = baseUrl;

  // Register a new user
  Future<ApiResponse<Map<String, dynamic>>> register(
    String name,
    String email,
    String password,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConfig.apiBaseUrl}/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'name': name, 'email': email, 'password': password}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        // Save token and user ID
        await TokenStorage.saveToken(data['token'], data['user']['id']);
        return ApiResponse(
          success: true,
          data: data,
          statusCode: response.statusCode,
        );
      } else {
        return ApiResponse(
          success: false,
          error: data['message'] ?? 'Registration failed',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse(success: false, error: e.toString(), statusCode: 0);
    }
  }

  // Login user
  Future<ApiResponse<Map<String, dynamic>>> login(
    String email,
    String password,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConfig.apiBaseUrl}/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // Save token and user ID
        await TokenStorage.saveToken(data['token'], data['user']['id']);
        return ApiResponse(
          success: true,
          data: data,
          statusCode: response.statusCode,
        );
      } else {
        return ApiResponse(
          success: false,
          error: data['message'] ?? 'Login failed',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse(success: false, error: e.toString(), statusCode: 0);
    }
  }

  // Get current user
  Future<ApiResponse<User>> getCurrentUser() async {
    try {
      final token = await TokenStorage.getToken();
      if (token == null) {
        return ApiResponse(
          success: false,
          error: 'No authentication token found',
          statusCode: 401,
        );
      }

      final response = await http.get(
        Uri.parse('$baseUrl/users/me'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('Current User API Response Status: ${response.statusCode}');
      print('Current User API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final jsonData = json.decode(response.body);
          final user = User.fromJson(jsonData);
          return ApiResponse(
            success: true,
            data: user,
            statusCode: response.statusCode,
          );
        } catch (e) {
          print('Error parsing user data: $e');
          return ApiResponse(
            success: false,
            error: 'Failed to parse user data: $e',
            statusCode: response.statusCode,
          );
        }
      } else if (response.statusCode == 401) {
        await TokenStorage.clearToken();
        return ApiResponse(
          success: false,
          error: 'Session expired. Please login again.',
          statusCode: response.statusCode,
        );
      } else {
        try {
          final errorData = json.decode(response.body);
          return ApiResponse(
            success: false,
            error: errorData['message'] ?? 'Failed to fetch user data',
            statusCode: response.statusCode,
          );
        } catch (e) {
          return ApiResponse(
            success: false,
            error: 'Failed to fetch user data: ${response.body}',
            statusCode: response.statusCode,
          );
        }
      }
    } catch (e) {
      print('Error in getCurrentUser: $e');
      return ApiResponse(
        success: false,
        error: 'Failed to fetch user data: $e',
        statusCode: 500,
      );
    }
  }

  // Logout
  Future<void> logout() async {
    await TokenStorage.clearToken();
  }

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    return await TokenStorage.isLoggedIn();
  }
}
