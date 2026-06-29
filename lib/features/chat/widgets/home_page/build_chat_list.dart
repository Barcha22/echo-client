import 'package:flutter/material.dart';
import 'package:glint/features/chat/models/message.dart';
import 'package:glint/features/chat/widgets/home_page/build_chat_card.dart';

class ChatList extends StatelessWidget {
  final List<RecentChat> chats;
  final bool isLoading;
  final String? error;
  final VoidCallback onRetry;
  final Function(RecentChat) onChatTap;
  final Function(RecentChat) onAvatarTap;
  final Function(String) onDelete;

  const ChatList({
    super.key,
    required this.chats,
    required this.isLoading,
    this.error,
    required this.onRetry,
    required this.onChatTap,
    required this.onAvatarTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.blue),
      );
    }

    if (error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 60, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              error!,
              style: const TextStyle(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              child: const Text('Retry',style: TextStyle(color:Colors.white),),
            ),
          ],
        ),
      );
    }

    if (chats.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline, size: 60, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No messages yet',
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
            SizedBox(height: 8),
            Text(
              'Start chatting with your friends!',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return ScrollConfiguration(
      behavior: const ScrollBehavior().copyWith(overscroll: false),
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 2),
        itemCount: chats.length,
        itemBuilder: (context, index) {
          final chat = chats[index];
          return Dismissible(
            key: Key(chat.friendId),
            direction: DismissDirection.endToStart,
            background: Container(
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 24),
              child: const Icon(
                Icons.delete_outline,
                color: Colors.white,
                size: 28,
              ),
            ),
            confirmDismiss: (_) async {
              return await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Delete Chat'),
                  content: Text('Delete chat with ${chat.friendName}?'),
                  backgroundColor: Colors.grey[900],
                  titleTextStyle: const TextStyle(color: Colors.white),
                  contentTextStyle: const TextStyle(color: Colors.white70),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              );
            },
            onDismissed: (_) => onDelete(chat.friendId),
            child: ChatCard(
              chat: chat,
              onTap: () => onChatTap(chat),
              onAvatarTap: () => onAvatarTap(chat),
            ),
          );
        },
      ),
    );
  }
}