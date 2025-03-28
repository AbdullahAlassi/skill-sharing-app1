import 'skill_model.dart';

class Resource {
  final String id;
  final String title;
  final String description;
  final String link;
  final String type;
  final Skill skill;
  final String addedBy;
  final double rating;
  final List<Review> reviews;
  final DateTime createdAt;

  Resource({
    required this.id,
    required this.title,
    required this.description,
    required this.link,
    required this.type,
    required this.skill,
    required this.addedBy,
    this.rating = 0,
    this.reviews = const [],
    required this.createdAt,
  });

  factory Resource.fromJson(Map<String, dynamic> json) {
    return Resource(
      id: json['_id'],
      title: json['title'],
      description: json['description'],
      link: json['link'],
      type: json['type'],
      skill: Skill.fromJson(json['skill']),
      addedBy:
          json['addedBy'] is String ? json['addedBy'] : json['addedBy']['_id'],
      rating: json['rating']?.toDouble() ?? 0,
      reviews:
          json['reviews'] != null
              ? List<Review>.from(
                json['reviews'].map((x) => Review.fromJson(x)),
              )
              : [],
      createdAt:
          json['createdAt'] != null
              ? DateTime.parse(json['createdAt'])
              : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'link': link,
      'type': type,
      'skillId': skill.id,
    };
  }
}

class Review {
  final String id;
  final String userId;
  final String? userName;
  final String? userProfilePicture;
  final int rating;
  final String? comment;
  final DateTime date;

  Review({
    required this.id,
    required this.userId,
    this.userName,
    this.userProfilePicture,
    required this.rating,
    this.comment,
    required this.date,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['_id'],
      userId: json['user'] is String ? json['user'] : json['user']['_id'],
      userName: json['user'] is Map ? json['user']['name'] : null,
      userProfilePicture:
          json['user'] is Map ? json['user']['profilePicture'] : null,
      rating: json['rating'],
      comment: json['comment'],
      date:
          json['date'] != null ? DateTime.parse(json['date']) : DateTime.now(),
    );
  }
}
