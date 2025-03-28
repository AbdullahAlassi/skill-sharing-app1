class User {
  final String id;
  final String name;
  final String email;
  final String? profilePicture;
  final String? bio;
  final List<UserSkill> skills;
  final List<String> interests;
  final List<String> friends;
  final List<String> groups;
  final DateTime createdAt;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.profilePicture,
    this.bio,
    this.skills = const [],
    this.interests = const [],
    this.friends = const [],
    this.groups = const [],
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id'],
      name: json['name'],
      email: json['email'],
      profilePicture: json['profilePicture'],
      bio: json['bio'],
      skills:
          json['skills'] != null
              ? List<UserSkill>.from(
                json['skills'].map((x) => UserSkill.fromJson(x)),
              )
              : [],
      interests:
          json['interests'] != null
              ? List<String>.from(
                json['interests'].map((x) => x is String ? x : x['_id']),
              )
              : [],
      friends:
          json['friends'] != null
              ? List<String>.from(
                json['friends'].map((x) => x is String ? x : x['_id']),
              )
              : [],
      groups:
          json['groups'] != null
              ? List<String>.from(
                json['groups'].map((x) => x is String ? x : x['_id']),
              )
              : [],
      createdAt:
          json['createdAt'] != null
              ? DateTime.parse(json['createdAt'])
              : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {'name': name, 'email': email, 'bio': bio};
  }
}

class UserSkill {
  final String skillId;
  final String skillName;
  final String skillCategory;
  final String proficiency;
  final DateTime addedAt;

  UserSkill({
    required this.skillId,
    required this.skillName,
    required this.skillCategory,
    required this.proficiency,
    required this.addedAt,
  });

  factory UserSkill.fromJson(Map<String, dynamic> json) {
    return UserSkill(
      skillId: json['skill'] is String ? json['skill'] : json['skill']['_id'],
      skillName: json['skill'] is Map ? json['skill']['name'] : '',
      skillCategory: json['skill'] is Map ? json['skill']['category'] : '',
      proficiency: json['proficiency'],
      addedAt:
          json['addedAt'] != null
              ? DateTime.parse(json['addedAt'])
              : DateTime.now(),
    );
  }
}
