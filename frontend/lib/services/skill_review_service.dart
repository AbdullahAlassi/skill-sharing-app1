import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../utils/token_storage.dart';

class SkillReviewService {
  final String baseUrl;

  SkillReviewService({required this.baseUrl});

  Future<Map<String, dynamic>> addReview({
    required String skillId,
    required int rating,
    required String comment,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/api/skills/$skillId/reviews');
      final token = await TokenStorage.getToken();

      print('=== Submitting Skill Review ===');
      print('Requested URL: $uri');
      print('Request Headers: {' +
          '\'Content-Type\': \'application/json\', \'Authorization\': \'Bearer [TOKEN]\'}'); // Log headers without sensitive token
      print('Request Body: ${json.encode({
            'rating': rating,
            'comment': comment,
          })}');

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'rating': rating,
          'comment': comment,
        }),
      );

      print('Response Status Code: ${response.statusCode}');

      if (response.statusCode == 201) {
        print('Response Body (Success): ${response.body}');
        return {
          'success': true,
          'data': json.decode(response.body),
        };
      } else {
        print('Response Body (Error): ${response.body}');
        try {
          final errorBody = json.decode(response.body);
          return {
            'success': false,
            'error': errorBody['message'] ??
                errorBody.toString() ??
                'Failed to add review',
          };
        } catch (e) {
          print('Error decoding error response body: $e');
          return {
            'success': false,
            'error': 'Failed to add review: Invalid response from server',
          };
        }
      }
    } catch (e) {
      print('Error in addReview: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  Future<Map<String, dynamic>> getReviews(String skillId) async {
    try {
      final uri = Uri.parse('$baseUrl/api/skills/$skillId/reviews');
      print('=== Fetching Skill Reviews ===');
      print('Requested URL: $uri');

      final response = await http.get(uri);

      print('Response Status Code: ${response.statusCode}');

      if (response.statusCode == 200) {
        print('Response Body (Success): ${response.body}');
        return {
          'success': true,
          'data': json.decode(response.body),
        };
      } else {
        print('Response Body (Error): ${response.body}');
        return {
          'success': false,
          'error': json.decode(response.body)['message'] ??
              'Failed to fetch reviews',
        };
      }
    } catch (e) {
      print('Error in getReviews: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  Future<Map<String, dynamic>> updateReview({
    required String skillId,
    required String reviewId,
    required int rating,
    required String comment,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/api/skills/$skillId/reviews/$reviewId');
      final token = await TokenStorage.getToken();

      print('=== Updating Skill Review ===');
      print('Requested URL: $uri');
      print('Request Headers: {' +
          '\'Content-Type\': \'application/json\', \'Authorization\': \'Bearer [TOKEN]\'}');
      print('Request Body: ${json.encode({
            'rating': rating,
            'comment': comment,
          })}');

      final response = await http.put(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'rating': rating,
          'comment': comment,
        }),
      );

      print('Response Status Code: ${response.statusCode}');

      if (response.statusCode == 200) {
        print('Response Body (Success): ${response.body}');
        return {
          'success': true,
          'data': json.decode(response.body),
        };
      } else {
        print('Response Body (Error): ${response.body}');
        try {
          final errorBody = json.decode(response.body);
          return {
            'success': false,
            'error': errorBody['message'] ??
                errorBody.toString() ??
                'Failed to update review',
          };
        } catch (e) {
          print('Error decoding error response body: $e');
          return {
            'success': false,
            'error': 'Failed to update review: Invalid response from server',
          };
        }
      }
    } catch (e) {
      print('Error in updateReview: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  Future<Map<String, dynamic>> deleteReview({
    required String skillId,
    required String reviewId,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/api/skills/$skillId/reviews/$reviewId');
      final token = await TokenStorage.getToken();

      print('=== Deleting Skill Review ===');
      print('Requested URL: $uri');
      print('Request Headers: {' +
          '\'Authorization\': \'Bearer [TOKEN]\'}'); // Log headers without sensitive token

      final response = await http.delete(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      print('Response Status Code: ${response.statusCode}');

      if (response.statusCode == 200) {
        print('Response Body (Success): ${response.body}');
        return {
          'success': true,
          'data': json.decode(response.body),
        };
      } else {
        print('Response Body (Error): ${response.body}');
        try {
          final errorBody = json.decode(response.body);
          return {
            'success': false,
            'error': errorBody['message'] ??
                errorBody.toString() ??
                'Failed to delete review',
          };
        } catch (e) {
          print('Error decoding error response body: $e');
          return {
            'success': false,
            'error': 'Failed to delete review: Invalid response from server',
          };
        }
      }
    } catch (e) {
      print('Error in deleteReview: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }
}
