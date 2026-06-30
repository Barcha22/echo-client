import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_response.dart';
import '../../../core/network/api_client.dart';
import '../models/message.dart';

class MessageService {
  final ApiService _api = ApiService();

  // Send a message
  Future<ApiResponse> sendMessage({
    required String recieverId,
    required String content,
    String? replyToId,
  }) async {
    if (recieverId.isEmpty) {
      return ApiResponse(status: 400, result: 'Receiver ID cannot be empty');
    }
    if (content.isEmpty) {
      return ApiResponse(
        status: 400,
        result: 'Message content cannot be empty',
      );
    }

    return await _api.post(
      ApiConstants.sendMessages,
      body: {
        'recieverId': recieverId,
        'content': content,
        replyToId ?? 'replyToId': replyToId,
      },
    );
  }

  // delete a message
  Future<ApiResponse> deleteMessage(String messageId) async {
    if (messageId.isEmpty) {
      return ApiResponse(status: 400, result: 'Message ID cannot be empty');
    }
    return await _api.post(
      ApiConstants.deleteMessages,
      body: {'messageId': messageId},
    );
  }

  // Editing a message
  Future<ApiResponse> editMessage({
    required String messageId,
    required String newContent,
  }) async {
    if (messageId.isEmpty) {
      return ApiResponse(status: 400, result: 'Message ID cannot be empty');
    }
    if (newContent.isEmpty) {
      return ApiResponse(status: 400, result: 'New content cannot be empty');
    }
    return await _api.post(
      ApiConstants.editMessages,
      body: {'messageId': messageId, 'newContent': newContent},
    );
  }

  // retrieving messages
  Future<ApiResponse> getMessages() async {
    return await _api.get(ApiConstants.getMessages);
  }

  // retrieving chat history with a friend
  Future<ApiResponse> getChatHistory(String friendId) async {
    if (friendId.isEmpty) {
      return ApiResponse(status: 400, result: 'Friend ID cannot be empty');
    }
    return await _api.get('${ApiConstants.getMessages}?friendId=$friendId');
  }

  // marking messages as read
  Future<ApiResponse> markAsRead(String friendId) async {
    if (friendId.isEmpty) {
      return ApiResponse(status: 400, result: 'Friend ID cannot be empty');
    }
    return await _api.put(
      ApiConstants.markAsRead,
      body: {'friendId': friendId},
    );
  }

  // reacting to a message
  Future<ApiResponse> reactToMessage({
    required String messageId,
    required String emoji,
  }) async {
    if (messageId.isEmpty) {
      return ApiResponse(status: 400, result: 'Message ID cannot be empty');
    }
    if (emoji.isEmpty) {
      return ApiResponse(status: 400, result: 'Emoji cannot be empty');
    }
    return await _api.post(
      ApiConstants.reactToMessage,
      body: {'messageId': messageId, 'emoji': emoji},
    );
  }

  // getting unread messages count
  Future<ApiResponse> getUnreadCount() async {
    return await _api.get(ApiConstants.getUnread);
  }

  // getting recent unread messages with a friend
  Future<ApiResponse> getRecentMessages() async {
    return await _api.get(ApiConstants.getRecentChats);
  }

  // deleting all messages
  Future<ApiResponse> deleteAllMessages(String friendId) async {
    if (friendId.isEmpty) {
      return ApiResponse(status: 400, result: 'Friend ID was empty');
    }
    return await _api.delete(
      '${ApiConstants.deleteAllMessages}?friendId=$friendId',
    );
  }

  // ============= HELPER METHODS =============
  // parse recent chats from API response
  List<RecentChat> parseRecentChats(ApiResponse response) {
    if (response.isSuccess && response.data != null) {
      if (response.data is Map && response.data['chats'] != null) {
        final List<dynamic> chatsData = response.data['chats'];
        return chatsData.map((json) => RecentChat.fromJson(json)).toList();
      }
      if (response.data is List) {
        return (response.data as List)
            .map((json) => RecentChat.fromJson(json))
            .toList();
      }
    }
    return [];
  }

  // parse messages from API response
  List<Message> parseMessages(ApiResponse response) {
    if (response.isSuccess && response.data != null) {
      // If data is directly a List
      if (response.data is List) {
        final List<dynamic> messagesData = response.data;
        return messagesData.map((json) => Message.fromJson(json)).toList();
      }
      // If data has a 'messages' field
      if (response.data is Map && response.data['messages'] != null) {
        final List<dynamic> messagesData = response.data['messages'];
        return messagesData.map((json) => Message.fromJson(json)).toList();
      }
    }
    return [];
  }

  // parsing a single message from API response
  Message? parseMessage(ApiResponse response) {
    if (response.isSuccess && response.data != null) {
      if (response.data is Map<String, dynamic>) {
        return Message.fromJson(response.data);
      }
    }
    return null;
  }
}
