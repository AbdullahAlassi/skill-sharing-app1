import '../models/skill_model.dart';
import 'api_client.dart';

class SkillService {
  final ApiClient _apiClient;

  SkillService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  // Get all skills
  Future<ApiResponse<List<Skill>>> getSkills() async {
    return await _apiClient.get<List<Skill>>(
      'skills',
      (json) => List<Skill>.from(json.map((x) => Skill.fromJson(x))),
    );
  }

  // Get skill by ID
  Future<ApiResponse<Skill>> getSkillById(String id) async {
    return await _apiClient.get<Skill>(
      'skills/$id',
      (json) => Skill.fromJson(json),
    );
  }

  // Create a new skill
  Future<ApiResponse<Skill>> createSkill(
    String name,
    String category,
    String description,
    List<String> relatedSkills,
  ) async {
    return await _apiClient.post<Skill>('skills', {
      'name': name,
      'category': category,
      'description': description,
      'relatedSkills': relatedSkills,
    }, (json) => Skill.fromJson(json));
  }

  // Update a skill
  Future<ApiResponse<Skill>> updateSkill(
    String id,
    String name,
    String category,
    String description,
    List<String> relatedSkills,
  ) async {
    return await _apiClient.put<Skill>('skills/$id', {
      'name': name,
      'category': category,
      'description': description,
      'relatedSkills': relatedSkills,
    }, (json) => Skill.fromJson(json));
  }

  // Get all skill categories
  Future<ApiResponse<List<String>>> getCategories() async {
    return await _apiClient.get<List<String>>(
      'skills/categories',
      (json) => List<String>.from(json),
    );
  }

  // Get skill recommendations for user
  Future<ApiResponse<List<Skill>>> getRecommendations() async {
    return await _apiClient.get<List<Skill>>(
      'skills/recommendations',
      (json) => List<Skill>.from(json.map((x) => Skill.fromJson(x))),
    );
  }
}
