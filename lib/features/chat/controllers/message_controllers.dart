import 'package:flutter/material.dart';
import 'package:glint/config/injector.dart';
import 'package:glint/features/friends/repositories/friend_service.dart';
import '../../chat/repositories/message_service.dart';
import '../../profile/repositories/profile_service.dart';
import 'package:glint/core/network/socket_client.dart';
import '../models/message.dart';
import '../../auth/models/user.dart';
import 'package:audioplayers/audioplayers.dart';

class MessageController extends ChangeNotifier {
  // Dependencies
  final _messageService = locator<MessageService>();
  final _profileService = locator<ProfileService>();
  final _socketService = locator<SocketService>();
  final _friendService = locator<FriendService>();

  AudioPlayer? _audioPlayer;
  AudioPlayer get audioPlayer {
    _audioPlayer ??= AudioPlayer();
    return _audioPlayer!;
  }

  // State
  List<Message> _messages = [];
  String? _editingMessageId;
  bool _isLoading = true;
  bool _isSending = false;
  bool _isTyping = false;
  String? _error;
  User? _currentUser;
  String _friendId = '';
  bool _isFriend = false;
  bool _isFriendOnline = false;
  bool _isPageVisible = true;

  bool _disposed = false;
  final List<Function> _registeredSocketCallbacks = [];

  // Getters
  List<Message> get messages => _messages;
  String? get editingMessageId => _editingMessageId;
  bool get isLoading => _isLoading;
  bool get isSending => _isSending;
  bool get isTyping => _isTyping;
  String? get error => _error;
  User? get currentUser => _currentUser;
  bool get isFriend => _isFriend;
  bool get isFriendOnline => _isFriendOnline;

  // Initialize
  void init(String friendId, BuildContext context) {
    _friendId = friendId;
    _isPageVisible = true;
    _setupSocketListeners();
    _loadData();
    _checkFriendshipStatus();
    _fetchFriendStatus();
  }

  // To track if user has chat message open, closed, or minimized to set sockets accordingly
  void setPageVisibility(bool isVisible) {
    _isPageVisible = isVisible;
    if (!_disposed) notifyListeners();

    if (isVisible) {
      _rejoinChatRoom();
      _markAsRead();
    } else {
      _leaveChatRoom();
    }
  }

  void _joinChatRoom() {
    _socketService.joinChatRoom(_currentUser?.id ?? '', _friendId);
  }

  void _rejoinChatRoom() {
    if (_currentUser != null && _friendId.isNotEmpty) {
      _socketService.joinChatRoom(_currentUser!.id, _friendId);
    }
  }

  void _leaveChatRoom() {
    if (_currentUser != null && _friendId.isNotEmpty) {
      _socketService.leaveChatRoom(_currentUser!.id, _friendId);
    }
  }

