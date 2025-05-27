import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/user_model.dart';

class PublicProfileService {
  final String baseUrl;

  PublicProfileService({required this.baseUrl});

  Future<Map<String, dynamic>> getPublicProfile(String userId) async {
    try {
      final uri = Uri.parse('$baseUrl/api/users/$userId');
      print('=== Fetching Public User Profile ===');
      print('Requested URL: $uri');

      final response = await http.get(uri);

      print('Response Status Code: ${response.statusCode}');

      if (response.statusCode == 200) {
        print('Response Body (Success): ${response.body}');
        return {
          'success': true,
          'data': json.decode(response.body)['data'],
        };
      } else {
        print('Response Body (Error): ${response.body}');
        try {
          final errorBody = json.decode(response.body);
          return {
            'success': false,
            'error': errorBody['message'] ??
                errorBody.toString() ??
                'Failed to fetch public profile',
          };
        } catch (e) {
          print('Error decoding error response body: $e');
          return {
            'success': false,
            'error':
                'Failed to fetch public profile: Invalid response from server',
          };
        }
      }
    } catch (e) {
      print('Error in getPublicProfile: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }
}
