import 'package:flutter/material.dart';
import 'package:glint/config/injector.dart';
import 'package:glint/core/network/api_client.dart';
import 'package:glint/core/network/socket_client.dart';
import 'package:glint/features/chat/models/message.dart';
import 'package:glint/features/chat/repositories/message_service.dart';
import 'package:glint/features/friends/repositories/friend_service.dart';

class HomeController extends ChangeNotifier {
  //Everytime anything changes state in a class which extends changeNotifier, the whole class runs again
  final _messageService = locator<MessageService>();
  final _socketService = locator<SocketService>();
  final _apiService = locator<ApiService>();
  final _friendService = locator<FriendService>();

  List<RecentChat> _recentChats = [];
  List<RecentChat> get recentChats => _recentChats;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  int _pendingCount = 0;
  int get pendingCount => _pendingCount;

  bool _hasUnreadMessages = false;
  bool get hasUnreadMessages => _hasUnreadMessages;

  bool _hasPendingRequests = false;
  bool get hasPendingRequests => _hasPendingRequests;

  // init
  void init() async {
    _fetchRecentMessages();
    _initSocket();
    _fetchPendingCount();
    await _friendService.refreshFriendsCache();
    await _fetchUnreadStatus();
    await _fetchPendingStatus();
  }

  // socket initialization
  Future<void> _initSocket() async {
    final token = await _apiService.getToken();
    final userId = _apiService.getUserIdFromToken();

    if (token != null && userId != null) {
      _socketService.connect(userId, token);
      _socketService.onMessageReceived(_handleNewMessage);
      _socketService.onUserOnline((userId) => _updateUserStatus(userId, true));
      _socketService.onUserOffline(
        (userId) => _updateUserStatus(userId, false),
      );
      _socketService.onChatRefreshRequired(() {
        silentRefreshMessages(); // Refresh the list seamlessly in the background
      });
      _socketService.onMessageEdited((data) {
        final messageId = data['messageId'];
        final newContent = data['content'];

        // Find the chat whose lastMessage matches this ID and update it
        _recentChats = _recentChats.map((chat) {
          final isMatch = chat.lastMessage.id == messageId;

          if (isMatch) {
            final updatedMessage = Message(
              id: chat.lastMessage.id,
              senderId: chat.lastMessage.senderId,
              recieverId: chat.lastMessage.recieverId,
              content: newContent,
              sentAt: chat.lastMessage.sentAt,
              isRead: chat.lastMessage.isRead,
              reactions: chat.lastMessage.reactions,
            );
            return chat.copyWith(lastMessage: updatedMessage);
          }
          return chat;
        }).toList();

        notifyListeners();
      });
    }
  }

  // checking if user has unread messages pending
  Future<void> _fetchUnreadStatus() async {
    try {
      final response = await _messageService.getUnreadCount();
      if (response.isSuccess) {
        _hasUnreadMessages = (response.data?['unreadCount'] ?? 0) > 0;
        notifyListeners();
      }
    } catch (e) {
      _hasUnreadMessages = false;
    }
  }

  //cheking if user has any pending friend requests
  Future<void> _fetchPendingStatus() async {
    try {
      final response = await _friendService.getPendingRequests();
      if (response.isSuccess) {
        final users = _friendService.parsePendingRequestsAsUsers(response);
        _hasPendingRequests = users.isNotEmpty;
        notifyListeners();
      }
    } catch (e) {
      _hasPendingRequests = false;
    }
  }

  // fetching pending requests count
  Future<void> _fetchPendingCount() async {
    try {
      final response = await _friendService.getPendingRequests();
      if (response.isSuccess) {
        final users = _friendService.parseFriends(response);
        _pendingCount = users.length;
        _hasPendingRequests = users.isNotEmpty;
      } else {
        _pendingCount = 0;
      }
    } catch (e) {
      _pendingCount = 0;
    }
    notifyListeners();
  }