  //socket listeners setup
  void _setupSocketListeners() {
    // Notice we assign the function to a variable now:
    void onMessageCallback(data) {
      if (data['senderId'] == _friendId || data['recieverId'] == _friendId) {
        final messageId = data['_id'] ?? '';
        final senderId = data['senderId'] ?? '';
        final receiverId = data['recieverId'] ?? _friendId;
        final content = data['content'] ?? '';
        final sentAt = data['sentAt'] != null
            ? DateTime.parse(data['sentAt'])
            : DateTime.now();
        final isDelivered = data['isDelivered'] ?? false;

        final isRead = (senderId == _friendId) && _isPageVisible;
        if (senderId == _friendId) {
          _playReceiveAudio();
        }
        final existingIndex = _messages.indexWhere((m) => m.id == messageId);

        if (existingIndex != -1) {
          _messages[existingIndex] = _messages[existingIndex].copyWith(
            isDelivered: isDelivered,
            isRead: isRead,
          );
        } else {
          int? tempIndex = _messages.indexWhere(
            (m) =>
                m.id.startsWith('1') &&
                m.senderId == senderId &&
                m.content == content &&
                m.recieverId == receiverId,
          );

          if (tempIndex == -1) {
            tempIndex = _messages.indexWhere(
              (m) => m.id.startsWith('1') && m.senderId == senderId,
            );
          }

          if (tempIndex != -1 && tempIndex >= 0) {
            _messages[tempIndex] = Message(
              id: messageId,
              senderId: senderId,
              recieverId: receiverId,
              content: content,
              sentAt: sentAt,
              isRead: isRead,
              isDelivered: isDelivered,
            );
          } else {
            final newMessage = Message(
              id: messageId,
              senderId: senderId,
              recieverId: receiverId,
              content: content,
              sentAt: sentAt,
              isRead: isRead,
              isDelivered: isDelivered,
            );
            _messages.insert(0, newMessage);
          }
        }
        if (senderId == _friendId && _isPageVisible) {
          _messageService.markAsRead(_friendId);
        }
        if (!_disposed) notifyListeners();
      }
    }

    // Register it
    _socketService.onMessageReceived(onMessageCallback);
    // Track it so we can kill it later
    _registeredSocketCallbacks.add(onMessageCallback);

    void onTypingCallback(data) {
      if (data['userId'] == _friendId) {
        var raw = data['isTyping'] ?? false;
        if (raw == false) {
          _isTyping = false;
        } else {
          _isTyping = true;
        }
        if (!_disposed) notifyListeners();
      }
    }

    _socketService.onTyping(onTypingCallback);
    _registeredSocketCallbacks.add(onTypingCallback);

    void onReadCallback(data) {
      if (data['readerId'] == _friendId) {
        for (var message in _messages) {
          if (message.senderId == _currentUser?.id && !message.isRead) {
            message.isRead = true;
          }
        }
        if (!_disposed) notifyListeners();
      }
    }

    _socketService.onMessageReadReceipt(onReadCallback);
    _registeredSocketCallbacks.add(onReadCallback);

    void onEditedCallback(data) {
      final idx = _messages.indexWhere((m) => m.id == data['messageId']);
      if (idx != -1) {
        _messages[idx] = Message(
          id: _messages[idx].id,
          senderId: _messages[idx].senderId,
          recieverId: _messages[idx].recieverId,
          content: data['content'],
          sentAt: _messages[idx].sentAt,
          isRead: _messages[idx].isRead,
        );
        if (!_disposed) notifyListeners();
      }
    }

    _socketService.onMessageEdited(onEditedCallback);
    _registeredSocketCallbacks.add(onEditedCallback);

    void onDeletedCallback(data) {
      _messages.removeWhere((m) => m.id == data['messageId']);
      if (!_disposed) notifyListeners();
    }

    _socketService.onMessageDeleted(onDeletedCallback);
    _registeredSocketCallbacks.add(onDeletedCallback);

    void onReactedCallback(data) {
      final idx = _messages.indexWhere((m) => m.id == data['messageId']);
      if (idx != -1) {
        _messages[idx].reactions = data['reactions'] != null
            ? Map<String, dynamic>.from(data['reactions'])
            : null;
        if (!_disposed) notifyListeners();
      }
    }

    _socketService.onMessageReacted(onReactedCallback);
    _registeredSocketCallbacks.add(onReactedCallback);

    void onOnlineCallback(userId) {
      if (userId == _friendId) {
        _isFriendOnline = true;
        if (!_disposed) notifyListeners();
      }
    }

    _socketService.onUserOnline(onOnlineCallback);
    _registeredSocketCallbacks.add(onOnlineCallback);

    void onOfflineCallback(userId) {
      if (userId == _friendId) {
        _isFriendOnline = false;
        if (!_disposed) notifyListeners();
      }
    }

    _socketService.onUserOffline(onOfflineCallback);
    _registeredSocketCallbacks.add(onOfflineCallback);

    void onDeliveredCallback(data) {
      final messageIds = data['messageIds'] as List;
      for (var msgId in messageIds) {
        final idx = _messages.indexWhere((m) => m.id == msgId);
        if (idx != -1) {
          _messages[idx] = _messages[idx].copyWith(isDelivered: true);
        }
      }
      if (!_disposed) notifyListeners();
    }

    _socketService.onMessageDelivered(onDeliveredCallback);
    _registeredSocketCallbacks.add(onDeliveredCallback);
  }

