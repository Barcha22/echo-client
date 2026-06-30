import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as i_o;

class SocketService {
  /* ._internal is used to make singleton pattern or one instance only */
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  i_o.Socket? _socket;
  String? _userId;
  bool _isConnected = false;
  Timer? _typingTimer;

  // --- CALLBACK LISTS ---
  List<void Function(String userId)> onUserOnlineCallbacks = [];
  List<void Function(String userId)> onUserOfflineCallbacks = [];
  List<void Function(Map<String, dynamic>)> onMessageReceivedCallbacks = []; // Handles 'message:new'
  List<void Function(Map<String, dynamic>)> onTypingCallbacks = [];
  List<void Function(Map<String, dynamic>)> onFriendRequestCallbacks = [];
  List<void Function(Map<String, dynamic>)> onFriendAcceptedCallbacks = []; 
  List<void Function(Map<String, dynamic>)> onMessageEditedCallbacks = [];
  List<void Function(Map<String, dynamic>)> onMessageDeletedCallbacks = [];
  List<void Function(Map<String, dynamic>)> onMessageReactedCallbacks = [];
  List<void Function(Map<String, dynamic>)> onMessageDeliveredCallbacks = [];
  List<void Function(Map<String, dynamic>)> onMessageReadReceiptCallbacks = []; 
  List<void Function()> onChatRefreshRequiredCallbacks = [];
  
  void connect(String userId, String token) {

    if (_isConnected) return; //prevents duplicate connections for the same user

    _userId = userId;

    _socket = i_o.io('http://10.0.2.2:5000', {
    // _socket = i_o.io('http://192.168.18.54:5000', {
      'transports': ['websocket'],
      'autoConnect': true,
      'forceNew': true,
      'query': {
        'userId': userId,
        'token': token,
      },
    });

    _socket?.onConnect((_) {
      debugPrint('🔌 Socket Connected');
      _isConnected = true;
      _socket?.emit('user:join', {'userId': _userId});
    });

    _socket?.onConnectError((error) {
      debugPrint('❌ Socket Connect Error: $error');
    });

    _socket?.onError((error) {
      debugPrint('❌ Socket Error: $error');
    });

    _socket?.onDisconnect((_) {
      debugPrint('🔌 Socket Disconnected');
      _isConnected = false;
    });

    // Initialize all listeners
    listenToUserStatus();
    listenToMessages();
    listenToTyping();
    listenToFriendRequests();
    listenToMessageDelivered();
    listenToReadReceipts();
    listenToChatRefresh();

    _socket?.connect();
  }

  void disconnect() {
    if (_socket != null) {
      _socket?.clearListeners();
      _socket?.disconnect();
      _socket?.dispose();
      _socket = null;
      _isConnected = false;

      // Clearing all callbacks to prevent memory leaks
      onUserOnlineCallbacks.clear();
      onUserOfflineCallbacks.clear();
      onMessageReceivedCallbacks.clear();
      onTypingCallbacks.clear();
      onFriendRequestCallbacks.clear();
      onFriendAcceptedCallbacks.clear();
      onMessageEditedCallbacks.clear();
      onMessageDeletedCallbacks.clear();
      onMessageReactedCallbacks.clear();
      onMessageDeliveredCallbacks.clear();
      onMessageReadReceiptCallbacks.clear();
      onChatRefreshRequiredCallbacks.clear();
    }
  }

  // ============================= SOCKET EMITTERS (client->server)  =================================
  void joinChatRoom(String senderId, String receiverId) {
    if (!_isConnected) return;
    _socket?.emit('message:join', { 
      'senderId': senderId,
      'recieverId': receiverId,
    });
  }

  void leaveChatRoom(String senderId, String receiverId) {
    if (!_isConnected) return;
    final ids = [senderId, receiverId]..sort(); 
    final roomId = 'chat_${ids[0]}_${ids[1]}'; // Fixed the string here
    _socket?.emit('message:leave', {'roomId': roomId}); 
  }

  void sendTyping(String senderId, String receiverId, bool isTyping) {
    if (!_isConnected) return;

    _socket?.emit('message:typing', {
      'senderId': senderId,
      'recieverId': receiverId,
      'isTyping': isTyping, 
    });

    if (isTyping) {
      _typingTimer?.cancel();
      _typingTimer = Timer(
        const Duration(seconds: 1),
        () {
          sendTyping(senderId, receiverId, false);
        },
      );
    }
  }

