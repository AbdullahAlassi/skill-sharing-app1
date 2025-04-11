class Skill {
  final String id;
  final String name;
  final String category;
  final String description;
  final List<String>? relatedSkillIds;
  final List<Skill>? relatedSkills;
  final String? createdBy;
  final DateTime createdAt;

  Skill({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    this.relatedSkillIds,
    this.relatedSkills,
    this.createdBy,
    required this.createdAt,
  });

  factory Skill.fromJson(Map<String, dynamic> json) {
    // Handle relatedSkills which could be a list of strings (IDs) or a list of objects
    List<String>? relatedSkillIds;
    List<Skill>? relatedSkills;

    if (json['relatedSkills'] != null) {
      if (json['relatedSkills'] is List) {
        final relatedList = json['relatedSkills'] as List;

        if (relatedList.isNotEmpty) {
          if (relatedList.first is String) {
            // If it's a list of strings (IDs)
            relatedSkillIds = List<String>.from(relatedList);
          } else if (relatedList.first is Map) {
            // If it's a list of objects
            relatedSkills =
                relatedList
                    .map((x) => Skill.fromJson(x as Map<String, dynamic>))
                    .toList();
          }
        } else {
          // Empty list
          relatedSkillIds = [];
        }
      }
    }

    // Handle different ID field names
    final id = json['_id'] ?? json['id'] ?? '';

    // Handle different date formats
    DateTime createdAt;
    try {
      createdAt =
          json['createdAt'] != null
              ? DateTime.parse(json['createdAt'].toString())
              : DateTime.now();
    } catch (e) {
      createdAt = DateTime.now();
    }

    return Skill(
      id: id.toString(),
      name: json['name']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      relatedSkillIds: relatedSkillIds,
      relatedSkills: relatedSkills,
      createdBy: json['createdBy']?.toString(),
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'description': description,
      'relatedSkills':
          relatedSkillIds ?? relatedSkills?.map((x) => x.toJson()).toList(),
      'createdBy': createdBy,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
