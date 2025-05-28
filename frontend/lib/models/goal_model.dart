import 'package:skill_sharing_app/models/skill_model.dart';
import 'package:skill_sharing_app/models/skill_category.dart';

enum GoalStatus { inProgress, completed, expired }

class GoalModel {
  final String id;
  final String userId;
  final Skill skill;
  final DateTime targetDate;
  double currentProgress;
  final GoalStatus status;
  final DateTime? achievedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  GoalModel({
    required this.id,
    required this.userId,
    required this.skill,
    required this.targetDate,
    required this.currentProgress,
    required this.status,
    this.achievedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory GoalModel.fromJson(Map<String, dynamic> json) {
    print('goal.skill runtimeType: ${json['skill'].runtimeType}');
    print('goal.user runtimeType: ${json['user'].runtimeType}');
    print('goal.targetDate runtimeType: ${json['targetDate'].runtimeType}');
    print(
        'goal.currentProgress runtimeType: ${json['currentProgress'].runtimeType}');
    return GoalModel(
      id: json['_id'] ?? json['id'],
      userId: json['user'] is Map
          ? json['user']['_id'] ?? json['user']['id']
          : json['user'],
      skill: json['skill'] is Map
          ? Skill.fromJson(json['skill'])
          : Skill(
              id: json['skill'],
              name: '',
              categoryId: '',
              categoryName: '',
              description: '',
              relatedSkills: [],
              createdBy: null,
              createdAt: DateTime.now(),
              difficultyLevel: 'Beginner',
              resources: [],
              roadmap: [],
              proficiency: null,
              recommendationReason: null,
            ),
      targetDate: DateTime.tryParse(json['targetDate'] ?? '') ?? DateTime.now(),
      currentProgress: (json['currentProgress'] as num?)?.toDouble() ?? 0.0,
      status: GoalStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
        orElse: () => GoalStatus.inProgress,
      ),
      achievedAt: json['achievedAt'] != null
          ? DateTime.parse(json['achievedAt'])
          : null,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'user': userId,
      'skill': skill.toJson(),
      'targetDate': targetDate.toIso8601String(),
      'currentProgress': currentProgress,
      'status': status.toString().split('.').last,
      'achievedAt': achievedAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  GoalModel copyWith({
    String? id,
    String? userId,
    Skill? skill,
    DateTime? targetDate,
    double? currentProgress,
    GoalStatus? status,
    DateTime? achievedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return GoalModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      skill: skill ?? this.skill,
      targetDate: targetDate ?? this.targetDate,
      currentProgress: currentProgress ?? this.currentProgress,
      status: status ?? this.status,
      achievedAt: achievedAt ?? this.achievedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
