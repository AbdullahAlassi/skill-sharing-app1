import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:skill_sharing_app/services/profile_service.dart';
import '../config/app_config.dart';
import '../models/user_model.dart';
import '../utils/token_storage.dart';
import 'api_client.dart';
import '../utils/api_response.dart';

class AuthService {
  final ApiClient _apiClient;

  AuthService(ApiClient apiClient) : _apiClient = apiClient;

  // Register a new user
  Future<ApiResponse<Map<String, dynamic>>> register(
    String name,
    String email,
    String password,
  ) async {
    try {
      print(
          'Making registration request to: ${AppConfig.apiBaseUrl}/api/auth/register');
      final response = await http.post(
        Uri.parse('${AppConfig.apiBaseUrl}/api/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'name': name, 'email': email, 'password': password}),
      );

      print('Registration Response Status: ${response.statusCode}');
      print('Registration Response Body: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Save token and user ID
        await TokenStorage.saveToken(data['token'], data['user']['id']);
        return ApiResponse(
          success: true,
          data: data,
          statusCode: response.statusCode,
          message: 'Registration successful',
        );
      } else {
        try {
          final data = jsonDecode(response.body);
          return ApiResponse(
            success: false,
            error: data['message'] ?? 'Registration failed',
            statusCode: response.statusCode,
            message: 'Registration failed',
          );
        } catch (e) {
          return ApiResponse(
            success: false,
            error: 'Registration failed: ${response.body}',
            statusCode: response.statusCode,
            message: 'Registration failed',
          );
        }
      }
    } catch (e) {
      print('Registration error: $e');
      return ApiResponse(
        success: false,
        error: e.toString(),
        statusCode: 0,
        message: 'Registration failed',
      );
    }
  }

  // Login user
  Future<ApiResponse<Map<String, dynamic>>> login(
    String email,
    String password,
  ) async {
    try {
      print('Making login request to: ${AppConfig.apiBaseUrl}/api/auth/login');
      final response = await http.post(
        Uri.parse('${AppConfig.apiBaseUrl}/api/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      print('Login Response Status: ${response.statusCode}');
      print('Login Response Body: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body);

          // Clear any existing token first
          await TokenStorage.clearToken();

          // Save new token and user ID
          await TokenStorage.saveToken(data['token'], data['user']['id']);
          print('Token saved successfully');

          // Return the initial login data without making an additional API call
          return ApiResponse(
            success: true,
            data: data,
            statusCode: response.statusCode,
            message: 'Login successful',
          );
        } catch (e) {
          print('Error parsing login response: $e');
          return ApiResponse(
            success: false,
            error: 'Failed to parse login response: $e',
            statusCode: response.statusCode,
            message: 'Login failed',
          );
        }
      } else {
        try {
          final data = jsonDecode(response.body);
          print('Login failed: ${data['message']}');
          return ApiResponse(
            message: 'Login failed',
            success: false,
            error: data['message'] ?? 'Login failed',
            statusCode: response.statusCode,
          );
        } catch (e) {
          print('Error parsing error response: $e');
          return ApiResponse(
            message: 'Login failed',
            success: false,
            error: 'Login failed: ${response.body}',
            statusCode: response.statusCode,
          );
        }
      }
    } catch (e) {
      print('Login error: $e');
      return ApiResponse(
        success: false,
        error: e.toString(),
        statusCode: 0,
        message: 'Login failed',
      );
    }
  }

  // Get current user
  Future<ApiResponse<User>> getCurrentUser() async {
    try {
      final token = await TokenStorage.getToken();
      if (token == null) {
        return ApiResponse(
          message: 'No authentication token found',
          success: false,
          error: 'No authentication token found',
          statusCode: 401,
        );
      }

      print(
          'Making getCurrentUser request to: ${AppConfig.apiBaseUrl}/api/users/me');
      final response = await http.get(
        Uri.parse('${AppConfig.apiBaseUrl}/api/users/me'),
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
          print('Parsed JSON data: $jsonData');

          if (jsonData['data'] != null) {
            final user = User.fromJson(jsonData['data']);
            print('Parsed User object: ${user.toJson()}');

            return ApiResponse(
              message: 'User data fetched successfully',
              success: true,
              data: user,
              statusCode: response.statusCode,
            );
          } else {
            print('No user data in response');
            return ApiResponse(
              message: 'No user data in response',
              success: false,
              error: 'No user data in response',
              statusCode: response.statusCode,
            );
          }
        } catch (e) {
          print('Error parsing user data: $e');
          return ApiResponse(
            message: 'Failed to parse user data',
            success: false,
            error: 'Failed to parse user data: $e',
            statusCode: response.statusCode,
          );
        }
      } else if (response.statusCode == 401) {
        await TokenStorage.clearToken();
        return ApiResponse(
          message: 'Session expired. Please login again.',
          success: false,
          error: 'Session expired. Please login again.',
          statusCode: response.statusCode,
        );
      } else {
        try {
          final errorData = json.decode(response.body);
          return ApiResponse(
            message: 'Failed to fetch user data',
            success: false,
            error: errorData['message'] ?? 'Failed to fetch user data',
            statusCode: response.statusCode,
          );
        } catch (e) {
          return ApiResponse(
            message: 'Failed to fetch user data',
            success: false,
            error: 'Failed to fetch user data: ${response.body}',
            statusCode: response.statusCode,
          );
        }
      }
    } catch (e) {
      print('Error in getCurrentUser: $e');
      return ApiResponse(
        message: 'Failed to fetch user data',
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

      // First try to connect to the server using a known endpoint
      try {
        final testResponse = await http.get(
          Uri.parse(
              '${AppConfig.apiBaseUrl}/api/events'), // Using events endpoint as health check
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ).timeout(const Duration(seconds: 3));

        if (testResponse.statusCode == 401) {
          print('Token is invalid or expired');
          return ApiResponse(
            message: 'Token is invalid or expired',
            success: false,
            error: 'Token is invalid or expired',
            statusCode: 401,
          );
        } else if (testResponse.statusCode != 200) {
          print('Server check failed: ${testResponse.statusCode}');
          return ApiResponse(
            message: 'Server is not responding properly',
            success: false,
            error: 'Server is not responding properly',
            statusCode: testResponse.statusCode,
          );
        }
      } catch (e) {
        print('Server connection test failed: $e');
        return ApiResponse(
          message: 'Could not connect to the server',
          success: false,
          error:
              'Could not connect to the server. Please check if the backend server is running.',
          statusCode: 503,
        );
      }

      // If we get here, the server is responding and the token is valid
      // Get the current user data
      final response = await http.get(
        Uri.parse('${AppConfig.apiBaseUrl}/api/users/me'),
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
            message: 'User data fetched successfully',
            success: true,
            data: user,
            statusCode: response.statusCode,
          );
        } catch (e) {
          print('Error parsing user data: $e');
          return ApiResponse(
            message: 'Failed to parse user data',
            success: false,
            error: 'Failed to parse user data',
            statusCode: response.statusCode,
          );
        }
      } else {
        print('Unexpected response status: ${response.statusCode}');
        return ApiResponse(
          message: 'Failed to get user data',
          success: false,
          error: 'Failed to get user data',
          statusCode: response.statusCode,
        );
      }
    } on TimeoutException {
      print('Server connection timed out');
      return ApiResponse(
        message: 'Server connection timed out',
        success: false,
        error:
            'Could not connect to the server. Please check if the backend server is running and accessible.',
        statusCode: 408,
      );
    } catch (e) {
      print('Error validating token: $e');
      return ApiResponse(
        message: 'Failed to connect to the server',
        success: false,
        error:
            'Failed to connect to the server. Please check your internet connection and ensure the backend server is running.',
        statusCode: 500,
      );
    }
  }
}
