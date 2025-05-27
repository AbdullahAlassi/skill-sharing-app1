import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/badge_model.dart';
import '../config/app_config.dart';
import '../utils/token_storage.dart';

class BadgeService {
  final String baseUrl = AppConfig.apiBaseUrl;

  Future<Map<String, dynamic>> getBadges() async {
    try {
      final token = await TokenStorage.getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/api/badges'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> badgesJson = jsonDecode(response.body);
        return {
          'success': true,
          'data': badgesJson.map((json) => BadgeModel.fromJson(json)).toList(),
        };
      } else {
        return {
          'success': false,
          'error': jsonDecode(response.body)['message'],
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  Future<Map<String, dynamic>> unlockBadge(String badgeId) async {
    try {
      final token = await TokenStorage.getToken();
      final response = await http.post(
        Uri.parse('$baseUrl/api/badges/$badgeId/unlock'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': BadgeModel.fromJson(jsonDecode(response.body)),
        };
      } else {
        return {
          'success': false,
          'error': jsonDecode(response.body)['message'],
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  Future<Map<String, dynamic>> checkAchievements() async {
    try {
      final token = await TokenStorage.getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/api/badges/check-achievements'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> badgesJson = jsonDecode(response.body);
        return {
          'success': true,
          'data': badgesJson.map((json) => BadgeModel.fromJson(json)).toList(),
        };
      } else {
        return {
          'success': false,
          'error': jsonDecode(response.body)['message'],
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }
}
