import 'package:flutter/material.dart';
import '../models/resource_model.dart' as rm;
import '../models/goal_model.dart';
import '../services/progress_service.dart';
import '../services/resource_service.dart';
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import '../models/progress_model.dart';
import '../utils/api_response.dart';
import '../models/skill_model.dart';

class SkillProgress {
  final String skillId;
  final String skillName;
  final double progress;
  final List<Map<String, dynamic>> milestones;
  final String difficultyLevel;
  final double completionPercentage;
  final int practiceTimeMinutes;
  final int completedResources;
  final double? assessmentScore;

  SkillProgress({
    required this.skillId,
    required this.skillName,
    required this.progress,
    required this.milestones,
    required this.difficultyLevel,
    required this.completionPercentage,
    required this.practiceTimeMinutes,
    required this.completedResources,
    this.assessmentScore,
  });

  factory SkillProgress.fromJson(Map<String, dynamic> json) {
    return SkillProgress(
      skillId: json['skillId'] as String,
      skillName: json['skillName'] as String,
      progress: (json['completionPercentage'] as num).toDouble(),
      milestones: (json['milestones'] as List<dynamic>?)
              ?.cast<Map<String, dynamic>>() ??
          [],
      difficultyLevel: json['difficultyLevel'] as String? ?? 'beginner',
      completionPercentage: (json['completionPercentage'] as num).toDouble(),
      practiceTimeMinutes: (json['practiceTimeMinutes'] as num?)?.toInt() ?? 0,
      completedResources: (json['completedResources'] as num?)?.toInt() ?? 0,
      assessmentScore: (json['assessmentScore'] as num?)?.toDouble(),
    );
  }
}

class ProgressProvider with ChangeNotifier {
  final ProgressService _progressService;
  final ResourceService _resourceService = ResourceService();
  List<GoalModel> _goals = [];
  List<Progress> _progress = [];
  List<rm.Resource> _completedResources = [];
  List<Map<String, dynamic>> _practiceHistory = [];
  bool _isLoading = false;
  String? _error;
  double _totalProgress = 0.0;
  List<SkillProgress> _skillProgress = [];
  // Cache for resources by skill ID
  final Map<String, List<rm.Resource>> _resourceCache = {};

  ProgressProvider(this._progressService);

  List<GoalModel> get goals => _goals;
  List<Progress> get progress => _progress;
  List<rm.Resource> get completedResources => _completedResources;
  List<Map<String, dynamic>> get practiceHistory => _practiceHistory;
  bool get isLoading => _isLoading;
  String? get error => _error;
  double get totalProgress => _totalProgress;
  List<SkillProgress> get skillProgress => _skillProgress;

