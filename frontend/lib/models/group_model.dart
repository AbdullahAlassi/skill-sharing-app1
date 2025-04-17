import 'package:frontend/models/skill_model.dart';

class Group {
  final String id;
  final String name;
  final String description;
  final String? image;
  final List<Skill> relatedSkills;
  final String creatorId;
  final String? creatorName;
  final List<GroupMember> members;
  final bool isPublic;
  final DateTime createdAt;

  Group({
    required this.id,
    required this.name,
    required this.description,
    this.image,
    this.relatedSkills = const [],
    required this.creatorId,
    this.creatorName,
    this.members = const [],
    this.isPublic = true,
    required this.createdAt,
  });

  factory Group.fromJson(Map<String, dynamic> json) {
    return Group(
      id: json['_id'],
      name: json['name'],
      description: json['description'],
      image: json['image'],
      relatedSkills: json['relatedSkills'] != null
          ? List<Skill>.from(
              json['relatedSkills'].map((x) => Skill.fromJson(x)),
            )
          : [],
      creatorId:
          json['creator'] is String ? json['creator'] : json['creator']['_id'],
      creatorName: json['creator'] is Map ? json['creator']['name'] : null,
      members: json['members'] != null
          ? List<GroupMember>.from(
              json['members'].map((x) => GroupMember.fromJson(x)),
            )
          : [],
      isPublic: json['isPublic'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'relatedSkills': relatedSkills.map((skill) => skill.id).toList(),
      'isPublic': isPublic,
    };
  }

  bool get isUserMember => members.any(
        (m) => m.userId == 'currentUserId',
      ); // Replace with actual user ID check
  bool get isUserAdmin => members.any(
        (m) => m.userId == 'currentUserId' && m.role == 'Admin',
      ); // Replace with actual user ID check
}

class GroupMember {
  final String userId;
  final String? userName;
  final String? userProfilePicture;
  final String role;
  final DateTime joinedAt;

  GroupMember({
    required this.userId,
    this.userName,
    this.userProfilePicture,
    required this.role,
    required this.joinedAt,
  });

  factory GroupMember.fromJson(Map<String, dynamic> json) {
    return GroupMember(
      userId: json['user'] is String ? json['user'] : json['user']['_id'],
      userName: json['user'] is Map ? json['user']['name'] : null,
      userProfilePicture:
          json['user'] is Map ? json['user']['profilePicture'] : null,
      role: json['role'],
      joinedAt: json['joinedAt'] != null
          ? DateTime.parse(json['joinedAt'])
          : DateTime.now(),
    );
  }
}
