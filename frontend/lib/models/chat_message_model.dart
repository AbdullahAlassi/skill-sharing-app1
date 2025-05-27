class ChatMessage {
  final String id;
  final String senderId;
  final String content;
  final DateTime createdAt;
  final bool isRead;
  final String? senderName;
  final String? senderProfilePicture;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.content,
    required this.createdAt,
    this.isRead = false,
    this.senderName,
    this.senderProfilePicture,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['_id'] ?? '',
      senderId: json['sender'] is Map ? json['sender']['_id'] : json['sender'],
      content: json['content'] ?? '',
      createdAt: DateTime.parse(json['createdAt']),
      isRead: json['readBy'] != null && (json['readBy'] as List).isNotEmpty,
      senderName: json['sender'] is Map ? json['sender']['name'] : null,
      senderProfilePicture:
          json['sender'] is Map ? json['sender']['profilePicture'] : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'sender': senderId,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'isRead': isRead,
    };
  }

  ChatMessage copyWith({
    String? id,
    String? senderId,
    String? content,
    DateTime? createdAt,
    bool? isRead,
    String? senderName,
    String? senderProfilePicture,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      senderName: senderName ?? this.senderName,
      senderProfilePicture: senderProfilePicture ?? this.senderProfilePicture,
    );
  }
}
