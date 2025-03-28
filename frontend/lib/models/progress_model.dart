import 'package:frontend/models/skill_model.dart';

class Progress {
  final String id;
  final String userId;
  final Skill skill;
  final String goal;
  final DateTime? targetDate;
  final int progress;
  final List<Milestone> milestones;
  final DateTime createdAt;
  final DateTime updatedAt;

  Progress({
    required this.id,
    required this.userId,
    required this.skill,
    required this.goal,
    this.targetDate,
    this.progress = 0,
    this.milestones = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  factory Progress.fromJson(Map<String, dynamic> json) {
    return Progress(
      id: json['_id'],
      userId: json['user'],
      skill: Skill.fromJson(json['skill']),
      goal: json['goal'],
      targetDate:
          json['targetDate'] != null
              ? DateTime.parse(json['targetDate'])
              : null,
      progress: json['progress'],
      milestones:
          json['milestones'] != null
              ? List<Milestone>.from(
                json['milestones'].map((x) => Milestone.fromJson(x)),
              )
              : [],
      createdAt:
          json['createdAt'] != null
              ? DateTime.parse(json['createdAt'])
              : DateTime.now(),
      updatedAt:
          json['updatedAt'] != null
              ? DateTime.parse(json['updatedAt'])
              : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'skillId': skill.id,
      'goal': goal,
      'targetDate': targetDate?.toIso8601String(),
      'progress': progress,
    };
  }
}

class Milestone {
  final String id;
  final String title;
  final String? description;
  final bool completed;
  final DateTime? completedAt;

  Milestone({
    required this.id,
    required this.title,
    this.description,
    this.completed = false,
    this.completedAt,
  });

  factory Milestone.fromJson(Map<String, dynamic> json) {
    return Milestone(
      id: json['_id'],
      title: json['title'],
      description: json['description'],
      completed: json['completed'],
      completedAt:
          json['completedAt'] != null
              ? DateTime.parse(json['completedAt'])
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {'title': title, 'description': description, 'completed': completed};
  }
}