  Future<Map<String, dynamic>> createGoal({
    required String skillId,
    required DateTime targetDate,
  }) async {
    try {
      final response = await _progressService.createGoal(
        skillId: skillId,
        targetDate: targetDate,
      );

      if (response['success']) {
        // Refresh goals after creation
        await fetchUserProgress();
        return {'success': true};
      }

      return {
        'success': false,
        'error': response['error'] ?? 'Failed to create goal',
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  Future<void> fetchUserProgress() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      debugPrint('[DEBUG] Fetching user progress...');

      final progressResponse = await _progressService.getUserProgress();
      debugPrint('[DEBUG] Progress response: ${progressResponse.data}');

      if (progressResponse.success) {
        final data = progressResponse.data as Map<String, dynamic>;

        // Update total progress
        _totalProgress = (data['totalProgress'] as num?)?.toDouble() ?? 0.0;
        debugPrint('[DEBUG] Total progress: $_totalProgress');

        // Update skill progress
        final skillProgressList =
            (data['skillProgress'] as List<dynamic>?) ?? [];
        _skillProgress = skillProgressList
            .map((item) => SkillProgress.fromJson(item as Map<String, dynamic>))
            .toList();
        debugPrint('[DEBUG] Skill progress: $_skillProgress');

        // Update completed resources
        final completedResourcesList =
            (data['completedResources'] as List<dynamic>?) ?? [];
        _completedResources = completedResourcesList
            .map((item) => rm.Resource.fromJson(item as Map<String, dynamic>))
            .toList();
        debugPrint('[DEBUG] Completed resources: $_completedResources');

        // Update practice history
        _practiceHistory = (data['practiceHistory'] as List<dynamic>?)
                ?.cast<Map<String, dynamic>>() ??
            [];
        debugPrint('[DEBUG] Practice history: $_practiceHistory');

        // Fetch goals separately
        final goalsResponse = await _progressService.getGoals();
        if (goalsResponse['success']) {
          _goals = List<GoalModel>.from(goalsResponse['data'] ?? []);
          debugPrint('[DEBUG] Goals before sync: $_goals');

          // Create a map of skill progress for easy lookup
          final Map<String, double> skillProgressMap = {};
          for (var progress in _skillProgress) {
            skillProgressMap[progress.skillId] = progress.completionPercentage;
            debugPrint(
                '[DEBUG] Added to progress map: ${progress.skillId} -> ${progress.completionPercentage}');
          }

          // Update goal progress based on skill progress
          for (var goal in _goals) {
            final skillId = goal.skill.id;
            if (skillProgressMap.containsKey(skillId)) {
              final newProgress = skillProgressMap[skillId]!;
              debugPrint(
                  '[DEBUG] Syncing goal ${goal.id} with progress $newProgress');

              // Only update if progress has changed
              if (goal.currentProgress != newProgress) {
                goal.currentProgress = newProgress;
                debugPrint(
                    '[DEBUG] Updated goal ${goal.id} progress to $newProgress');

                // Update goal in backend
                await updateGoal(
                  goalId: goal.id,
                  currentProgress: newProgress,
                );
              }
            }
          }
          debugPrint('[DEBUG] Goals after sync: $_goals');
        } else {
          _error = goalsResponse['error'] ?? 'Failed to load goals';
          debugPrint('[DEBUG] Error loading goals: $_error');
        }
      } else {
        _error = progressResponse.error ?? 'Failed to load progress';
        debugPrint('[DEBUG] Error loading progress: $_error');
      }
    } catch (e) {
      _error = e.toString();
      debugPrint('[DEBUG] Exception in fetchUserProgress: $_error');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Calculate weighted progress based on total resources
  Future<double> calculateWeightedProgress(String skillId) async {
    print('[DEBUG] Calculating weighted progress for skill $skillId');

    // Get completed resources count for this skill
    final completedCount =
        _completedResources.where((r) => r.skill.id == skillId).length;
    print('[DEBUG] Completed resources count: $completedCount');

    // Get total resources from cache or fetch from API
    List<rm.Resource>? totalResources = _resourceCache[skillId];
    if (totalResources == null) {
      print('[DEBUG] Fetching resources for skill $skillId');
      final response = await _resourceService.getResourcesBySkill(skillId);
      if (response.success && response.data != null) {
        totalResources = response.data!;
        _resourceCache[skillId] = totalResources;
      } else {
        print('[DEBUG] Failed to fetch resources: ${response.error}');
        return 0.0;
      }
    }

    final totalCount = totalResources.length;
    print('[DEBUG] Total resources count: $totalCount');

    if (totalCount == 0) {
      print('[DEBUG] No resources found for skill $skillId');
      return 0.0;
    }

    final progress = (completedCount / totalCount) * 100;
    print('[DEBUG] Calculated weighted progress: $progress');
    return progress.clamp(0.0, 100.0);
  }

  // Mark a resource as completed
  Future<void> markResourceCompleted(String skillId, String resourceId) async {
    print(
        '[DEBUG] Attempting to mark resource $resourceId for skill $skillId as completed');
    final response =
        await _progressService.markResourceComplete(skillId, resourceId);

    if (response.success) {
      print('[DEBUG] Resource marked completed successfully.');

      // Calculate new progress based on weighted resources
      final newProgress = await calculateWeightedProgress(skillId);
      print('[DEBUG] Calculated new weighted progress: $newProgress');

      // Update goal progress if exists
      final matchingGoal =
          _goals.firstWhereOrNull((goal) => goal.skill.id == skillId);
      if (matchingGoal != null) {
        print('[DEBUG] Found matching goal: ${matchingGoal.id}');
        final updateResult = await updateGoal(
          goalId: matchingGoal.id,
          currentProgress: newProgress,
        );
        print('[DEBUG] updateGoal call result: $updateResult');
      }

      // Clear resource cache for this skill to ensure fresh data
      _resourceCache.remove(skillId);

      // Refresh user progress
      print('[DEBUG] Fetching user progress after resource completion.');
      await fetchUserProgress();
      // Explicitly fetch goals again to ensure latest data
      await _progressService.getGoals().then((goalsResponse) {
        if (goalsResponse['success']) {
          _goals = List<GoalModel>.from(goalsResponse['data'] ?? []);
          print('[DEBUG] Goals refreshed after resource completion.');
        } else {
          print(
              '[DEBUG] Failed to refresh goals after resource completion: ${goalsResponse['error']}');
        }
      });

      notifyListeners();
    } else {
      _error = response.message ?? 'Failed to mark resource complete';
      notifyListeners();
      debugPrint('Failed to mark resource complete: ${response.message}');
    }
  }

  Future<Map<String, dynamic>> updateGoal({
    required String goalId,
    required double currentProgress,
  }) async {
    try {
      final result = await _progressService.updateGoal(
        goalId: goalId,
        currentProgress: currentProgress,
      );

      if (result['success']) {
        // Refresh goals after successful update
        await fetchUserProgress();
      }

      return result;
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // Check if a resource is completed
  bool isResourceCompleted(String resourceId) {
    return _completedResources.any((resource) => resource.id == resourceId);
  }

  // Toggle resource completion status
  Future<void> toggleResourceCompleted(
      String skillId, String resourceId) async {
    print('[DEBUG] Toggling resource $resourceId completion status');

    final isCompleted = isResourceCompleted(resourceId);
    print('[DEBUG] Current completion status: $isCompleted');

    if (isCompleted) {
      // Unmark as completed
      await unmarkResourceComplete(skillId, resourceId);
    } else {
      // Mark as completed
      await markResourceCompleted(skillId, resourceId);
    }

    // Refresh user progress
    await fetchUserProgress();
    notifyListeners();
  }

  Future<void> unmarkResourceComplete(String skillId, String resourceId) async {
    try {
      final response =
          await _progressService.unmarkResourceComplete(skillId, resourceId);
      if (response.success) {
        // Calculate new progress based on weighted resources
        final newProgress = await calculateWeightedProgress(skillId);
        print(
            '[DEBUG] Calculated new weighted progress after unmarking: $newProgress');

        // Update goal progress if exists
        final matchingGoal =
            _goals.firstWhereOrNull((goal) => goal.skill.id == skillId);
        if (matchingGoal != null) {
          print('[DEBUG] Updating goal progress after unmarking');
          await updateGoal(
            goalId: matchingGoal.id,
            currentProgress: newProgress,
          );
        }

        // Clear resource cache for this skill to ensure fresh data
        _resourceCache.remove(skillId);

        // Refresh user progress
        await fetchUserProgress();
        // Explicitly fetch goals again to ensure latest data
        await _progressService.getGoals().then((goalsResponse) {
          if (goalsResponse['success']) {
            _goals = List<GoalModel>.from(goalsResponse['data'] ?? []);
            print('[DEBUG] Goals refreshed after unmarking resource.');
          } else {
            print(
                '[DEBUG] Failed to refresh goals after unmarking resource: ${goalsResponse['error']}');
          }
        });

        notifyListeners();
      } else {
        _error = response.message ?? 'Failed to unmark resource';
        notifyListeners();
      }
    } catch (e) {
      print('Error in unmarkResourceComplete: $e');
      rethrow;
    }
  }
}
