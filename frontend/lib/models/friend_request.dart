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
    // Handle sender which can be either a full user object or just an ID
    User parseUser(dynamic userData) {
      if (userData is Map<String, dynamic>) {
        return User.fromJson(userData);
      } else {
        // If it's just an ID, create a minimal user object
        return User(
          id: userData.toString(),
          name: '',
          email: '',
          createdAt: DateTime.now(),
        );
      }
    }

    return FriendRequest(
      id: json['_id'],
      sender: parseUser(json['sender']),
      receiver: parseUser(json['receiver']),
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
    // Handle both direct data and nested data structure
    final data = json['data'] ?? json;
    final requestsList = data['requests'] as List;

    return FriendRequestResponse(
      requests: requestsList
          .map((x) => FriendRequest.fromJson(x as Map<String, dynamic>))
          .toList(),
      currentUserId: data['currentUserId'] ?? '',
    );
  }
}
