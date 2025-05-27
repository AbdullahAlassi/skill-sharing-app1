import 'user_model.dart';

class FriendRequest {
  final String id;
  final User sender;
  final User receiver;
  final String status;
  final DateTime createdAt;

  FriendRequest({
    required this.id,
    required this.sender,
    required this.receiver,
    required this.status,
    required this.createdAt,
  });

  factory FriendRequest.fromJson(Map<String, dynamic> json) {
    return FriendRequest(
      id: json['_id'],
      sender: User.fromJson(json['sender']),
      receiver: User.fromJson(json['receiver']),
      status: json['status'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'sender': sender.toJson(),
      'receiver': receiver.toJson(),
      'status': status,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

class FriendRequestResponse {
  final List<FriendRequest> requests;
  final String currentUserId;

  FriendRequestResponse({
    required this.requests,
    required this.currentUserId,
  });

  factory FriendRequestResponse.fromJson(Map<String, dynamic> json) {
    return FriendRequestResponse(
      requests: (json['requests'] as List)
          .map((x) => FriendRequest.fromJson(x))
          .toList(),
      currentUserId: json['currentUserId'],
    );
  }
}
