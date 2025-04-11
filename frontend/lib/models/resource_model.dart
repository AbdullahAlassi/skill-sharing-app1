import 'package:frontend/models/skill_model.dart';

class Resource {
  final String id;
  final String title;
  final String description;
  final String link;
  final String type;
  final Skill skill;
  final String addedBy;
  final List<Review>? reviews;
  final DateTime createdAt;

  Resource({
    required this.id,
    required this.title,
    required this.description,
    required this.link,
    required this.type,
    required this.skill,
    required this.addedBy,
    this.reviews,
    required this.createdAt,
  });

  factory Resource.fromJson(Map<String, dynamic> json) {
    return Resource(
      id: json['_id'] ?? json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      link: json['link'] ?? '',
      type: json['type'] ?? '',
      skill:
          json['skill'] is Map
              ? Skill.fromJson(json['skill'])
              : Skill(
                id: json['skill'] ?? '',
                name: '',
                category: '',
                description: '',
                createdAt: DateTime.now(),
              ),
      addedBy: json['addedBy'] ?? '',
      reviews:
          json['reviews'] != null
              ? List<Review>.from(
                json['reviews'].map((x) => Review.fromJson(x)),
              )
              : null,
      createdAt:
          json['createdAt'] != null
              ? DateTime.parse(json['createdAt'])
              : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'link': link,
      'type': type,
      'skill': skill.id,
      'addedBy': addedBy,
      'reviews': reviews?.map((x) => x.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

class Review {
  final String id;
  final int rating;
  final String comment;
  final String userId;
  final String userName;
  final DateTime createdAt;

  Review({
    required this.id,
    required this.rating,
    required this.comment,
    required this.userId,
    required this.userName,
    required this.createdAt,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['_id'] ?? json['id'] ?? '',
      rating: json['rating'] ?? 0,
      comment: json['comment'] ?? '',
      userId: json['userId'] ?? '',
      userName: json['userName'] ?? '',
      createdAt:
          json['createdAt'] != null
              ? DateTime.parse(json['createdAt'])
              : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'rating': rating,
      'comment': comment,
      'userId': userId,
      'userName': userName,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
