import 'package:flutter/foundation.dart';

enum ProficiencyLevel { beginner, intermediate, advanced }

class SkillProficiency {
  final String skillId;
  final ProficiencyLevel level;
  final DateTime startedLearning;
  final List<String> tags;

  SkillProficiency({
    required this.skillId,
    required this.level,
    required this.startedLearning,
    this.tags = const [],
  });

  factory SkillProficiency.fromJson(Map<String, dynamic> json) {
    return SkillProficiency(
      skillId: json['skillId'],
      level: ProficiencyLevel.values.firstWhere(
        (e) => e.toString() == 'ProficiencyLevel.${json['level']}',
        orElse: () => ProficiencyLevel.beginner,
      ),
      startedLearning: DateTime.parse(json['startedLearning']),
      tags: List<String>.from(json['tags'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'skillId': skillId,
      'level': level.toString().split('.').last,
      'startedLearning': startedLearning.toIso8601String(),
      'tags': tags,
    };
  }
}
