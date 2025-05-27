import 'package:skill_sharing_app/models/skill_model.dart';

class Completion {
  final String user;
  final DateTime completedAt;

  Completion({
    required this.user,
    required this.completedAt,
  });

  factory Completion.fromJson(Map<String, dynamic> json) {
    return Completion(
      user:
          json['user'] is Map ? json['user']['_id'] ?? '' : json['user'] ?? '',
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user': user,
      'completedAt': completedAt.toIso8601String(),
    };
  }
}

class Resource {
  final String id;
  final String title;
  final String description;
  final String link;
  final String type;
  final String? fileUrl;
  final String? fileType;
  final String? previewUrl;
  final bool isFlagged;
  final int views;
  final Skill skill;
  final Map<String, dynamic> addedBy;
  final List<Review>? reviews;
  final DateTime createdAt;
  final List<String> tags;
  final List<Completion> completions;

  static const List<String> types = [
    'Article',
    'Video',
    'Course',
    'Book',
    'Image',
    'PDF',
    'Other',
  ];

  Resource({
    required this.id,
    required this.title,
    required this.description,
    required this.link,
    required this.type,
    this.fileUrl,
    this.fileType,
    this.previewUrl,
    this.isFlagged = false,
    this.views = 0,
    required this.skill,
    required this.addedBy,
    this.reviews,
    required this.createdAt,
    this.tags = const [],
    this.completions = const [],
  });

  factory Resource.fromJson(Map<String, dynamic> json) {
    print('[DEBUG] Resource JSON: $json');

    // Handle skill with proper type checking and null safety
    Skill parsedSkill;
    if (json['skill'] is Map<String, dynamic>) {
      final skillData = json['skill'];
      parsedSkill = Skill(
        id: skillData['_id']?.toString() ?? '',
        name: skillData['name']?.toString() ?? '',
        description: skillData['description']?.toString() ?? '',
        category: skillData['category'] is Map
            ? skillData['category']['name']?.toString() ?? ''
            : skillData['category']?.toString() ?? '',
        relatedSkills: [],
        difficultyLevel: skillData['difficultyLevel']?.toString() ?? 'Beginner',
        resources: [],
        proficiency: skillData['proficiency']?.toString() ?? 'Beginner',
        createdAt:
            DateTime.tryParse(skillData['createdAt']?.toString() ?? '') ??
                DateTime.now(),
        createdBy: null,
        roadmap: [],
      );
    } else if (json['skill'] is String) {
      parsedSkill = Skill(
        id: json['skill'] as String,
        name: '',
        description: '',
        category: '',
        relatedSkills: [],
        difficultyLevel: 'Beginner',
        resources: [],
        proficiency: 'Beginner',
        createdAt: DateTime.now(),
        createdBy: null,
        roadmap: [],
      );
    } else {
      print(
          '[DEBUG] Warning: skill is neither Map nor String: ${json['skill']}');
      parsedSkill = Skill(
        id: '',
        name: '',
        description: '',
        category: '',
        relatedSkills: [],
        difficultyLevel: 'Beginner',
        resources: [],
        proficiency: 'Beginner',
        createdAt: DateTime.now(),
        createdBy: null,
        roadmap: [],
      );
    }

    // Handle addedBy with proper type checking and null safety
    Map<String, dynamic> parsedAddedBy;
    if (json['addedBy'] is Map<String, dynamic>) {
      parsedAddedBy = {
        '_id': json['addedBy']['_id']?.toString() ?? '',
        'name': json['addedBy']['name']?.toString() ?? '',
      };
    } else if (json['addedBy'] is String) {
      parsedAddedBy = {
        '_id': json['addedBy'] as String,
        'name': '',
      };
    } else {
      print(
          '[DEBUG] Warning: addedBy is neither Map nor String: ${json['addedBy']}');
      parsedAddedBy = {
        '_id': '',
        'name': '',
      };
    }

    // Handle reviews with proper type checking
    List<Review>? parsedReviews;
    if (json['reviews'] != null) {
      if (json['reviews'] is List) {
        parsedReviews = List<Review>.from(
          json['reviews']
              .map((x) => Review.fromJson(x as Map<String, dynamic>)),
        );
      } else {
        print('[DEBUG] Warning: reviews is not a List: ${json['reviews']}');
        parsedReviews = [];
      }
    }

    // Handle completions with proper type checking and safe parsing
    List<Completion> parsedCompletions = (json['completions'] as List<dynamic>?)
            ?.map((item) => Completion.fromJson(item as Map<String, dynamic>))
            .toList() ??
        [];

    return Resource(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      link: json['link']?.toString() ?? '',
      type: json['type']?.toString() ?? 'Article',
      fileUrl: json['fileUrl']?.toString(),
      fileType: json['fileType']?.toString(),
      previewUrl: json['previewUrl']?.toString(),
      isFlagged: json['isFlagged'] as bool? ?? false,
      views: json['views'] as int? ?? 0,
      skill: parsedSkill,
      addedBy: parsedAddedBy,
      reviews: parsedReviews,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      tags: List<String>.from(json['tags'] ?? []),
      completions: parsedCompletions,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'link': link,
      'type': type,
      'fileUrl': fileUrl,
      'fileType': fileType,
      'previewUrl': previewUrl,
      'isFlagged': isFlagged,
      'views': views,
      'skill': skill.id,
      'addedBy': addedBy,
      'reviews': reviews?.map((x) => x.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'tags': tags,
      'completions': completions.map((x) => x.toJson()).toList(),
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
      createdAt: json['createdAt'] != null
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
