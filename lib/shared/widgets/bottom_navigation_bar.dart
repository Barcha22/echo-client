import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import '../../core/constants/app_colors.dart';

class BottomBar extends StatelessWidget {
  final int index;
  final ValueChanged<int> onTap;
  final bool hasUnreadMessages;
  final bool hasPendingRequests;

  const BottomBar({
    super.key,
    required this.index,
    required this.onTap,
    this.hasUnreadMessages = false,
    this.hasPendingRequests = false,
  });

  @override
  Widget build(BuildContext context) {
    final Color selected = Colors.blue;
    final Color unselected = Colors.white;
    
    return CurvedNavigationBar(
      backgroundColor: AppColors.backgroundTransparent,
      color: const Color.fromARGB(255, 46, 48, 62),
      animationCurve: Curves.easeIn,
      animationDuration: const Duration(milliseconds: 300),
      height: 60,
      index: index,
      onTap: onTap,
      items: [
        Stack(
          children: [
            Icon(Icons.chat, color: index == 0 ? selected : unselected),
            if (hasUnreadMessages)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
        
        Icon(Icons.person, color: index == 1 ? selected : unselected),
        
        Stack(
          children: [
            Icon(Icons.person_add, color: index == 2 ? selected : unselected),
            if (hasPendingRequests)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
        
        Icon(Icons.settings, color: index == 3 ? selected : unselected),
      ],
    );
  }
}