  //handling new messages
  void _handleNewMessage(Map<String, dynamic> data) {
    final currentUserId = _apiService.getUserIdFromToken();
    final senderId = data['senderId'];
    if (senderId == currentUserId) {
      return;
    }
    final receiverId = data['recieverId'] ?? '';
    final friendId = (senderId == currentUserId) ? receiverId : senderId;

    final updatedLastMessage = Message(
      id: data['_id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      senderId: senderId,
      recieverId: receiverId,
      content: data['content'],
      sentAt: DateTime.parse(data['sentAt']),
      isRead: false,
    );

    final senderName =
        data['senderUserName'] ?? data['senderName'] ?? 'Unknown';
    final fullName = data['senderFullName'] ?? data['senderName'] ?? senderName;

    final existingIndex = _recentChats.indexWhere(
      (chat) => chat.friendId == friendId,
    );

    if (existingIndex != -1) {
      final existing = _recentChats[existingIndex];
      int newUnreadCount = (senderId == currentUserId)
          ? 0
          : existing.unreadCount + 1;

      _recentChats[existingIndex] = RecentChat(
        friendId: existing.friendId,
        friendUserName: existing.friendUserName,
        friendName: existing.friendName,
        friendPhoto: existing.friendPhoto,
        friendOnline: existing.friendOnline,
        lastMessage: updatedLastMessage,
        unreadCount: newUnreadCount,
      );
    } else {
      int initialUnreadCount = (senderId == currentUserId) ? 0 : 1;
      _recentChats.add(
        RecentChat(
          friendId: friendId,
          friendUserName: senderName,
          friendName: fullName,
          friendPhoto: null,
          friendOnline: false,
          lastMessage: updatedLastMessage,
          unreadCount: initialUnreadCount,
        ),
      );
    }
    _recentChats.sort(
      (a, b) => b.lastMessage.sentAt.compareTo(a.lastMessage.sentAt),
    );
    _fetchUnreadStatus();
    notifyListeners();
  }

  //updating user status online
  void _updateUserStatus(String userId, bool isOnline) {
    _recentChats = _recentChats.map((chat) {
      if (chat.friendId == userId) {
        return chat.copyWith(friendOnline: isOnline);
      }
      return chat;
    }).toList();
    notifyListeners();
  }

  // fetching recent messages
  Future<void> _fetchRecentMessages() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _messageService.getRecentMessages();
      if (response.isSuccess) {
        _recentChats = _messageService.parseRecentChats(response);
        _isLoading = false;
      } else {
        _error = response.result;
        _isLoading = false;
      }
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // handling the delete all operation for a chat with friend
  Future<void> deleteChat(String friendId) async {
    try {
      final response = await _messageService.deleteAllMessages(friendId);
      if (response.isSuccess) {
        _recentChats.removeWhere((chat) => chat.friendId == friendId);
        notifyListeners();
      }
    } catch (e) {
      // handle error
    }
  }

  // checking if user is friends with with a user
  Future<bool> isFriend(String friendId) async {
    return await _friendService.isFriend(friendId);
  }

  /* ====================================== Refreshers =====================================*/
  Future<void> refreshFriendCache() async {
    await _friendService.refreshFriendsCache();
  }

  Future<void> refreshPendingCount() async {
    await _fetchPendingCount();
  }

  Future<void> refreshMessages() async {
    await _fetchRecentMessages();
  }

  Future<void> silentRefreshMessages() async {
    try {
      final response = await _messageService.getRecentMessages();
      if (response.isSuccess) {
        _recentChats = _messageService.parseRecentChats(response);
        notifyListeners();
      }
    } catch (e) {
      // ignore
    }
  }

  Future<void> refreshUnreadStatus() async {
    await _fetchUnreadStatus();
  }

  Future<void> refreshPendingStatus() async {
    await _fetchPendingStatus();
  }

  // ===================HELPER METHODS==========================
  void clearUnreadDot() {
    _hasUnreadMessages = false;
    notifyListeners();
  }

  void clearPendingDot() {
    _hasPendingRequests = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _socketService.disconnect();
    super.dispose();
  }
}
