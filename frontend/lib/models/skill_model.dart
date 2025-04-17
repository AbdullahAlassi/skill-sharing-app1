class Skill {
  final String id;
  final String name;
  final String category;
  final String description;
  final List<String> relatedSkills;
  String? proficiency;
  final String? creatorId;
  final DateTime createdAt;

  Skill({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.relatedSkills,
    this.proficiency,
    this.creatorId,
    required this.createdAt,
  });

  factory Skill.fromJson(Map<String, dynamic> json) {
    return Skill(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      category: json['category'] ?? '',
      description: json['description'] ?? '',
      relatedSkills: List<String>.from(json['relatedSkills'] ?? []),
      proficiency: json['proficiency']?.toString(),
      creatorId: json['creatorId'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
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
      'creatorId': creatorId,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
