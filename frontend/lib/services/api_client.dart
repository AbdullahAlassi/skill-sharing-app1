import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../utils/token_storage.dart';
import '../utils/api_response.dart';

class ApiClient {
  final String baseUrl;
  final http.Client _client;

  ApiClient({
    required this.baseUrl,
    http.Client? client,
  }) : _client = client ?? http.Client();

  Future<String?> getToken() async {
    final token = await TokenStorage.getToken();
    if (token == null) {
      print('[ApiClient] No token available for request');
      return null;
    }

    // Verify token is not expired
    if (await TokenStorage.isTokenExpired(token)) {
      print('[ApiClient] Token is expired, clearing...');
      await TokenStorage.clearToken();
      return null;
    }

    print('[ApiClient] Retrieved fresh token: $token');
    return token;
  }

  Future<ApiResponse<T>> get<T>(
    String endpoint,
    T Function(dynamic json) fromJson, {
    bool requiresAuth = true,
  }) async {
    final url = '$baseUrl/$endpoint';
    print('\n[ApiClient] Making GET Request to: $endpoint');
    print('[ApiClient] Final URL: $url');
    return _handleRequest<T>(
      () async => await _client.get(
        Uri.parse(url),
        headers: await _getHeaders(requiresAuth),
      ),
      fromJson,
    );
  }

  Future<ApiResponse<T>> post<T>(
    String endpoint,
    Map<String, dynamic> data,
    T Function(dynamic json) fromJson, {
    bool requiresAuth = true,
  }) async {
    final url = '$baseUrl/$endpoint';
    print('\n[ApiClient] Making POST Request to: $endpoint');
    print('[ApiClient] Final URL: $url');
    print('[ApiClient] Request body: $data');
    return _handleRequest<T>(
      () async => await _client.post(
        Uri.parse(url),
        headers: await _getHeaders(requiresAuth),
        body: json.encode(data),
      ),
      fromJson,
    );
  }

  Future<ApiResponse<T>> put<T>(
    String endpoint,
    Map<String, dynamic> data,
    T Function(dynamic json) fromJson, {
    bool requiresAuth = true,
  }) async {
    final url = '$baseUrl/$endpoint';
    print('\n[ApiClient] Making PUT Request to: $endpoint');
    print('[ApiClient] Final URL: $url');
    print('[ApiClient] Request body: $data');
    return _handleRequest<T>(
      () async => await _client.put(
        Uri.parse(url),
        headers: await _getHeaders(requiresAuth),
        body: json.encode(data),
      ),
      fromJson,
    );
  }

  Future<ApiResponse<T>> delete<T>(
    String endpoint,
    T Function(dynamic json) fromJson, {
    bool requiresAuth = true,
  }) async {
    final url = '$baseUrl/$endpoint';
    print('\n[ApiClient] Making DELETE Request to: $endpoint');
    print('[ApiClient] Final URL: $url');
    return _handleRequest<T>(
      () async => await _client.delete(
        Uri.parse(url),
        headers: await _getHeaders(requiresAuth),
      ),
      fromJson,
    );
  }

  Future<http.Response> rawPut(
    String endpoint,
    Map<String, dynamic> data, {
    bool requiresAuth = true,
  }) async {
    final url = '$baseUrl/$endpoint';
    print('\n[ApiClient] Making raw PUT Request to: $endpoint');
    print('[ApiClient] Final URL: $url');
    print('[ApiClient] Request body: $data');
    final headers = await _getHeaders(requiresAuth);
    return await _client.put(
      Uri.parse(url),
      headers: headers,
      body: jsonEncode(data),
    );
  }

  Future<Map<String, String>> _getHeaders(bool requiresAuth) async {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (requiresAuth) {
      final token = await getToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
        print('[ApiClient] Using token: $token');
      } else {
        print('[ApiClient] No token available for authenticated request');
      }
    }

    return headers;
  }

  Future<ApiResponse<T>> _handleRequest<T>(
    Future<http.Response> Function() requestFunction,
    T Function(dynamic json) fromJson,
  ) async {
    try {
      final response = await requestFunction();
      final statusCode = response.statusCode;
      final rawBody = response.body;

      print('[ApiClient] Status Code: $statusCode');
      print('[ApiClient] Raw Response Body: $rawBody');

      // Handle error responses
      if (statusCode >= 400) {
        final parsedJson = json.decode(rawBody);
        final errorMessage = parsedJson is Map<String, dynamic>
            ? parsedJson['message'] ?? 'Request failed'
            : 'Request failed';
        return ApiResponse<T>.error(
          errorMessage,
          statusCode: statusCode,
        );
      }

      final parsedJson = json.decode(rawBody);

      // Pass the entire parsedJson to fromJson. The fromJson function
      // is responsible for handling the specific structure (e.g., unwrapping 'data').
      final T data = fromJson(parsedJson);

      print('[ApiClient] Parsed data type: ${data.runtimeType}');
      // Avoid printing large data payloads to prevent log spam
      // print('[ApiClient] Parsed data content: $data');

      return ApiResponse<T>.success(
        data: data,
        statusCode: statusCode,
        message: parsedJson is Map<String, dynamic> &&
                parsedJson.containsKey('message')
            ? parsedJson['message']
            : 'Success',
      );
    } catch (e) {
      print('[ApiClient] Error in _handleRequest: $e');
      return ApiResponse<T>.error(
        'Request failed: ${e.toString()}',
        statusCode: 500,
      );
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> debugTokenCheck() async {
    print('\n[ApiClient] Making debug token check request');
    try {
      final token = await getToken();
      if (token == null) {
        print('[ApiClient] No token found for debug check');
        return ApiResponse<Map<String, dynamic>>.error(
          'No token found',
          statusCode: 401,
        );
      }

      final url = '$baseUrl/users/debug-token';
      print('[ApiClient] Final URL: $url');
      final response = await _client.get(
        Uri.parse(url),
        headers: await _getHeaders(true),
      );

      print('[ApiClient] Debug token response: ${response.body}');
      final body = json.decode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return ApiResponse<Map<String, dynamic>>.success(
          data: body,
          message: 'Token verified successfully',
          statusCode: response.statusCode,
        );
      } else {
        final message = body['message'] ?? 'Failed to verify token';
        print('[ApiClient] Debug token check failed: $message');
        return ApiResponse<Map<String, dynamic>>.error(
          message,
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      print('[ApiClient] Debug token check exception: $e');
      return ApiResponse<Map<String, dynamic>>.error(
        e.toString(),
        statusCode: 500,
      );
    }
  }

  void dispose() {
    _client.close();
  }
}
