import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../utils/token_storage.dart';

class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? error;
  final int statusCode;
  final String? body;

  ApiResponse({
    required this.success,
    this.data,
    this.error,
    required this.statusCode,
    this.body,
  });
}

class ApiClient {
  final String baseUrl;

  ApiClient({String? baseUrl}) : baseUrl = baseUrl ?? AppConfig.apiBaseUrl;

  // Helper method to get headers with auth token
  Future<Map<String, String>> _getHeaders() async {
    final token = await TokenStorage.getToken();
    print("Auth token: ${token != null ? 'Present' : 'Missing'}");
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // GET request for a single item or a list
  Future<ApiResponse<T>> get<T>(
    String endpoint,
    T Function(dynamic, String) fromJson, // Keep as dynamic to be flexible
  ) async {
    try {
      print("GET request to: $baseUrl/$endpoint");
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/$endpoint'),
        headers: headers,
      );

      print("GET response status: ${response.statusCode}");
      if (response.body.isNotEmpty) {
        print(
          "GET response body: ${response.body.substring(0, response.body.length > 100 ? 100 : response.body.length)}...",
        );
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        try {
          // Pass the raw response body string
          final data = fromJson(response.body, endpoint);
          return ApiResponse<T>(
            success: true,
            data: data,
            error: null,
            statusCode: response.statusCode,
            body: response.body,
          );
        } catch (e) {
          print("GET parsing error: $e");
          return ApiResponse<T>(
            success: false,
            data: null,
            error: "Error parsing response: $e",
            statusCode: response.statusCode,
            body: response.body,
          );
        }
      } else {
        // Rest of the method remains the same
        String errorMsg;
        try {
          final jsonData = jsonDecode(response.body);
          errorMsg =
              jsonData['message'] ??
              'Request failed with status ${response.statusCode}';
        } catch (e) {
          errorMsg = 'Request failed with status ${response.statusCode}';
        }
        print("GET error: $errorMsg");
        return ApiResponse<T>(
          success: false,
          data: null,
          error: errorMsg,
          statusCode: response.statusCode,
          body: response.body,
        );
      }
    } catch (e) {
      print("GET exception: $e");
      return ApiResponse<T>(
        success: false,
        data: null,
        error: e.toString(),
        statusCode: 0,
        body: null,
      );
    }
  }

  // POST request
  Future<ApiResponse<T>> post<T>(
    String endpoint,
    Map<String, dynamic> data,
    T Function(dynamic, String) fromJson,
  ) async {
    try {
      print("POST request to: $baseUrl/$endpoint");
      print("POST data: $data");
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/$endpoint'),
        headers: headers,
        body: jsonEncode(data),
      );

      print("POST response status: ${response.statusCode}");
      if (response.body.isNotEmpty) {
        print(
          "POST response body: ${response.body.substring(0, response.body.length > 100 ? 100 : response.body.length)}...",
        );
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        try {
          final result = fromJson(response.body, endpoint);
          return ApiResponse<T>(
            success: true,
            data: result,
            error: null,
            statusCode: response.statusCode,
            body: response.body,
          );
        } catch (e) {
          print("POST parsing error: $e");
          return ApiResponse<T>(
            success: false,
            data: null,
            error: "Error parsing response: $e",
            statusCode: response.statusCode,
            body: response.body,
          );
        }
      } else {
        String errorMsg;
        try {
          final jsonData = jsonDecode(response.body);
          errorMsg =
              jsonData['message'] ??
              'Request failed with status ${response.statusCode}';
        } catch (e) {
          errorMsg = 'Request failed with status ${response.statusCode}';
        }
        print("POST error: $errorMsg");
        return ApiResponse<T>(
          success: false,
          data: null,
          error: errorMsg,
          statusCode: response.statusCode,
          body: response.body,
        );
      }
    } catch (e) {
      print("POST exception: $e");
      return ApiResponse<T>(
        success: false,
        data: null,
        error: e.toString(),
        statusCode: 0,
        body: null,
      );
    }
  }

  // PUT request
  Future<ApiResponse<T>> put<T>(
    String endpoint,
    Map<String, dynamic> data,
    T Function(dynamic, String) fromJson,
  ) async {
    try {
      print("PUT request to: $baseUrl/$endpoint");
      print("PUT data: $data");
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse('$baseUrl/$endpoint'),
        headers: headers,
        body: jsonEncode(data),
      );

      print("PUT response status: ${response.statusCode}");
      if (response.body.isNotEmpty) {
        print(
          "PUT response body: ${response.body.substring(0, response.body.length > 100 ? 100 : response.body.length)}...",
        );
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        try {
          final result = fromJson(response.body, endpoint);
          return ApiResponse<T>(
            success: true,
            data: result,
            error: null,
            statusCode: response.statusCode,
            body: response.body,
          );
        } catch (e) {
          print("PUT parsing error: $e");
          return ApiResponse<T>(
            success: false,
            data: null,
            error: "Error parsing response: $e",
            statusCode: response.statusCode,
            body: response.body,
          );
        }
      } else {
        String errorMsg;
        try {
          final jsonData = jsonDecode(response.body);
          errorMsg =
              jsonData['message'] ??
              'Request failed with status ${response.statusCode}';
        } catch (e) {
          errorMsg = 'Request failed with status ${response.statusCode}';
        }
        print("PUT error: $errorMsg");
        return ApiResponse<T>(
          success: false,
          data: null,
          error: errorMsg,
          statusCode: response.statusCode,
          body: response.body,
        );
      }
    } catch (e) {
      print("PUT exception: $e");
      return ApiResponse<T>(
        success: false,
        data: null,
        error: e.toString(),
        statusCode: 0,
        body: null,
      );
    }
  }

  // DELETE request
  Future<ApiResponse<T>> delete<T>(
    String endpoint,
    T Function(dynamic, String) fromJson,
  ) async {
    try {
      print("DELETE request to: $baseUrl/$endpoint");
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/$endpoint'),
        headers: headers,
      );

      print("DELETE response status: ${response.statusCode}");
      if (response.body.isNotEmpty) {
        print(
          "DELETE response body: ${response.body.substring(0, response.body.length > 100 ? 100 : response.body.length)}...",
        );
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (response.body.isEmpty) {
          // Some DELETE endpoints return empty body
          return ApiResponse<T>(
            success: true,
            data: {} as T,
            error: null,
            statusCode: response.statusCode,
            body: response.body,
          );
        }
        try {
          final result = fromJson(response.body, endpoint);
          return ApiResponse<T>(
            success: true,
            data: result,
            error: null,
            statusCode: response.statusCode,
            body: response.body,
          );
        } catch (e) {
          print("DELETE parsing error: $e");
          return ApiResponse<T>(
            success: false,
            data: null,
            error: "Error parsing response: $e",
            statusCode: response.statusCode,
            body: response.body,
          );
        }
      } else {
        String errorMsg;
        try {
          final jsonData = jsonDecode(response.body);
          errorMsg =
              jsonData['message'] ??
              'Request failed with status ${response.statusCode}';
        } catch (e) {
          errorMsg = 'Request failed with status ${response.statusCode}';
        }
        print("DELETE error: $errorMsg");
        return ApiResponse<T>(
          success: false,
          data: null,
          error: errorMsg,
          statusCode: response.statusCode,
          body: response.body,
        );
      }
    } catch (e) {
      print("DELETE exception: $e");
      return ApiResponse<T>(
        success: false,
        data: null,
        error: e.toString(),
        statusCode: 0,
        body: null,
      );
    }
  }
}
