import 'package:flutter/material.dart';
import 'package:glint/app/app_routes.dart';
import 'package:glint/core/backgrounds/chat_background.dart';
import 'package:glint/core/constants/app_colors.dart';
import 'package:glint/features/chat/controllers/message_controllers.dart';
import 'package:glint/features/chat/models/message.dart';
import 'package:glint/features/chat/widgets/animated_dot.dart';
import 'package:glint/features/chat/widgets/message_page/build_message_bubble.dart';
import 'package:glint/features/chat/widgets/message_page/build_message_input.dart';
import 'package:glint/features/chat/widgets/message_page/build_message_option_sheet.dart';

class MessagePage extends StatefulWidget {
  static const String id = 'MessagePageId';

  final String friendId;
  final String friendUserName;
  final String? friendPhotoUrl;
  final String? friendFullName;

  const MessagePage({
    super.key,
    required this.friendId,
    required this.friendUserName,
    this.friendPhotoUrl,
    required this.friendFullName,
  });

  @override
  State<MessagePage> createState() => _MessagePageState();
}

class _MessagePageState extends State<MessagePage> {
  late MessageController _controller;
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _editController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

 @override
  void initState() {
    super.initState();
    _controller = MessageController();
    _controller.init(widget.friendId, context);
    _controller.addListener(() => setState(() {}));    
  }

 

  void _showMessageOptions(Message message, bool isMe) {
    MessageOptionsSheet.show(
      context,
      message,
      isMe,
      onEdit: () {
        _editController.text = message.content;
        _controller.startEditing(message);
      },
      onDelete: () => _controller.deleteMessage(message),
      onReply: () {
       //
      },
      onReact: (emoji) => _controller.reactToMessage(message, emoji),
    );
  }

  void _sendMessage() {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;
    _controller.sendMessage(content, context);
    _messageController.clear();
    Future.delayed(const Duration(milliseconds: 100), () {
      _controller.silentRefresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ChatBackground(
      child:Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: AppColors.backgroundTransparent,
      
      appBar: AppBar(
        title: Row(
          children: [
            GestureDetector(
            onTap: () {
              if (_controller.isFriend) {
                AppNavigator.push(
                  AppRoutes.userProfile,
                  arguments: {
                    'userId': widget.friendId,
                    'userName': widget.friendUserName,
                    'fullName': widget.friendFullName ?? widget.friendUserName,
                    'userPhoto': widget.friendPhotoUrl ?? '',
                  },
                );
              }
            },
            child: CircleAvatar(
              radius: 20,
              backgroundColor: AppColors.noAvatarBackground,
              backgroundImage: widget.friendPhotoUrl != null
                  ? NetworkImage(widget.friendPhotoUrl!)
                  : null,
              child: widget.friendPhotoUrl == null
                  ? Text(
                      widget.friendUserName.isNotEmpty
                          ? widget.friendUserName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        color: AppColors.textColor,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
          ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.friendUserName,
                    style: const TextStyle(
                      color: AppColors.textColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  //online status
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _controller.isFriendOnline
                              ? Colors.green 
                              : Colors.grey,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _controller.isFriendOnline ? 'Online' : 'Offline',
                        style: TextStyle(
                          color: _controller.isFriendOnline 
                              ? Colors.green 
                              : Colors.grey,
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ],
              )
            ),
          ],
        ),
        backgroundColor: AppColors.backgroundTransparent,
        centerTitle: false,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2),
          child: Container(
            height: 2,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  Colors.white.withValues(alpha:0.3),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textColor),
          onPressed: () {
            AppNavigator.pop();
          },
          
        ),
      ),
      
      body: Column(
        children: [
          Expanded(
            child: _controller.isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.circularProgressIndicatorColor),
                )
              : _controller.error != null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 60,
                            color: Colors.red,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _controller.error!,
                            style: const TextStyle(color: AppColors.mutedTextColor),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () =>
                                _controller.refreshMessages(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.buttonColor,
                            ),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    )
                  : _controller.messages.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.chat_bubble_outline,
                                size: 60,
                                color: AppColors.mutedTextColor,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'No messages yet',
                                style: TextStyle(
                                  color: AppColors.mutedTextColor,
                                  fontSize: 16,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Start the conversation!',
                                style: TextStyle(
                                  color: AppColors.mutedTextColor,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ScrollConfiguration(
                          behavior: const ScrollBehavior().copyWith(
                            overscroll: false,
                          ),
                          child: ListView.builder(
                            reverse: true,
                            controller: _scrollController,
                            itemCount: _controller.messages.length,
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
                            itemBuilder: (context, index) {
                              final message = _controller.messages[index];
                              final isMe = message.senderId ==
                                  _controller.currentUser?.id;
                              final isEditing = _controller.editingMessageId ==
                                  message.id;
                              return MessageBubble(
                                message: message,
                                isMe: isMe,
                                onLongPress: _controller.isFriend?()=>_showMessageOptions(message, isMe):()=>{},
                                isEditing: isEditing,
                                onlineStatus: _controller.isFriendOnline,
                                editController: isEditing ? _editController : null,
                                onEditSubmitted: () {
                                  _controller.submitEdit(
                                    message,
                                    _editController.text.trim(),
                                    context,
                                  );
                                },
                              );
                            },
                          ),
                        ),
          ),
          if (_controller.isTyping)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  Text(
                    'Typing',
                    style: TextStyle(
                      color: AppColors.mutedTextColor,
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  SizedBox(width: 4),
                  SizedBox(
                    width: 40,
                    height: 10,
                    child: Row(
                      children: [
                        AnimatedDot(delay: Duration(milliseconds: 0)),
                        AnimatedDot(delay: Duration(milliseconds: 300)),
                        AnimatedDot(delay: Duration(milliseconds: 600)),
                        
                      ],
                    ),
                  ),
                ],
              ),
            ),
          if(_controller.isFriend)
          MessageInput(
            controller: _messageController,
            isSending: _controller.isSending,
            onTyping: (text) => _controller.sendTyping(true),
            onSend: _sendMessage,
          ),
          if(!_controller.isFriend)
            Padding(
              padding: EdgeInsets.only(bottom:25),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                spacing: 5,
                children: [
                  Icon(Icons.info,color: AppColors.mutedTextColor),
                  Text(
                'You are not friends with the user',
                style:TextStyle(
                  fontSize: 15,
                  color: AppColors.mutedTextColor,
                  )
                )
                ],
              )
            )
        ],
      ),
    ) 
      );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _editController.dispose();
    _scrollController.dispose();
    _controller.dispose();
    super.dispose();
  }
}