import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../services/skill_service.dart';
import '../models/skill_model.dart';
import '../models/user_model.dart';
import '../utils/api_response.dart';
import 'package:provider/provider.dart';
import '../providers/progress_provider.dart';
import '../services/progress_service.dart';
import '../providers/user_provider.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class SkillProvider with ChangeNotifier {
  final SkillService _skillService;
  final ProgressService _progressService;
  List<Skill> _skills = [];
  List<Skill> _recommendedSkills = [];
  bool _isLoading = false;
  String? _error;

  SkillProvider(this._skillService, this._progressService);

  List<Skill> get skills => _skills;
  List<Skill> get recommendedSkills => _recommendedSkills;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadSkills() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _skillService.getSkills();
      if (response.success && response.data != null) {
        _skills = response.data!;
        _error = null;
      } else {
        _error = response.error ?? 'Failed to load skills';
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createSkill(
    String name,
    String category,
    String description,
    List<String> relatedSkills,
    String proficiency,
    String difficultyLevel,
  ) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _skillService.createSkill(
        name,
        category,
        description,
        relatedSkills,
        proficiency,
        difficultyLevel,
      );
      if (response.success && response.data != null) {
        _skills.add(response.data!);
        _error = null;

        // Automatically create a learning goal for the new skill
        try {
          final goalResult = await _progressService.createGoal(
            skillId: response.data!.id,
            targetDate: DateTime.now()
                .add(const Duration(days: 30)), // default goal duration
          );
          if (!goalResult['success']) {
            debugPrint(
                '[DEBUG] auto-create goal failed: ${goalResult['error']}');
          }
        } catch (e) {
          debugPrint('[DEBUG] auto-create goal exception: $e');
        }
      } else {
        _error = response.error ?? 'Failed to create skill';
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateSkill(
    String id,
    String name,
    String category,
    String description,
    List<String> relatedSkills,
    String proficiency,
  ) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _skillService.updateSkill(
        id,
        name,
        category,
        description,
        relatedSkills,
        proficiency,
      );
      if (response.success && response.data != null) {
        final index = _skills.indexWhere((s) => s.id == id);
        if (index != -1) {
          _skills[index] = response.data!;
        }
        _error = null;
      } else {
        _error = response.error ?? 'Failed to update skill';
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadRecommendedSkills(BuildContext context) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final user = userProvider.user;

      if (user == null) {
        _error = 'User not found';
        debugPrint('[SkillProvider] User not found');
        return;
      }

      debugPrint(
          '[SkillProvider] Loading recommendations for user: ${user.id}');
      debugPrint(
          '[SkillProvider] User favorite categories: ${user.favoriteCategories}');

      if (user.favoriteCategories.isEmpty) {
        _error = 'No favorite categories selected';
        debugPrint('[SkillProvider] No favorite categories selected');
        return;
      }

      final response = await _skillService.getRecommendations();
      if (response.success && response.data != null) {
        debugPrint(
            '[SkillProvider] response.data runtimeType: ${response.data.runtimeType}');

        List<Skill> allRecommendedSkills = [];

        if (response.data is List<Skill>) {
          // If data is already a List<Skill>, use it directly
          allRecommendedSkills = response.data!;
          debugPrint('[SkillProvider] Data is already List<Skill>');
        } else if (response.data is Map<String, dynamic> &&
            (response.data as Map<String, dynamic>)['recommendations']
                is List) {
          // If data is a Map with a recommendations list, process it
          final recommendationsJson = (response.data
              as Map<String, dynamic>)['recommendations'] as List;
          debugPrint(
              '[SkillProvider] Raw recommendations count (from map): ${recommendationsJson.length}');
          allRecommendedSkills = recommendationsJson
              .map((json) => Skill.fromJson(json as Map<String, dynamic>))
              .toList();
          debugPrint(
              '[SkillProvider] Processed recommendations count (from map): ${allRecommendedSkills.length}');
        } else if (response.data is List) {
          // If data is a general List (assuming list of maps), process it
          final recommendationsJson = response.data as List;
          debugPrint(
              '[SkillProvider] Raw recommendations count (from list): ${recommendationsJson.length}');
          allRecommendedSkills = recommendationsJson
              .map((json) => Skill.fromJson(json as Map<String, dynamic>))
              .toList();
          debugPrint(
              '[SkillProvider] Processed recommendations count (from list): ${allRecommendedSkills.length}');
        }

        debugPrint(
            '[SkillProvider] Total potential recommendations after initial processing: ${allRecommendedSkills.length}');

        // Filter out skills the user already has and skills created by the user
        _recommendedSkills = allRecommendedSkills
            .where((skill) =>
                (user.skills == null || !user.skills!.contains(skill.id)) &&
                skill.createdBy?.id != user.id)
            .toList();

        debugPrint(
            '[SkillProvider] Filtered recommendations count: ${_recommendedSkills.length}');
        debugPrint(
            '[SkillProvider] Removed ${allRecommendedSkills.length - _recommendedSkills.length} already added or created skills');

        // Sort the filtered recommendations based on favorite categories
        _recommendedSkills = _sortRecommendedSkills(_recommendedSkills, user);

        debugPrint('[SkillProvider] Final recommendations:');
        for (var skill in _recommendedSkills) {
          debugPrint('- ${skill.name} (${skill.categoryName})');
        }

        _error = null;
      } else {
        _error = response.error ?? 'Failed to load recommended skills';
        debugPrint('[SkillProvider] Error loading recommendations: $_error');
      }
    } catch (e) {
      _error = e.toString();
      debugPrint('[SkillProvider] Exception loading recommendations: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
      debugPrint('[SkillProvider] Notified listeners of state change');
    }
  }

  List<Skill> _sortRecommendedSkills(List<Skill> skills, User user) {
    debugPrint('[SkillProvider] Sorting ${skills.length} skills');
    debugPrint(
        '[SkillProvider] User favorite categories: ${user.favoriteCategories}');

    // First try to filter skills to only include those in user's favorite categories
    final filteredSkills = skills
        .where((skill) => user.favoriteCategories.contains(skill.categoryName))
        .toList();

    debugPrint(
        '[SkillProvider] Filtered to ${filteredSkills.length} skills in favorite categories');

    // If no skills match favorite categories, use all skills
    final skillsToSort = filteredSkills.isEmpty ? skills : filteredSkills;

    // Sort by category to group similar skills together
    final sortedSkills = List<Skill>.from(skillsToSort)
      ..sort((a, b) {
        // First sort by category to group similar skills
        int categoryCompare = a.categoryName.compareTo(b.categoryName);
        if (categoryCompare != 0) {
          return categoryCompare;
        }

        // Then sort by name within the same category
        return a.name.compareTo(b.name);
      });

    debugPrint('[SkillProvider] Sorted skills by category and name');
    for (var skill in sortedSkills) {
      debugPrint('- ${skill.name} (${skill.categoryName})');
    }

    return sortedSkills;
  }

  Future<void> fetchSkillsByCategory(String categoryId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:5000/api/skills?category=$categoryId'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _skills = data.map((json) => Skill.fromJson(json)).toList();
        _error = null;
      } else {
        _error = 'Failed to load skills';
      }
    } catch (e) {
      _error = 'Error: ${e.toString()}';
    }

    _isLoading = false;
    notifyListeners();
  }
}
