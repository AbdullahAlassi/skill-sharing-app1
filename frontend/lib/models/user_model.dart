import 'skill_model.dart';
import 'skill_proficiency_model.dart';
import 'skill_category.dart';

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
  final bool isAdmin;
  final DateTime createdAt;
  final String? preferredDifficulty;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.profilePicture,
    this.bio,
    List<String>? favoriteCategories,
    List<String>? friends,
    List<String>? groups,
    List<String>? createdSkills,
    List<String>? skills,
    this.skillProficiencies,
    this.isAdmin = false,
    required this.createdAt,
    this.preferredDifficulty,
  })  : favoriteCategories = List<String>.from(favoriteCategories ?? []),
        friends = List<String>.from(friends ?? []),
        groups = List<String>.from(groups ?? []),
        createdSkills = List<String>.from(createdSkills ?? []),
        skills = List<String>.from(skills ?? []);

  factory User.fromJson(Map<String, dynamic> json) {
    print('\n=== User.fromJson Debug ===');
    print('Raw JSON input: $json');

    final userData = json['data'] ?? json;
    print('Extracted user data: $userData');

    // Handle skills array with detailed logging
    print('\nProcessing skills array:');
    print('Raw skills from JSON: ${userData['skills']}');
    print('Raw skills type: ${userData['skills']?.runtimeType}');

    final skills = <String>[];
    final proficiencies = <SkillProficiency>[];

    if (userData['skills'] != null && userData['skills'] is List) {
      for (final skillObj in userData['skills']) {
        print('Processing skill object: $skillObj');
        if (skillObj is String) {
          // Handle simple string ID
          skills.add(skillObj);
          print('Added skill ID (string): $skillObj');
        } else if (skillObj is Map<String, dynamic>) {
          // Handle complex object with skill and proficiency
          final skillData = skillObj['skill'];
          if (skillData is Map<String, dynamic>) {
            final skillId = skillData['_id']?.toString() ?? '';
            if (skillId.isNotEmpty) {
              skills.add(skillId);
              print('Added skill ID (from object): $skillId');
            }

            if (skillObj['proficiency'] != null) {
              try {
                proficiencies.add(SkillProficiency(
                  skillId: skillId,
                  level: ProficiencyLevel.values.firstWhere(
                    (e) =>
                        e.toString().split('.').last.toLowerCase() ==
                        (skillObj['proficiency'] as String).toLowerCase(),
                    orElse: () => ProficiencyLevel.beginner,
                  ),
                  startedLearning: DateTime.parse(
                      skillObj['addedAt'] ?? DateTime.now().toIso8601String()),
                ));
              } catch (e) {
                print('Error creating SkillProficiency: $e');
              }
            }
          }
        }
      }
    }

    // Handle createdSkills with detailed logging
    print('\nProcessing createdSkills:');
    print('Raw createdSkills from JSON: ${userData['createdSkills']}');
    print('Raw createdSkills type: ${userData['createdSkills']?.runtimeType}');

    final createdSkills = (userData['createdSkills'] as List<dynamic>?)
            ?.map((e) {
              print(
                  'Processing createdSkill item: $e (type: ${e.runtimeType})');
              if (e is String) {
                print('  - String item: $e');
                return e;
              }
              if (e is Map<String, dynamic> && e.containsKey('_id')) {
                print('  - Map item with _id: ${e['_id']}');
                return e['_id'] as String;
              }
              print('  - Invalid item type, returning empty string');
              return '';
            })
            .where((id) => id.isNotEmpty)
            .toList() ??
        [];

    print('\nFinal createdSkills:');
    print('Converted createdSkills: $createdSkills');
    print('Converted createdSkills type: ${createdSkills.runtimeType}');
    print('=== End User.fromJson Debug ===\n');

    return User(
      id: userData['_id']?.toString() ?? userData['id']?.toString() ?? '',
      name: userData['name']?.toString() ?? '',
      email: userData['email']?.toString() ?? '',
      profilePicture: userData['profilePicture']?.toString(),
      bio: userData['bio']?.toString(),
      favoriteCategories:
          List<String>.from(userData['favoriteCategories'] ?? []),
      friends: List<String>.from(userData['friends'] ?? []),
      groups: List<String>.from(userData['groups'] ?? []),
      createdSkills: createdSkills,
      skills: skills,
      skillProficiencies: proficiencies,
      createdAt: userData['createdAt'] != null
          ? DateTime.parse(userData['createdAt'])
          : DateTime.now(),
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
      'isAdmin': isAdmin,
      'createdAt': createdAt.toIso8601String(),
      'preferredDifficulty': preferredDifficulty,
    };
  }

  User copyWith({
    String? id,
    String? name,
    String? email,
    String? profilePicture,
    String? bio,
    List<String>? favoriteCategories,
    List<String>? friends,
    List<String>? groups,
    List<String>? createdSkills,
    List<String>? skills,
    List<SkillProficiency>? skillProficiencies,
    bool? isAdmin,
    DateTime? createdAt,
    String? preferredDifficulty,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      profilePicture: profilePicture ?? this.profilePicture,
      bio: bio ?? this.bio,
      favoriteCategories:
          List<String>.from(favoriteCategories ?? this.favoriteCategories),
      friends: List<String>.from(friends ?? this.friends),
      groups: List<String>.from(groups ?? this.groups),
      createdSkills: List<String>.from(createdSkills ?? this.createdSkills),
      skills: List<String>.from(skills ?? this.skills),
      skillProficiencies: skillProficiencies ?? this.skillProficiencies,
      isAdmin: isAdmin ?? this.isAdmin,
      createdAt: createdAt ?? this.createdAt,
      preferredDifficulty: preferredDifficulty ?? this.preferredDifficulty,
    );
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
              difficultyLevel: '',
              resources: [],
              createdBy: null,
              roadmap: [],
            ),
      proficiency: json['proficiency'] ?? 'Beginner',
    );
  }

  Map<String, dynamic> toJson() {
    return {'skill': skill.toJson(), 'proficiency': proficiency};
  }
}
