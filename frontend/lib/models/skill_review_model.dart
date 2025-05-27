class SkillReview {
  final String id;
  final String skillId;
  final String userId;
  final String userName;
  final int rating;
  final String comment;
  final DateTime createdAt;
  final DateTime updatedAt;

  SkillReview({
    required this.id,
    required this.skillId,
    required this.userId,
    required this.userName,
    required this.rating,
    required this.comment,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SkillReview.fromJson(Map<String, dynamic> json) {
    return SkillReview(
      id: json['_id'],
      skillId: json['skill'],
      userId: json['user']['_id'],
      userName: json['user']['name'],
      rating: json['rating'],
      comment: json['comment'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'skill': skillId,
      'user': {
        '_id': userId,
        'name': userName,
      },
      'rating': rating,
      'comment': comment,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
