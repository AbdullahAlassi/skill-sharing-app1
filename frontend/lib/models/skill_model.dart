class Skill {
  final String id;
  final String name;
  final String category;
  final String description;
  final List<String> relatedSkills;
  final String? createdBy;
  final DateTime createdAt;

  Skill({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    this.relatedSkills = const [],
    this.createdBy,
    required this.createdAt,
  });

  factory Skill.fromJson(Map<String, dynamic> json) {
    return Skill(
      id: json['_id'],
      name: json['name'],
      category: json['category'],
      description: json['description'],
      relatedSkills:
          json['relatedSkills'] != null
              ? List<String>.from(
                json['relatedSkills'].map((x) => x is String ? x : x['_id']),
              )
              : [],
      createdBy:
          json['createdBy'] is String
              ? json['createdBy']
              : json['createdBy']?['_id'],
      createdAt:
          json['createdAt'] != null
              ? DateTime.parse(json['createdAt'])
              : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'category': category,
      'description': description,
      'relatedSkills': relatedSkills,
    };
  }
}
