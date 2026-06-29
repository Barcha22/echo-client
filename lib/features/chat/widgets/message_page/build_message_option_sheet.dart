// features/chat/widgets/message_options_sheet.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:glint/core/utils/snack_bar.dart';
import 'package:glint/features/chat/models/message.dart';
import 'package:glint/features/chat/widgets/message_page/build_option_tile.dart';

class MessageOptionsSheet {
  static void show(
    BuildContext context,
    Message message,
    bool isMe, {
    required VoidCallback onEdit,
    required VoidCallback onDelete,
    required VoidCallback onReply,
    required ValueChanged<String> onReact,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isMe) ...[
              OptionTile(icon: Icons.edit, label: 'Edit', onTap: () {
                Navigator.pop(context);
                onEdit();
              }),
              OptionTile(icon: Icons.delete_outline, label: 'Delete', onTap: () {
                Navigator.pop(context);
                onDelete();
              }),
            ],
            OptionTile(icon: Icons.copy, label: 'Copy', onTap: () {
              Navigator.pop(context);
              Clipboard.setData(ClipboardData(text: message.content));
              SnackBarUtils.showSuccess(context, 'Copied!');
            }),
            OptionTile(icon: Icons.emoji_emotions, label: 'React', onTap: () {
              Navigator.pop(context);
              _showReactionPicker(context, message, onReact);
            }),
          ],
        ),
      ),
    );
  }

  static void _showReactionPicker(BuildContext context, Message message, ValueChanged<String> onReact) {
    const emojis = ['❤️', '😂', '😮', '😢', '🙏', '👍', '👎'];
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 16,
          runSpacing: 16,
          children: emojis.map((emoji) {
            return GestureDetector(
              onTap: () {
                Navigator.pop(context);
                onReact(emoji);
              },
              child: Text(emoji, style: const TextStyle(fontSize: 32)),
            );
          }).toList(),
        ),
      ),
    );
  }
}