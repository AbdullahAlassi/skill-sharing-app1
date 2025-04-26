import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/user_model.dart';
import '../utils/token_storage.dart';
import 'api_client.dart';

class AuthService {
  final ApiClient _apiClient;
  final String baseUrl;
  static const Duration _timeoutDuration = Duration(seconds: 10);

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
        print('Token saved successfully');
        return ApiResponse(
          success: true,
          data: data,
          statusCode: response.statusCode,
        );
      } else {
        print('Login failed: ${data['message']}');
        return ApiResponse(
          success: false,
          error: data['message'] ?? 'Login failed',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      print('Login error: $e');
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

  // Validate token
  Future<ApiResponse<User>> validateToken(String token) async {
    try {
      print('Validating token with backend...');
      print('Base URL: $baseUrl');

      // First try to connect to the server using a known endpoint
      try {
        final testResponse = await http.get(
          Uri.parse(
              '$baseUrl/api/events'), // Using events endpoint as health check
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ).timeout(const Duration(seconds: 3));

        if (testResponse.statusCode == 401) {
          print('Token is invalid or expired');
          return ApiResponse(
            success: false,
            error: 'Token is invalid or expired',
            statusCode: 401,
          );
        } else if (testResponse.statusCode != 200) {
          print('Server check failed: ${testResponse.statusCode}');
          return ApiResponse(
            success: false,
            error: 'Server is not responding properly',
            statusCode: testResponse.statusCode,
          );
        }
      } catch (e) {
        print('Server connection test failed: $e');
        return ApiResponse(
          success: false,
          error:
              'Could not connect to the server. Please check if the backend server is running.',
          statusCode: 503,
        );
      }

      // If we get here, the server is responding and the token is valid
      // Get the current user data
      final response = await http.get(
        Uri.parse('$baseUrl/api/users/me'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 5));

      print('User data response status: ${response.statusCode}');
      print('User data response body: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final userData = json.decode(response.body);
          final user = User.fromJson(userData);
          return ApiResponse(
            success: true,
            data: user,
            statusCode: response.statusCode,
          );
        } catch (e) {
          print('Error parsing user data: $e');
          return ApiResponse(
            success: false,
            error: 'Failed to parse user data',
            statusCode: response.statusCode,
          );
        }
      } else {
        print('Unexpected response status: ${response.statusCode}');
        return ApiResponse(
          success: false,
          error: 'Failed to get user data',
          statusCode: response.statusCode,
        );
      }
    } on TimeoutException {
      print('Server connection timed out');
      return ApiResponse(
        success: false,
        error:
            'Could not connect to the server. Please check if the backend server is running and accessible.',
        statusCode: 408,
      );
    } catch (e) {
      print('Error validating token: $e');
      return ApiResponse(
        success: false,
        error:
            'Failed to connect to the server. Please check your internet connection and ensure the backend server is running.',
        statusCode: 500,
      );
    }
  }
}
