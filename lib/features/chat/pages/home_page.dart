import 'package:flutter/material.dart';
import 'package:glint/app/app_routes.dart';
import 'package:glint/core/backgrounds/chat_background.dart';
import 'package:glint/core/utils/snack_bar.dart';
import 'package:glint/features/chat/widgets/home_page/build_chat_list.dart';
import 'package:glint/core/constants/app_colors.dart';
import 'package:glint/features/chat/controllers/home_controller.dart';
import 'package:glint/features/friends/pages/add_friends.dart';
import 'package:glint/features/friends/pages/myfriends.dart';
import 'package:glint/features/profile/pages/settings.dart';
import 'package:glint/shared/widgets/bottom_navigation_bar.dart';

class HomePage extends StatefulWidget {
  static const String id = "HomePageKey";
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  late HomeController _controller;
  int _currentIndex = 0;

  final List<String> _titles = [
    "Chats",
    "My Friends",
    "Add Friends",
    "Settings",
  ];

  @override
  void initState() {
    super.initState();
    _controller = HomeController();
    _controller.init();
    _controller.addListener(() => setState(() {}));
    WidgetsBinding.instance.addObserver(this);
  }


  @override
  void didChangeDependencies() { //checks for if aanything like theme, media query or state providers has changed or not, if yes then it runs
    super.didChangeDependencies();
    _controller.refreshMessages();
  }

  @override
  void dispose() {
    _controller.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChatBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,

        appBar: AppBar(
          backgroundColor: Colors.transparent,
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
                    Colors.white.withValues(alpha: 0.3),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          title: Text(
            _titles[_currentIndex],
            style: const TextStyle(color: AppColors.textColor),
          ),
          actions: [
            if (_currentIndex == 2)
              Stack(
                children: [
                  IconButton(
                    onPressed: _goToPendingRequests,
                    icon: const Icon(
                      Icons.person_add,
                      color: AppColors.textColor,
                    ),
                  ),
                  if (_controller.pendingCount > 0)
                    Positioned(
                      right: 1,
                      top: 4,
                      child: Container(
                        padding: const EdgeInsets.all(1),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        child: Text(
                          _controller.pendingCount > 9
                              ? '9+'
                              : '${_controller.pendingCount}',
                          style: const TextStyle(
                            color: AppColors.textColor,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
          ],
        ),

        body: _getBody(_currentIndex),

        bottomNavigationBar: BottomBar(
          index: _currentIndex,
          onTap: (value) {
            setState(() {
              _currentIndex = value;
              if (value == 0) {
                _controller.clearUnreadDot();
                _controller.silentRefreshMessages();
                _controller.refreshFriendCache();
              }
              if (value == 2) {
                _controller.clearPendingDot();
              }
            });
          },
          hasUnreadMessages: _controller.hasUnreadMessages,
          hasPendingRequests: _controller.hasPendingRequests,
        ),
      ),
    );
  }

  // ======================= HELPER METHODS AND WIDGETS============================
  Widget _getBody(int index) {
    switch (index) {
      case 0:
        if (_controller.hasUnreadMessages) {
          _controller.clearUnreadDot();
        }
        return ChatList(
          chats: _controller.recentChats,
          isLoading: _controller.isLoading,
          error: _controller.error,
          onRetry: () => _controller.refreshMessages(),
          onChatTap: (chat) {
            AppNavigator.push(
              AppRoutes.message,
              arguments: {
                'friendId': chat.friendId,
                'friendUserName': chat.friendUserName,
                'friendPhotoUrl': chat.friendPhoto,
                'friendFullName': chat.friendName,
              },
            ).then((_) {
              Future.delayed(Duration(milliseconds: 300), () {
                _controller.silentRefreshMessages();
              });
            });
          },
          onAvatarTap: (chat) async {
            bool areFriends = await _controller.isFriend(chat.friendId);
            if (areFriends) {
              AppNavigator.push(
                AppRoutes.userProfile,
                arguments: {
                  'userId': chat.friendId,
                  'userName': chat.friendUserName,
                  'fullName': chat.friendName,
                  'userPhoto': chat.friendPhoto,
                },
              );
            } else {
              if (mounted) {
                SnackBarUtils.showInfo(context, 'you are not friends');
              }
            }
          },
          onDelete: (friendId) async {
            await _controller.deleteChat(friendId);
            if (mounted) {
              SnackBarUtils.showSuccess(context, 'Chat deleted successfully');
            }
          },
        );
      case 1:
        return const MyFriends();
      case 2:
        return const AddFriends();
      case 3:
        return const Settings();
      default:
        return const SizedBox.shrink();
    }
  }

  void _goToPendingRequests() async {
    await AppNavigator.push(AppRoutes.pendingRequests);
    _controller.refreshPendingCount();
    _controller.refreshFriendCache();
    _controller.silentRefreshMessages();
  }
}
