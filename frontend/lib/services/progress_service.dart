import '../models/progress_model.dart';
import 'api_client.dart';

class ProgressService {
  final ApiClient _apiClient;

  ProgressService({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  // Get all progress for current user
  Future<ApiResponse<List<Progress>>> getUserProgress() async {
    return await _apiClient.get<List<Progress>>(
      'progress',
      (json, _) => (json as List).map((x) => Progress.fromJson(x)).toList(),
    );
  }

  // Get progress by ID
  Future<ApiResponse<Progress>> getProgressById(String id) async {
    return await _apiClient.get<Progress>(
      'progress/$id',
      (json, _) => Progress.fromJson(json),
    );
  }

  // Create a new progress tracking
  Future<ApiResponse<Progress>> createProgress(
    String skillId,
    String goal,
    DateTime? targetDate,
    List<Map<String, dynamic>>? milestones,
  ) async {
    return await _apiClient.post<Progress>('progress', {
      'skillId': skillId,
      'goal': goal,
      'targetDate': targetDate?.toIso8601String(),
      'milestones': milestones,
    }, (json, _) => Progress.fromJson(json));
  }

  // Update progress
  Future<ApiResponse<Progress>> updateProgress(
    String id,
    String? goal,
    DateTime? targetDate,
    int? progress,
  ) async {
    return await _apiClient.put<Progress>('progress/$id', {
      if (goal != null) 'goal': goal,
      if (targetDate != null) 'targetDate': targetDate.toIso8601String(),
      if (progress != null) 'progress': progress,
    }, (json, _) => Progress.fromJson(json));
  }

  // Delete progress
  Future<ApiResponse<Map<String, dynamic>>> deleteProgress(String id) async {
    return await _apiClient.delete<Map<String, dynamic>>(
      'progress/$id',
      (json, _) => json as Map<String, dynamic>,
    );
  }

  // Add milestone to progress
  Future<ApiResponse<List<Milestone>>> addMilestone(
    String id,
    String title,
    String? description,
  ) async {
    return await _apiClient.post<List<Milestone>>(
      'progress/$id/milestone',
      {'title': title, 'description': description},
      (json, _) => (json as List).map((x) => Milestone.fromJson(x)).toList(),
    );
  }

  // Update milestone
  Future<ApiResponse<List<Milestone>>> updateMilestone(
    String progressId,
    String milestoneId,
    String? title,
    String? description,
    bool? completed,
  ) async {
    return await _apiClient.put<List<Milestone>>(
      'progress/$progressId/milestone/$milestoneId',
      {
        if (title != null) 'title': title,
        if (description != null) 'description': description,
        if (completed != null) 'completed': completed,
      },
      (json, _) => (json as List).map((x) => Milestone.fromJson(x)).toList(),
    );
  }
}
