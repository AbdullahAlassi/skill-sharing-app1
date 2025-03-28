import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../utils/token_storage.dart';

class ApiResponse<T> {
  final T? data;
  final String? error;
  final bool success;

  ApiResponse({this.data, this.error, this.success = true});

  factory ApiResponse.success(T data) {
    return ApiResponse(data: data, success: true);
  }

  factory ApiResponse.error(String error) {
    return ApiResponse(error: error, success: false);
  }
}

class ApiClient {
  final String baseUrl;

  ApiClient({String? baseUrl}) : baseUrl = baseUrl ?? AppConfig.apiBaseUrl;

  // Helper method to get headers with auth token
  Future<Map<String, String>> _getHeaders() async {
    final token = await TokenStorage.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // GET request
  Future<ApiResponse<T>> get<T>(
    String endpoint,
    T Function(dynamic json) fromJson,
  ) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/$endpoint'),
        headers: headers,
      );

      return _handleResponse(response, fromJson);
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }

  // POST request
  Future<ApiResponse<T>> post<T>(
    String endpoint,
    dynamic data,
    T Function(dynamic json) fromJson,
  ) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/$endpoint'),
        headers: headers,
        body: jsonEncode(data),
      );

      return _handleResponse(response, fromJson);
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }

  // PUT request
  Future<ApiResponse<T>> put<T>(
    String endpoint,
    dynamic data,
    T Function(dynamic json) fromJson,
  ) async {
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse('$baseUrl/$endpoint'),
        headers: headers,
        body: jsonEncode(data),
      );

      return _handleResponse(response, fromJson);
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }

  // DELETE request
  Future<ApiResponse<T>> delete<T>(
    String endpoint,
    T Function(dynamic json) fromJson,
  ) async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/$endpoint'),
        headers: headers,
      );

      return _handleResponse(response, fromJson);
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }

  // Handle API response
  ApiResponse<T> _handleResponse<T>(
    http.Response response,
    T Function(dynamic json) fromJson,
  ) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) {
        return ApiResponse.success({} as T);
      }

      final jsonData = jsonDecode(response.body);
      return ApiResponse.success(fromJson(jsonData));
    } else {
      final error =
          response.body.isNotEmpty
              ? jsonDecode(response.body)['message'] ?? 'An error occurred'
              : 'An error occurred';
      return ApiResponse.error(error);
    }
  }
}
