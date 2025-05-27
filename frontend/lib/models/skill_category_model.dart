class SkillCategory {
  final String id;
  final String name;
  final String icon;
  final String description;
  final int skillCount;

  SkillCategory({
    required this.id,
    required this.name,
    required this.icon,
    required this.description,
    required this.skillCount,
  });

  factory SkillCategory.fromJson(Map<String, dynamic> json) {
    return SkillCategory(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      icon: json['icon'] ?? '',
      description: json['description'] ?? '',
      skillCount: json['skillCount'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'icon': icon,
      'description': description,
      'skillCount': skillCount,
    };
  }
}