 // =====================Public methods for UI to call=======================/
  Future<void> _fetchFriendStatus() async {
    try {
      final response = await _profileService.getUserById(_friendId);
      if (response.isSuccess) {
        final user = _profileService.parseUser(response);
        if (user != null) {
          _isFriendOnline = user.isOnline;
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('Error fetching friend status: $e');
    }
  }

  Future<void> _checkFriendshipStatus() async {
    _isFriend = await _friendService.isFriend(_friendId);
    notifyListeners();
  }

  Future<void> refreshMessages() async {
    await _fetchMessages();
  }

  Future<void> _loadData() async {
    await _fetchCurrentUser();
    await _fetchMessages();
    await _markAsRead();
    _joinChatRoom();
  }

  Future<void> _fetchCurrentUser() async {
    try {
      final response = await _profileService.getProfile();
      if (response.isSuccess) {
        _currentUser = _profileService.parseUser(response);
        notifyListeners();
      }
    } catch (e) {
      //
    }
  }

  Future<void> _fetchMessages() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _messageService.getChatHistory(_friendId);
      if (response.isSuccess) {
        _messages = _messageService.parseMessages(response);
        _isLoading = false;
        notifyListeners();
      } else {
        _error = response.result;
        _isLoading = false;
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _markAsRead() async {
    try {
      await _messageService.markAsRead(_friendId);
    } catch (e) {
      //
    }
  }

  Future<void> refreshFriendshipStatus() async {
    await _friendService.refreshFriendsCache();
    _isFriend = await _friendService.isFriend(_friendId);
    notifyListeners();
  }

  Future<void> sendMessage(String content, BuildContext context) async {
    if (content.isEmpty || _isSending) return;
    final tempId = DateTime.now().millisecondsSinceEpoch.toString();

    final tempMessage = Message(
      id: tempId,
      senderId: _currentUser?.id ?? '',
      recieverId: _friendId,
      content: content,
      sentAt: DateTime.now(),
      isRead: true,
      isDelivered: false,
    );
    _messages.insert(0, tempMessage);
    notifyListeners();

    _isSending = true;
    notifyListeners();

    try {
      final response = await _messageService.sendMessage(
        recieverId: _friendId,
        content: content,
      );

      if (response.isSuccess) {
        final serverMessageId = response.data?['messageId'];

        if (serverMessageId != null) {
          final idx = _messages.indexWhere((m) => m.id == tempId);
          if (idx != -1) {
            _messages[idx] = Message(
              id: serverMessageId,
              senderId: _messages[idx].senderId,
              recieverId: _messages[idx].recieverId,
              content: _messages[idx].content,
              sentAt: _messages[idx].sentAt,
              isRead: true,
              isDelivered: _messages[idx].isDelivered,
              reactions: _messages[idx].reactions,
            );
            notifyListeners();
          }
        }
        _playSendAudio();
      } else {
        _messages.removeWhere((m) => m.id == tempId);
        notifyListeners();
      }
    } catch (e) {
      _messages.removeWhere((m) => m.id == tempId);
      notifyListeners();
    } finally {
      _isSending = false;
      notifyListeners();
    }
  }

  void sendTyping(bool text) {
    _socketService.sendTyping(_currentUser?.id ?? '', _friendId, text);
  }

  void startEditing(Message message) {
    _editingMessageId = message.id;
    notifyListeners();
  }

  void cancelEditing() {
    _editingMessageId = null;
    notifyListeners();
  }

  Future<void> submitEdit(
    Message message,
    String newContent,
    BuildContext context,
  ) async {
    if (newContent.isEmpty) return;
    try {
      final res = await _messageService.editMessage(
        messageId: message.id,
        newContent: newContent,
      );
      if (res.isSuccess) {
        _editingMessageId = null;
        final idx = _messages.indexWhere((m) => m.id == message.id);
        if (idx != -1) {
          _messages[idx] = Message(
            id: message.id,
            senderId: message.senderId,
            recieverId: message.recieverId,
            content: newContent,
            sentAt: message.sentAt,
            isRead: message.isRead,
            reactions: message.reactions,
          );
          notifyListeners();
        }
      } else {}
    } catch (e) {
      //
    }
  }

  Future<void> deleteMessage(Message message) async {
    try {
      final res = await _messageService.deleteMessage(message.id);
      if (res.isSuccess) {
        _messages.removeWhere((m) => m.id == message.id);
        notifyListeners();
      }
    } catch (e) {
      //
    }
  }

  Future<void> reactToMessage(Message message, String emoji) async {
    try {
      final userId = _currentUser?.id ?? '';
      if (userId.isEmpty) return;

      // Clone the reactions map
      final Map<String, dynamic> reactions = Map.from(message.reactions ?? {});

      // 1. Get the list for the target emoji (safe copy)
      final targetList = reactions[emoji] as List? ?? [];
      final alreadyReacted = targetList.contains(userId);

      if (alreadyReacted) {
        // Toggle off: remove user from this emoji
        targetList.remove(userId);
        if (targetList.isEmpty) {
          reactions.remove(emoji);
        } else {
          reactions[emoji] = targetList;
        }
      } else {
        // Remove user from ALL other reactions (safe iteration)
        final keysToRemove = <String>[];
        reactions.forEach((key, list) {
          if (key != emoji && list is List && list.contains(userId)) {
            list.remove(userId);
            if (list.isEmpty) {
              keysToRemove.add(key);
            }
          }
        });
        // Remove empty keys after iteration
        for (var key in keysToRemove) {
          reactions.remove(key);
        }

        // Add user to the new emoji
        if (!reactions.containsKey(emoji)) {
          reactions[emoji] = [];
        }
        (reactions[emoji] as List).add(userId);
      }

      // Update local message
      final idx = _messages.indexWhere((m) => m.id == message.id);
      if (idx != -1) {
        _messages[idx] = message.copyWith(reactions: reactions);
        notifyListeners();
      }

      // Send to server
      await _messageService.reactToMessage(messageId: message.id, emoji: emoji);
    } catch (e) {
      //
    }
  }

  Future<void> silentRefresh() async {
    try {
      final response = await _messageService.getChatHistory(_friendId);
      if (response.isSuccess) {
        _messages = _messageService.parseMessages(response);
        notifyListeners();
      }
    } catch (e) {
      //
    }
  }

  void scrollToBottom(ScrollController scrollController) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!scrollController.hasClients) return;
      scrollController.jumpTo(scrollController.position.maxScrollExtent);
    });
  }

  Future<void> _playSendAudio() async {
    try {
      await audioPlayer.play(AssetSource('send-sound/send.mp3'));
    } catch (e) {
      debugPrint('ERROR : $e');
    }
  }

  Future<void> _playReceiveAudio() async {
    try {
      await audioPlayer.stop();
      await audioPlayer.play(AssetSource('send-sound/received.mp3'));
    } catch (e) {
      debugPrint('ERROR playing receive sound: $e');
    }
  }

  @override
  void dispose() {
    _audioPlayer?.stop();
    _audioPlayer?.dispose();
    _audioPlayer = null;
    for (var callback in _registeredSocketCallbacks) {
      _socketService.onMessageReceivedCallbacks.remove(callback);
      _socketService.onTypingCallbacks.remove(callback);
      _socketService.onMessageReadReceiptCallbacks.remove(callback);
      _socketService.onMessageEditedCallbacks.remove(callback);
      _socketService.onMessageDeletedCallbacks.remove(callback);
      _socketService.onMessageReactedCallbacks.remove(callback);
      _socketService.onUserOnlineCallbacks.remove(callback);
      _socketService.onUserOfflineCallbacks.remove(callback);
      _socketService.onMessageDeliveredCallbacks.remove(callback);
    }
    _registeredSocketCallbacks.clear();
    // _socketService.leaveChatRoom(_currentUser?.id ?? '', _friendId);
    _leaveChatRoom();
    _disposed = true;
    super.dispose();
  }
}
