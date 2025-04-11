import 'package:frontend/models/skill_model.dart';

class User {
  final String id;
  final String name;
  final String email;
  final String? bio;
  final String? profilePicture;
  final List<UserSkill> skills;
  final List<Skill>? interests;
  final List<String>? friends;
  final List<String>? groups;
  final DateTime createdAt;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.bio,
    this.profilePicture,
    this.skills = const [],
    this.interests,
    this.friends,
    this.groups,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      bio: json['bio'],
      profilePicture: json['profilePicture'],
      skills:
          json['skills'] != null
              ? List<UserSkill>.from(
                json['skills'].map((x) => UserSkill.fromJson(x)),
              )
              : [],
      interests:
          json['interests'] != null
              ? List<Skill>.from(
                json['interests'].map((x) => Skill.fromJson(x)),
              )
              : null,
      friends:
          json['friends'] != null ? List<String>.from(json['friends']) : null,
      groups: json['groups'] != null ? List<String>.from(json['groups']) : null,
      createdAt:
          json['createdAt'] != null
              ? DateTime.parse(json['createdAt'])
              : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'bio': bio,
      'profilePicture': profilePicture,
      'skills': skills.map((x) => x.toJson()).toList(),
      'interests': interests?.map((x) => x.toJson()).toList(),
      'friends': friends,
      'groups': groups,
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
      skill:
          json['skill'] is Map
              ? Skill.fromJson(json['skill'])
              : Skill(
                id: json['skill'] ?? '',
                name: '',
                category: '',
                description: '',
                createdAt: DateTime.now(),
              ),

      proficiency: json['proficiency'] ?? 'Beginner',
    );
  }

  Map<String, dynamic> toJson() {
    return {'skill': skill.toJson(), 'proficiency': proficiency};
  }
}
