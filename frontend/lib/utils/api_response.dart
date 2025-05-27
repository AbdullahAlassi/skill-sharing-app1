class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? error;
  final int? statusCode;
  final String? message;

  ApiResponse({
    this.success = false,
    this.data,
    this.error,
    this.statusCode,
    this.message,
  });

  factory ApiResponse.success({
    required T data,
    int? statusCode,
    String? message,
  }) {
    return ApiResponse<T>(
      success: true,
      data: data,
      statusCode: statusCode,
      message: message,
    );
  }

  factory ApiResponse.error(
    String error, {
    int? statusCode,
  }) {
    return ApiResponse<T>(
      success: false,
      error: error,
      statusCode: statusCode,
    );
  }

  factory ApiResponse.fromJson(dynamic json) {
    print('[ApiResponse] Processing response: $json');
    print('[ApiResponse] Response type: ${json.runtimeType}');
    print('[ApiResponse] Expected type: $T');

    if (json is Map<String, dynamic>) {
      print('[ApiResponse] Processing Map response');
      // Handle standard API response format
      if (json.containsKey('success')) {
        print(
            '[ApiResponse] Found success field, processing standard response');
        final data = json['data'];
        print('[ApiResponse] Data field type: ${data?.runtimeType}');

        if (data != null) {
          if (T.toString() == 'List<String>' && data is List) {
            print('[ApiResponse] Converting List to List<String>');
            return ApiResponse<T>.success(
              data: data.cast<String>() as T,
              statusCode: json['statusCode'],
              message: json['message'],
            );
          } else if (T.toString() == 'Map<String, dynamic>' && data is Map) {
            print('[ApiResponse] Converting Map to Map<String, dynamic>');
            return ApiResponse<T>.success(
              data: data as T,
              statusCode: json['statusCode'],
              message: json['message'],
            );
          }
        }

        return ApiResponse<T>(
          success: json['success'] ?? false,
          data: data as T?,
          error: json['error'],
          statusCode: json['statusCode'],
          message: json['message'],
        );
      }

      // Handle direct data object
      print('[ApiResponse] Processing direct data object');
      return ApiResponse<T>.success(
        data: json as T,
      );
    } else if (json is List) {
      print('[ApiResponse] Processing List response');
      // Handle direct list responses
      if (T.toString() == 'List<String>') {
        print('[ApiResponse] Converting List to List<String>');
        return ApiResponse<T>.success(
          data: json.cast<String>() as T,
        );
      } else if (T.toString() == 'List<dynamic>') {
        print('[ApiResponse] Using List as List<dynamic>');
        return ApiResponse<T>.success(
          data: json as T,
        );
      }
    }

    // Fallback for invalid response format
    print('[ApiResponse] Invalid response format, returning error');
    return ApiResponse<T>(
      success: false,
      data: null,
      error: 'Invalid response format',
    );
  }
}
