class Discussion {
  final String id;
  final String groupId;
  final String title;
  final String content;
  final String authorId;
  final String? authorName;
  final String? authorProfilePicture;
  final List<Reply> replies;
  final DateTime createdAt;

  Discussion({
    required this.id,
    required this.groupId,
    required this.title,
    required this.content,
    required this.authorId,
    this.authorName,
    this.authorProfilePicture,
    this.replies = const [],
    required this.createdAt,
  });

  factory Discussion.fromJson(Map<String, dynamic> json) {
    return Discussion(
      id: json['_id'],
      groupId: json['group'],
      title: json['title'],
      content: json['content'],
      authorId:
          json['author'] is String ? json['author'] : json['author']['_id'],
      authorName: json['author'] is Map ? json['author']['name'] : null,
      authorProfilePicture:
          json['author'] is Map ? json['author']['profilePicture'] : null,
      replies:
          json['replies'] != null
              ? List<Reply>.from(json['replies'].map((x) => Reply.fromJson(x)))
              : [],
      createdAt:
          json['createdAt'] != null
              ? DateTime.parse(json['createdAt'])
              : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {'groupId': groupId, 'title': title, 'content': content};
  }
}

class Reply {
  final String id;
  final String content;
  final String authorId;
  final String? authorName;
  final String? authorProfilePicture;
  final DateTime createdAt;

  Reply({
    required this.id,
    required this.content,
    required this.authorId,
    this.authorName,
    this.authorProfilePicture,
    required this.createdAt,
  });

  factory Reply.fromJson(Map<String, dynamic> json) {
    return Reply(
      id: json['_id'],
      content: json['content'],
      authorId:
          json['author'] is String ? json['author'] : json['author']['_id'],
      authorName: json['author'] is Map ? json['author']['name'] : null,
      authorProfilePicture:
          json['author'] is Map ? json['author']['profilePicture'] : null,
      createdAt:
          json['createdAt'] != null
              ? DateTime.parse(json['createdAt'])
              : DateTime.now(),
    );
  }
}
