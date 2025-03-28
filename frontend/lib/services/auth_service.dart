import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/user_model.dart';
import '../utils/token_storage.dart';
import 'api_client.dart';

class AuthService {
  final ApiClient _apiClient;

  AuthService({ApiClient? apiClient, required String baseUrl})
    : _apiClient = apiClient ?? ApiClient();

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
        return ApiResponse.success(data);
      } else {
        return ApiResponse.error(data['message'] ?? 'Registration failed');
      }
    } catch (e) {
      return ApiResponse.error(e.toString());
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
        return ApiResponse.success(data);
      } else {
        return ApiResponse.error(data['message'] ?? 'Login failed');
      }
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }

  // Get current user
  Future<ApiResponse<User>> getCurrentUser() async {
    return await _apiClient.get<User>(
      'auth/user',
      (json) => User.fromJson(json),
    );
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
