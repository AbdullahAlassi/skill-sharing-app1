import 'package:frontend/models/skill_model.dart';
import 'skill_proficiency_model.dart';

class User {
  final String id;
  final String name;
  final String email;
  final String? profilePicture;
  final String? bio;
  final List<String> favoriteCategories;
  final List<String> friends;
  final List<String> groups;
  final List<String> createdSkills;
  final List<String> skills;
  final List<SkillProficiency>? skillProficiencies;
  final DateTime createdAt;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.profilePicture,
    this.bio,
    required this.favoriteCategories,
    required this.friends,
    required this.groups,
    required this.createdSkills,
    required this.skills,
    this.skillProficiencies,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    // Extract skill IDs and proficiencies from the nested skills array
    List<String> skills = [];
    Map<String, String> skillProficiencies = {};
    if (json['skills'] != null && json['skills'] is List) {
      for (var skillObj in json['skills']) {
        if (skillObj is Map && skillObj['skill'] is Map) {
          final skillId = skillObj['skill']['_id'].toString();
          skills.add(skillId);
          skillProficiencies[skillId] = skillObj['proficiency'] ?? 'Beginner';
        }
      }
    }

    return User(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      profilePicture: json['profilePicture'],
      bio: json['bio'],
      favoriteCategories: List<String>.from(json['favoriteCategories'] ?? []),
      friends: List<String>.from(json['friends'] ?? []),
      groups: List<String>.from(json['groups'] ?? []),
      createdSkills: List<String>.from(json['createdSkills'] ?? []),
      skills: skills,
      skillProficiencies: json['skills'] != null
          ? List<SkillProficiency>.from(
              (json['skills'] as List).map((skillObj) {
                if (skillObj is Map && skillObj['skill'] is Map) {
                  return SkillProficiency(
                    skillId: skillObj['skill']['_id'].toString(),
                    level: ProficiencyLevel.values.firstWhere(
                      (e) =>
                          e.toString().split('.').last.toLowerCase() ==
                          (skillObj['proficiency'] as String).toLowerCase(),
                      orElse: () => ProficiencyLevel.beginner,
                    ),
                    startedLearning: DateTime.parse(skillObj['addedAt']),
                  );
                }
                return SkillProficiency(
                  skillId: '',
                  level: ProficiencyLevel.beginner,
                  startedLearning: DateTime.now(),
                );
              }),
            )
          : null,
      createdAt:
          DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'email': email,
      'profilePicture': profilePicture,
      'bio': bio,
      'favoriteCategories': favoriteCategories,
      'friends': friends,
      'groups': groups,
      'createdSkills': createdSkills,
      'skills': skills,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

class UserSkill {
  final Skill skill;
  final String proficiency;

  UserSkill({required this.skill, required this.proficiency});

  factory UserSkill.fromJson(Map<String, dynamic> json) {
    return UserSkill(
      skill: json['skill'] is Map
          ? Skill.fromJson(json['skill'])
          : Skill(
              id: json['skill'] ?? '',
              name: '',
              category: '',
              description: '',
              relatedSkills: [],
              createdAt: DateTime.now(),
            ),
      proficiency: json['proficiency'] ?? 'Beginner',
    );
  }

  Map<String, dynamic> toJson() {
    return {'skill': skill.toJson(), 'proficiency': proficiency};
  }
}
