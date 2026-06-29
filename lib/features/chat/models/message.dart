// Message model
class Message {
  final String id;
  final String senderId;
  final String recieverId;
  final String content;
  final DateTime sentAt;
  bool isRead;
  final String? replyToId;
  Map<String, dynamic>? reactions;
  final String? senderName;
  final String? recieverName; 
  final String? replyToContent;
  final String? replyToSenderName;
  bool isDelivered;

  Message({
    required this.id,
    required this.senderId,
    required this.recieverId,
    required this.content,
    required this.sentAt,
    this.isRead = false,
    this.replyToId,
    this.reactions,
    this.senderName,
    this.recieverName, 
    this.replyToContent,
    this.replyToSenderName,
    this.isDelivered=false,
  });

  Message copyWith({
    String? id,
    String? senderId,
    String? recieverId,
    String? content,
    DateTime? sentAt,
    bool? isRead,
    String? replyToId,
    Map<String, dynamic>? reactions,
    String? senderName,
    String? recieverName,
    String? replyToContent,
    String? replyToSenderNam,
    bool? isDelivered,
  }) {
    return Message(
      id:id??this.id,
      senderId:senderId??this.senderId,
      recieverId:recieverId??this.recieverId,
      content:content??this.content,
      sentAt:sentAt??this.sentAt,
      isRead:isRead??this.isRead,
      replyToId:replyToId??this.replyToId,
      reactions:reactions??this.reactions,
      senderName:senderName??this.senderName,
      recieverName:recieverName??this.recieverName,
      replyToContent:replyToContent??this.replyToContent,
      replyToSenderName:replyToSenderNam??replyToSenderName,
      isDelivered: isDelivered??this.isDelivered,
    );
  }

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['_id'] ?? json['id'] ?? '',
      senderId: json['senderId'] ?? '',
      recieverId: json['recieverId'] ?? '',
      content: json['content'] ?? '',
      sentAt: json['sentAt'] != null 
          ? DateTime.parse(json['sentAt']) 
          : DateTime.now(),
      isRead: json['isRead'] ?? false,
      replyToId: json['replyToId'],
      reactions: json['reactions'] != null ? Map<String, dynamic>.from(json['reactions']) : null,
      senderName: json['senderName'] ?? json['senderId'],
      recieverName: json['recieverName'] ?? json['recieverId'], 
      replyToContent: json['replyToContent'] ?? json['replyTo']?['content'],
      replyToSenderName: json['replyToSenderName'] ?? json['replyTo']?['senderName'],
      isDelivered: json['isDelivered'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'senderId': senderId,
      'recieverId': recieverId,
      'content': content,
      'sentAt': sentAt.toIso8601String(),
      'isRead': isRead,
      'replyToId': replyToId,
      'reactions': reactions,
      'isDeliverd':isDelivered,
    };
  }
}


class RecentChat {
  final String friendId;
  final String friendUserName;
  final String friendName;
  final String? friendPhoto;
  final bool friendOnline;
  final Message lastMessage;
  final int unreadCount;

  RecentChat ({
    required this.friendId,
    required this.friendUserName,
    required this.friendName,
    this.friendPhoto,
    required this.friendOnline,
    required this.lastMessage,
    required this.unreadCount,
  });

   RecentChat copyWith({
    String? friendId,
    String? friendUserName,
    String? friendName,
    String? friendPhoto,
    bool? friendOnline,
    Message? lastMessage,
    int? unreadCount,
  }) {
    return RecentChat(
      friendId: friendId ?? this.friendId,
      friendUserName: friendUserName ?? this.friendUserName,
      friendName: friendName ?? this.friendName,
      friendPhoto: friendPhoto ?? this.friendPhoto,
      friendOnline: friendOnline ?? this.friendOnline,
      lastMessage: lastMessage ?? this.lastMessage,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }

  factory RecentChat.fromJson(Map<String, dynamic> json) {
    return RecentChat(
      friendId: json['friendId'] ?? '',
      friendUserName: json['friendUserName'] ?? '',
      friendName: json['friendName'] ?? 'Unknown',
      friendPhoto: json['friendPhoto'],
      friendOnline: json['friendOnline'] ?? false,
      lastMessage: Message.fromJson(json['lastMessage']),
      unreadCount: json['unreadCount'] ?? 0,
    );
  }
}