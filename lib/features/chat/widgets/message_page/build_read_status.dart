import 'package:flutter/material.dart';
import 'package:glint/features/chat/models/message.dart';


class ReadStatus extends StatelessWidget{
  final Message message;

  const ReadStatus({
    super.key,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Icon(
      message.isDelivered ? Icons.done_all : Icons.done,
      color: message.isRead && message.isDelivered ? Colors.blue : Colors.white70,
      size: 16,
    );
  }
}