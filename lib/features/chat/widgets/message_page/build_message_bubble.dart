import 'package:flutter/material.dart';
import 'package:glint/features/chat/models/message.dart';
import 'package:glint/features/chat/utils/message_helpers.dart';
import 'package:glint/features/chat/widgets/message_page/build_read_status.dart';

class MessageBubble extends StatelessWidget {
  final Message message;
  final bool isMe;
  final VoidCallback onLongPress;
  final bool isEditing;
  final TextEditingController? editController;
  final VoidCallback? onEditSubmitted;
  final bool onlineStatus;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    required this.onLongPress,
    required this.onlineStatus,
    this.isEditing = false,
    this.editController,
    this.onEditSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: onLongPress,
        child: IntrinsicWidth(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.60,
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isMe ? const Color.fromARGB(255, 1, 89, 80) : const Color.fromARGB(255, 39, 74, 113),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isEditing && editController != null)
                        TextField(
                          controller: editController,
                          autofocus: true,
                          style: const TextStyle(color: Colors.white, fontSize: 15),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => onEditSubmitted?.call(),
                        )
                      else
                        Text(
                          message.content,
                          style: const TextStyle(color: Colors.white, fontSize: 15),
                        ),
                      const SizedBox(height: 4),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              ChatHelpers.formatTime(message.sentAt),
                              style: const TextStyle(color: Colors.white, fontSize: 10),
                            ),
                            const SizedBox(width: 4),
                            if (isMe) ReadStatus(message: message,),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (message.reactions != null && message.reactions!.isNotEmpty)
                  Positioned(
                    bottom: -5,
                    right: isMe ? 65 : null,
                    left: isMe ? null : 2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.grey[800],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.black, width: 2),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: message.reactions!.keys
                            .map((emoji) => Text(emoji, style: const TextStyle(fontSize: 12)))
                            .toList(),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}