import 'package:flutter/foundation.dart';
import '../models/chat_message_model.dart';
import '../services/chat_service.dart';
import '../utils/api_response.dart';

class ChatProvider with ChangeNotifier {
  final ChatService _chatService;
  Map<String, List<ChatMessage>> _chatHistory = {};
  bool _isLoading = false;
  String? _error;
  String? _currentUserId;

  ChatProvider(this._chatService);

  // Getters
  Map<String, List<ChatMessage>> get chatHistory => _chatHistory;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get currentUserId => _currentUserId;

  // Set current user ID
  void setCurrentUserId(String userId) {
    _currentUserId = userId;
    notifyListeners();
  }

  // Load chat history for a specific friend
  Future<void> loadChatHistory(String friendId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _chatService.getChatHistory(friendId);
      if (response.success && response.data != null) {
        _chatHistory[friendId] = response.data!;
        _error = null;
      } else {
        _error = response.message;
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Send a message to a friend
  Future<bool> sendMessage(String friendId, String content) async {
    try {
      final response = await _chatService.sendMessage(friendId, content);
      if (response.success && response.data != null) {
        _chatHistory[friendId] = [
          ...(_chatHistory[friendId] ?? []),
          response.data!
        ];
        notifyListeners();
        return true;
      } else {
        _error = response.message;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Mark messages as read
  Future<bool> markMessagesAsRead(String friendId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _chatService.markMessagesAsRead(friendId);
      if (response.success) {
        // Update local messages to mark them as read
        if (_chatHistory.containsKey(friendId)) {
          _chatHistory[friendId] = _chatHistory[friendId]!
              .map((message) => message.copyWith(isRead: true))
              .toList();
        }
        _error = null;
        notifyListeners();
        return true;
      } else {
        _error = response.message;
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

  // Delete a message
  Future<bool> deleteMessage(String messageId, String friendId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _chatService.deleteMessage(messageId);
      if (response.success) {
        // Remove message from local history
        if (_chatHistory.containsKey(friendId)) {
          _chatHistory[friendId] = _chatHistory[friendId]!
              .where((message) => message.id != messageId)
              .toList();
        }
        _error = null;
        notifyListeners();
        return true;
      } else {
        _error = response.message;
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

  // Clear chat history for a specific friend
  void clearChatHistory(String friendId) {
    _chatHistory.remove(friendId);
    notifyListeners();
  }

  // Clear all chat history
  void clearAllChatHistory() {
    _chatHistory.clear();
    notifyListeners();
  }
}
