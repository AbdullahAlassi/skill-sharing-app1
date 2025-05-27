import 'package:flutter/foundation.dart';
import '../services/social_service.dart';
import '../models/user_model.dart';
import '../utils/api_response.dart';

class SocialProvider with ChangeNotifier {
  final SocialService _socialService;
  List<User> _friends = [];
  bool _isLoading = false;
  String? _error;

  SocialProvider(this._socialService);

  List<User> get friends => _friends;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadFriends() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _socialService.getFriends();
      if (response.success && response.data != null) {
        _friends = response.data!;
        _error = null;
      } else {
        _error = response.error ?? 'Failed to load friends';
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addFriend(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _socialService.addFriend(userId);
      if (response.success) {
        // Reload friends list after adding a friend
        await loadFriends();
        _error = null;
      } else {
        _error = response.error ?? 'Failed to add friend';
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> removeFriend(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _socialService.removeFriend(userId);
      if (response.success) {
        // Reload friends list after removing a friend
        await loadFriends();
        _error = null;
      } else {
        _error = response.error ?? 'Failed to remove friend';
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
