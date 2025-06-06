class Progress {
  final String id;
  final String skillId;
  final String userId;
  final String goal;
  final DateTime? targetDate;
  final double progress;
  final List<Milestone>? milestones;
  final DateTime createdAt;
  final DateTime updatedAt;

  Progress({
    required this.id,
    required this.skillId,
    required this.userId,
    required this.goal,
    this.targetDate,
    required this.progress,
    this.milestones,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Progress.fromJson(Map<String, dynamic> json) {
    print('[DEBUG] Progress JSON: $json');
    print('Progress progress: ${(json['progress'] as num?)?.toDouble()}');

    // Handle milestones with proper type checking
    List<Milestone>? parsedMilestones;
    if (json['milestones'] != null) {
      if (json['milestones'] is List) {
        parsedMilestones = List<Milestone>.from(
          json['milestones']
              .map((x) => Milestone.fromJson(x as Map<String, dynamic>)),
        );
      } else {
        print(
            '[DEBUG] Warning: milestones is not a List: ${json['milestones']}');
        parsedMilestones = [];
      }
    }

    return Progress(
      id: json['_id'] ?? json['id'] ?? '',
      skillId: json['skillId'] ?? '',
      userId: json['userId'] ?? '',
      goal: json['goal'] ?? '',
      targetDate: json['targetDate'] != null
          ? DateTime.parse(json['targetDate'])
          : null,
      progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
      milestones: parsedMilestones,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'skillId': skillId,
      'userId': userId,
      'goal': goal,
      'targetDate': targetDate?.toIso8601String(),
      'progress': progress,
      'milestones': milestones?.map((x) => x.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

class Milestone {
  final String id;
  final String title;
  final String? description;
  final bool completed;
  final DateTime createdAt;

  Milestone({
    required this.id,
    required this.title,
    this.description,
    required this.completed,
    required this.createdAt,
  });

  factory Milestone.fromJson(Map<String, dynamic> json) {
    return Milestone(
      id: json['_id'] ?? json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'],
      completed: json['completed'] ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'completed': completed,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
