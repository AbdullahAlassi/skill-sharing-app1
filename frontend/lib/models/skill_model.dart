import 'package:skill_sharing_app/models/user_model.dart';
import 'package:skill_sharing_app/models/resource_model.dart' as rm;
import 'resource_model.dart';
import 'package:skill_sharing_app/models/skill_category.dart';

class Resource {
  final String id;
  final String name;
  final String category;
  final String description;
  final List<String> relatedSkills;
  String? proficiency;
  final List<Map<String, dynamic>>? roadmap;
  final String? createdBy;
  final DateTime createdAt;
  final String difficultyLevel;
  final List<Resource> resources;
  final String? recommendationReason;

  Resource({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.relatedSkills,
    this.proficiency,
    this.roadmap,
    required this.createdBy,
    required this.createdAt,
    required this.difficultyLevel,
    required this.resources,
    this.recommendationReason,
  });

  factory Resource.fromJson(Map<String, dynamic> json) {
    return Resource(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      category: json['category'] ?? '',
      description: json['description'] ?? '',
      relatedSkills: List<String>.from(json['relatedSkills'] ?? []),
      proficiency: json['proficiency']?.toString(),
      roadmap: json['roadmap'] != null
          ? List<Map<String, dynamic>>.from(json['roadmap'])
          : null,
      createdBy: json['createdBy']?.toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      difficultyLevel: json['difficultyLevel'] ?? 'Beginner',
      resources: (json['resources'] as List<dynamic>?)
              ?.map((r) => Resource.fromJson(r))
              .toList() ??
          [],
      recommendationReason: json['recommendationReason'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'description': description,
      'relatedSkills': relatedSkills,
      'proficiency': proficiency,
      'roadmap': roadmap,
      'createdBy': createdBy,
      'createdAt': createdAt.toIso8601String(),
      'difficultyLevel': difficultyLevel,
      'resources': resources.map((r) => r.toJson()).toList(),
      'recommendationReason': recommendationReason,
    };
  }

  Resource copyWith({
    String? id,
    String? name,
    String? category,
    String? description,
    List<String>? relatedSkills,
    String? proficiency,
    List<Map<String, dynamic>>? roadmap,
    String? createdBy,
    DateTime? createdAt,
    String? difficultyLevel,
    List<Resource>? resources,
    String? recommendationReason,
  }) {
    return Resource(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      description: description ?? this.description,
      relatedSkills: relatedSkills ?? this.relatedSkills,
      proficiency: proficiency ?? this.proficiency,
      roadmap: roadmap ?? this.roadmap,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      difficultyLevel: difficultyLevel ?? this.difficultyLevel,
      resources: resources ?? this.resources,
      recommendationReason: recommendationReason ?? this.recommendationReason,
    );
  }
}

// Simple User model to handle populated creator data
class SimpleUser {
  final String id;
  final String name;
  final String? profilePicture;

  SimpleUser({
    required this.id,
    required this.name,
    this.profilePicture,
  });

  factory SimpleUser.fromJson(Map<String, dynamic> json) {
    return SimpleUser(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      profilePicture: json['profilePicture']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'profilePicture': profilePicture,
    };
  }
}

class Skill {
  final String id;
  final String name;
  final String categoryId;
  final String categoryName;
  final String description;
  final List<String> relatedSkills;
  final String? proficiency;
  final String difficultyLevel;
  final List<String> roadmap;
  final SimpleUser? createdBy;
  final DateTime createdAt;
  final List<rm.Resource> resources;
  final String? recommendationReason;

  Skill({
    required this.id,
    required this.name,
    required this.categoryId,
    required this.categoryName,
    required this.description,
    required this.relatedSkills,
    this.proficiency,
    required this.difficultyLevel,
    required this.roadmap,
    this.createdBy,
    required this.createdAt,
    this.resources = const [],
    this.recommendationReason,
  });

  factory Skill.fromJson(Map<String, dynamic> json) {
    String categoryId = '';
    String categoryName = '';
    if (json['category'] is Map) {
      categoryId = json['category']['_id']?.toString() ?? '';
      categoryName = json['category']['name']?.toString() ?? '';
    } else {
      categoryId = json['category']?.toString() ?? '';
      categoryName = '';
    }

    // Handle createdBy which can be either a string or an object
    SimpleUser? createdBy;
    if (json['createdBy'] is Map) {
      createdBy = SimpleUser.fromJson(json['createdBy']);
    } else if (json['createdBy'] != null) {
      createdBy = SimpleUser(
        id: json['createdBy'].toString(),
        name: '',
      );
    }

    return Skill(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      categoryId: categoryId,
      categoryName: categoryName,
      description: json['description']?.toString() ?? '',
      relatedSkills: (json['relatedSkills'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      proficiency: json['proficiency']?.toString(),
      difficultyLevel: json['difficultyLevel']?.toString() ?? 'Beginner',
      createdBy: createdBy,
      roadmap: (json['roadmap'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      resources: (json['resources'] as List<dynamic>?)
              ?.map((e) => rm.Resource.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'].toString())
          : DateTime.now(),
      recommendationReason: json['recommendationReason'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': categoryId,
      'categoryName': categoryName,
      'description': description,
      'relatedSkills': relatedSkills,
      'proficiency': proficiency,
      'roadmap': roadmap,
      'createdBy': createdBy?.toJson(),
      'createdAt': createdAt.toIso8601String(),
      'difficultyLevel': difficultyLevel,
      'resources': resources.map((r) => r.toJson()).toList(),
      'recommendationReason': recommendationReason,
    };
  }

  String get categoryDisplayName => categoryName;

  Skill copyWith({
    String? id,
    String? name,
    String? categoryId,
    String? categoryName,
    String? description,
    List<String>? relatedSkills,
    String? proficiency,
    String? difficultyLevel,
    List<String>? roadmap,
    SimpleUser? createdBy,
    DateTime? createdAt,
    List<rm.Resource>? resources,
    String? recommendationReason,
  }) {
    return Skill(
      id: id ?? this.id,
      name: name ?? this.name,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      description: description ?? this.description,
      relatedSkills: relatedSkills ?? this.relatedSkills,
      proficiency: proficiency ?? this.proficiency,
      difficultyLevel: difficultyLevel ?? this.difficultyLevel,
      roadmap: roadmap ?? this.roadmap,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      resources: resources ?? this.resources,
      recommendationReason: recommendationReason ?? this.recommendationReason,
    );
  }
}
