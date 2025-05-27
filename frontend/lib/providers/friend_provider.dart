import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../models/friend_request.dart';
import '../services/friend_service.dart';
import '../utils/api_response.dart';

class FriendProvider with ChangeNotifier {
  final FriendService _friendService;
  List<User> _friends = [];
  List<FriendRequest> _incomingRequests = [];
  List<FriendRequest> _outgoingRequests = [];
  bool _isLoading = false;
  String? _error;

  FriendProvider(this._friendService);

  List<User> get friends => _friends;
  List<FriendRequest> get incomingRequests => _incomingRequests;
  List<FriendRequest> get outgoingRequests => _outgoingRequests;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Load friends
  Future<void> loadFriends() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _friendService.getFriends();
      if (response.success && response.data != null) {
        _friends = response.data!;
        _error = null;
      } else {
        _error = response.message ?? 'Failed to load friends';
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load friend requests
  Future<void> loadFriendRequests() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _friendService.getFriendRequests();
      if (response.success && response.data != null) {
        final currentUserId = response.data!.currentUserId;
        _incomingRequests = response.data!.requests
            .where((request) =>
                request.receiver.id == currentUserId &&
                request.status == 'pending')
            .toList();
        _outgoingRequests = response.data!.requests
            .where((request) =>
                request.sender.id == currentUserId &&
                request.status == 'pending')
            .toList();
        _error = null;
      } else {
        _error = response.message ?? 'Failed to load friend requests';
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Send friend request
  Future<bool> sendFriendRequest(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _friendService.sendFriendRequest(userId);
      if (response.success) {
        _error = null;
        await loadFriendRequests();
        return true;
      } else {
        _error = response.message ?? 'Failed to send friend request';
        return false;
      }
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Accept friend request
  Future<bool> acceptFriendRequest(String requestId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _friendService.acceptFriendRequest(requestId);
      if (response.success) {
        await loadFriends();
        await loadFriendRequests();
        return true;
      } else {
        _error = response.message ?? 'Failed to accept friend request';
        return false;
      }
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Reject friend request
  Future<bool> rejectFriendRequest(String requestId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _friendService.rejectFriendRequest(requestId);
      if (response.success) {
        await loadFriendRequests();
        return true;
      } else {
        _error = response.message ?? 'Failed to reject friend request';
        return false;
      }
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Remove friend
  Future<bool> removeFriend(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _friendService.removeFriend(userId);
      if (response.success) {
        await loadFriends();
        return true;
      } else {
        _error = response.message ?? 'Failed to remove friend';
        return false;
      }
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Search users
  Future<List<User>> searchUsers(String query) async {
    try {
      final response = await _friendService.searchUsers(query);

      if (!response.success) {
        throw Exception(response.message ?? 'Failed to search users');
      }

      if (response.data == null) {
        return [];
      }

      return response.data!;
    } catch (e) {
      print('Error searching users: $e');
      rethrow;
    }
  }
}
