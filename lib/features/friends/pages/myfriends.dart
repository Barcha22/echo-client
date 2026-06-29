import 'package:flutter/material.dart';
import 'package:glint/app/app_routes.dart';
import 'package:glint/config/injector.dart';
import 'package:glint/core/constants/app_colors.dart';
import 'package:glint/core/network/socket_client.dart';
import '../repositories/friend_service.dart';
import '../../auth/models/user.dart';
import '../../../core/utils/snack_bar.dart';

class MyFriends extends StatefulWidget {
  const MyFriends({super.key});

  @override
  State<MyFriends> createState() => _MyFriendsState();
}

class _MyFriendsState extends State<MyFriends> with WidgetsBindingObserver {
  
  final _friendService = locator<FriendService>();
  final  _socketService = locator<SocketService>();

  List<User> _friends = [];
  bool _isLoading = true;
  String? _error;


  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _fetchFriends();
    _setupSocketListeners();
  }

  void _setupSocketListeners() {
    _socketService.onUserOnline((userId) {
      setState(() {
        _friends = _friends.map((friend) {
          if (friend.id == userId) {
            return User(
              id: friend.id,
              username: friend.username,
              email: friend.email,
              photoUrl: friend.photoUrl,
              isOnline: true,
            );
          }
          return friend;
        }).toList();
      });
    });

    _socketService.onUserOffline((userId) {
      setState(() {
        _friends = _friends.map((friend) {
          if (friend.id == userId) {
            return User(
              id: friend.id,
              username: friend.username,
              email: friend.email,
              photoUrl: friend.photoUrl,
              isOnline: false,
            );
          }
          return friend;
        }).toList();
      });
    });
  }

  Future<void> _fetchFriends() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _friendService.getAllFriends();
      if (!mounted) return;
      if (response.isSuccess) {
        setState(() {
          _friends = _friendService.parseFriends(response);
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = response.result;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _removeFriend(User friend) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Friend'),
        content: Text('Are you sure you want to remove ${friend.username}?'),
        backgroundColor: AppColors.alertDialogBackgroundColor,
        titleTextStyle: const TextStyle(color: AppColors.textColor),
        contentTextStyle: const TextStyle(color: AppColors.mutedTextColor),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.mutedTextColor)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final response = await _friendService.removeFriend(friend.id);
      
      if (!mounted) return;

      if (response.isSuccess) {
        setState(() {
          _friends.removeWhere((f) => f.id == friend.id);
        });
        SnackBarUtils.showSuccess(context, 'Friend removed');
        await _friendService.refreshFriendsCache();
      } else {
        SnackBarUtils.showError(context, response.result);
      }
    } catch (e) {
      if(mounted){
        SnackBarUtils.showError(context, 'Error: ${e.toString()}');
      }
    }
  }

  String _getDisplayName(User friend) {
    return friend.username;
  }

  String _getDisplayName2(User friend){
    if(friend.lastName != null){
      return '${friend.firstName} ${friend.lastName}';
    }
    return friend.firstName!;
  }

  String _getUserEmail(User friend){
    return friend.email;
  }

  @override
  void dispose(){
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.circularProgressIndicatorColor),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 60, color: Colors.red),
            const SizedBox(height: 16),
            Text(_error!, style: const TextStyle(color: AppColors.mutedTextColor)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchFriends,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.buttonColor),
              child: const Text('Retry',style: TextStyle(color:AppColors.textColor),),
            ),
          ],
        ),
      );
    }

    if (_friends.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 60, color: AppColors.mutedTextColor),
            SizedBox(height: 16),
            Text(
              'No friends yet',
              style: TextStyle(color: AppColors.mutedTextColor, fontSize: 16),
            ),
            SizedBox(height: 8),
            Text(
              'Add friends to start chatting!',
              style: TextStyle(color: AppColors.mutedTextColor, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return ScrollConfiguration(
      behavior: const ScrollBehavior().copyWith(overscroll: false),
      child: RefreshIndicator(
        onRefresh: _fetchFriends,
        color: Colors.blue,
        child: ListView.builder(
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.only(top: 2),
          itemCount: _friends.length,
          itemBuilder: (context, index) {
            return _buildFriendCard(_friends[index]);
          },
        ),
      ),
    );
  }

  Widget _buildFriendCard(User friend) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 1),
      child: Material(
        color: Colors.black,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              /// Avatar
              GestureDetector(
                onTap: () {
                  AppNavigator.push(
                    AppRoutes.userProfile,
                    arguments: {
                      'userId':friend.id,
                      'userName': _getDisplayName(friend),
                      'fullName': _getDisplayName2(friend),
                      'userPhoto': friend.photoUrl,
                    }
                    );
                },
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: AppColors.noAvatarBackground,
                      backgroundImage: friend.photoUrl != null
                          ? NetworkImage(friend.photoUrl!)
                          : null,
                      child: friend.photoUrl == null
                          ? Text(
                              friend.username.isNotEmpty
                                  ? friend.username[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                color: AppColors.textColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            )
                          : null,
                    ),

                    /// Online dot
                    if (friend.isOnline)
                      Positioned(
                        bottom: 2,
                        right: 2,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.black, width: 2),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              /// Name + status
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getDisplayName(friend),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      _getUserEmail(friend),
                      style: TextStyle(
                        color: AppColors.mutedTextColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              /// 3-dot menu
              PopupMenuButton<String>(
                color: AppColors.alertDialogBackgroundColor,
                icon: const Icon(Icons.more_vert, color: AppColors.textColor),
                onSelected: (value) {
                  if (value == "chat") {
                    AppNavigator.push(
                      AppRoutes.message,
                      arguments: {
                        'friendId':friend.id,
                        'friendUserName': _getDisplayName(friend),
                        'friendPhotoUrl': friend.photoUrl,
                        'friendFullName': _getDisplayName2(friend)
                      }
                      );
                  }

                  if (value == "remove") {
                    _removeFriend(friend);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: "chat",
                    child: Row(
                      spacing: 10,
                      children: [
                        Icon(
                          Icons.chat,
                          color: AppColors.textColor,
                        ),
                        Text(
                          'chat',
                          style: TextStyle(fontSize: 15,color: AppColors.textColor),
                        )
                      ],
                    )
                  ),
                  const PopupMenuItem(
                    value: "remove",
                    child: Row(
                      spacing: 7,
                      children: [
                        Icon(
                         Icons.person_remove,
                         color: Colors.red,
                        ),
                        Text(
                          'remove',
                          style: TextStyle(fontSize: 15,color: AppColors.textColor),
                        )
                      ],
                    )
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}