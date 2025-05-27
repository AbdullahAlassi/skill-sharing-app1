import 'resource_model.dart';

class Skill {
  final String id;
  final String name;
  final String category;
  final String description;
  final String difficultyLevel;
  final List<String> relatedSkills;
  final List<Resource> resources;
  final String? createdBy;
  final String? proficiency;

  Skill({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.difficultyLevel,
    required this.relatedSkills,
    required this.resources,
    this.createdBy,
    this.proficiency,
  });

  factory Skill.fromJson(Map<String, dynamic> json) {
    return Skill(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      category: json['category'] ?? '',
      description: json['description'] ?? '',
      difficultyLevel: json['difficultyLevel'] ?? 'beginner',
      relatedSkills: List<String>.from(json['relatedSkills'] ?? []),
      resources: (json['resources'] as List<dynamic>?)
              ?.map((r) => Resource.fromJson(r))
              .toList() ??
          [],
      createdBy: json['createdBy'],
      proficiency: json['proficiency'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'category': category,
      'description': description,
      'difficultyLevel': difficultyLevel,
      'relatedSkills': relatedSkills,
      'resources': resources.map((r) => r.toJson()).toList(),
      'createdBy': createdBy,
      'proficiency': proficiency,
    };
  }

  Skill copyWith({
    String? id,
    String? name,
    String? category,
    String? description,
    String? difficultyLevel,
    List<String>? relatedSkills,
    List<Resource>? resources,
    String? createdBy,
    String? proficiency,
  }) {
    return Skill(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      description: description ?? this.description,
      difficultyLevel: difficultyLevel ?? this.difficultyLevel,
      relatedSkills: relatedSkills ?? this.relatedSkills,
      resources: resources ?? this.resources,
      createdBy: createdBy ?? this.createdBy,
      proficiency: proficiency ?? this.proficiency,
    );
  }
}