  // =============================== SOCKET LISTENERS (server-client) ================================

  void listenToUserStatus() {
    _socket?.on('user:online', (data) {
      final userId = data['userId'];
      if (userId != null) {
        for (var callback in onUserOnlineCallbacks) {
          callback(userId);
        }
      }
    });

    _socket?.on('user:offline', (data) {
      final userId = data['userId'];
      if (userId != null) {
        for (var callback in onUserOfflineCallbacks) {
          callback(userId);
        }
      }
    });
  }

  void listenToMessages() {
  _socket?.on('message:new', (data) {
    for (var callback in onMessageReceivedCallbacks) {
      callback(data);
    }
  });

    _socket?.on('message:edited', (data) {
      for (var callback in onMessageEditedCallbacks) {
        callback(data);
      }
    });

    _socket?.on('message:deleted', (data) {
      for (var callback in onMessageDeletedCallbacks) {
        callback(data);
      }
    });

    _socket?.on('message:reacted', (data) {
      for (var callback in onMessageReactedCallbacks) {
        callback(data);
      }
    });
  }

  void listenToTyping() {
    _socket?.on('message:typing', (data) {
      final userId = data['userId'] ?? '';
      final isTyping = data['isTyping'] ?? true;
      
      for (var callback in onTypingCallbacks) {
        callback({
          'userId': userId,
          'isTyping': isTyping,
        });
      }
    });
  }

  void listenToFriendRequests() {
    _socket?.on('friend:request', (data) {
      for (var callback in onFriendRequestCallbacks) {
        callback(data);
      }
    });

    _socket?.on('friend:accepted', (data) {
      for (var callback in onFriendAcceptedCallbacks) {
        callback(data);
      }
    });
  }

  void listenToMessageDelivered() {
    _socket?.on('messages:delivered', (data) {
      for (var callback in onMessageDeliveredCallbacks) {
        callback(data);
      }
    });
  }

  void listenToReadReceipts() {
    _socket?.on('message:read_receipt', (data) {
      for (var callback in onMessageReadReceiptCallbacks) {
        callback(data);
      }
    });
  }

  void listenToChatRefresh() {
    _socket?.on('chat:refresh_required', (data) {
      for (var callback in onChatRefreshRequiredCallbacks) {
        callback();
      }
    });
  }

  // =============================== CALLBACK SETTERS ==========================================
  //call backs are used here cuz they trigger on a specific event's occurence, so when certain things are either sent to 
  // web sockets server or received from server via sockets these callbacks will be called
  
  void onUserOnline(void Function(String userId) callback) {
    onUserOnlineCallbacks.add(callback);
  }

  void onUserOffline(void Function(String userId) callback) {
    onUserOfflineCallbacks.add(callback);
  }

  void onMessageReceived(void Function(Map<String, dynamic>) callback) {
    onMessageReceivedCallbacks.add(callback);
  }

  void onTyping(void Function(Map<String, dynamic>) callback) {
    onTypingCallbacks.add(callback);
  }

  void onFriendRequest(void Function(Map<String, dynamic>) callback) {
    onFriendRequestCallbacks.add(callback);
  }

  void onFriendAccepted(void Function(Map<String, dynamic>) callback) {
    onFriendAcceptedCallbacks.add(callback);
  }

  void onMessageEdited(void Function(Map<String, dynamic>) callback) {
    onMessageEditedCallbacks.add(callback);
  }

  void onMessageDeleted(void Function(Map<String, dynamic>) callback) {
    onMessageDeletedCallbacks.add(callback);
  }

  void onMessageReacted(void Function(Map<String, dynamic>) callback) {
    onMessageReactedCallbacks.add(callback);
  }

  void onMessageDelivered(void Function(Map<String, dynamic>) callback) {
    onMessageDeliveredCallbacks.add(callback);
  }

  void onMessageReadReceipt(void Function(Map<String, dynamic>) callback) {
    onMessageReadReceiptCallbacks.add(callback);
  }
  
  void onChatRefreshRequired(void Function() callback) {
    onChatRefreshRequiredCallbacks.add(callback);
  }
  
  bool get isConnected => _isConnected;
}