import 'package:flutter/material.dart';
import 'package:glint/app/app_routes.dart';
import 'package:glint/features/chat/pages/message_page.dart';
import '../../features/friends/pages/pending_request.dart';

class NotificationNavigation {
  static GlobalKey<NavigatorState> get navigatorKey =>AppNavigator.navigatorKey;

  static void navigateToMessagePage({
    required String friendId,
    required String friendUserName,
    String? friendPhotoUrl,
    String? friendFullName,
  }) {
    final context = navigatorKey.currentContext;
    if (context == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MessagePage(
          friendId: friendId,
          friendUserName: friendUserName,
          friendPhotoUrl: friendPhotoUrl,
          friendFullName: friendFullName ?? friendUserName,
        ),
      ),
    );
  }

  static void navigateToPendingRequests() {
    final context = navigatorKey.currentContext;
    if (context == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PendingRequests(),
      ),
    );
  }

  static void navigateToHome() {
    final context = navigatorKey.currentContext;
    if (context == null) return;

    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.home,
      (route) => false,
    );
  }
}