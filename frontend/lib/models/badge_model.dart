class BadgeModel {
  final String id;
  final String name;
  final String description;
  final String icon;
  final String type;
  final bool isUnlocked;
  final DateTime? unlockedAt;

  BadgeModel({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.type,
    this.isUnlocked = false,
    this.unlockedAt,
  });

  factory BadgeModel.fromJson(Map<String, dynamic> json) {
    return BadgeModel(
      id: json['_id'],
      name: json['name'],
      description: json['description'],
      icon: json['icon'],
      type: json['type'],
      isUnlocked: json['isUnlocked'] ?? false,
      unlockedAt: json['unlockedAt'] != null
          ? DateTime.parse(json['unlockedAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'description': description,
      'icon': icon,
      'type': type,
      'isUnlocked': isUnlocked,
      'unlockedAt': unlockedAt?.toIso8601String(),
    };
  }
}

// Badge types
class BadgeType {
  static const String firstGoal = 'first_goal';
  static const String goalStreak = 'goal_streak';
  static const String perfectWeek = 'perfect_week';
  static const String skillMaster = 'skill_master';
  static const String earlyBird = 'early_bird';
  static const String nightOwl = 'night_owl';
  static const String socialButterfly = 'social_butterfly';
  static const String mentor = 'mentor';
  static const String learner = 'learner';
  static const String achiever = 'achiever';
}
