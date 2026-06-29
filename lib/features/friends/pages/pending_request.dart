import 'package:flutter/material.dart';
import 'package:glint/app/app_routes.dart';
import 'package:glint/config/injector.dart';
import 'package:glint/core/backgrounds/chat_background.dart';
import 'package:glint/core/network/socket_client.dart';
import '../repositories/friend_service.dart';
import '../../auth/models/user.dart';
import '../../../core/utils/snack_bar.dart';
import '../../../core/constants/app_colors.dart';

class PendingRequests extends StatefulWidget {
  const PendingRequests({super.key});

  @override
  State<PendingRequests> createState() => _PendingRequestsState();
}

class _PendingRequestsState extends State<PendingRequests> with WidgetsBindingObserver{
  
  final _friendService = locator<FriendService>();
  final  _socketService = locator<SocketService>();

  List<User> _pendingRequests = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadPendingRequests();
    _setupSocketListeners();
  }

  void _setupSocketListeners() {
    // Listen for new friend requests
    _socketService.onFriendRequest((data) {
      if (mounted) {
        _loadPendingRequests();
        SnackBarUtils.showInfo(
          context,
          '📨 New friend request from ${data['senderUsername']}',
        );
      }
    });
  }

  Future<void> _loadPendingRequests() async {
  setState(() {
    _isLoading = true;
    _error = null;
  });

  try {
    final response = await _friendService.getPendingRequests();
    if (!mounted) return;
    if (response.isSuccess) {
      setState(() {
        _pendingRequests = _friendService.parsePendingRequestsAsUsers(response);
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

  Future<void> _acceptRequest(String userId) async {
  try {
    final response = await _friendService.acceptFriendRequest(userId);
    if (!mounted) return;
    if (response.isSuccess) {
        if(mounted){
          SnackBarUtils.showSuccess(context, 'Friend added!');
        }
        setState(() {
          _pendingRequests.removeWhere((u) => u.id == userId);
        });
        await _friendService.refreshSuggestions(forceRefresh: true);
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

  Future<void> _rejectRequest(String userId) async {
    try {
      final response = await _friendService.rejectFriendRequest(userId);
      if (!mounted) return;
      if (response.isSuccess) {
        SnackBarUtils.showInfo(context, 'Request rejected');
        setState(() {
          _pendingRequests.removeWhere((u) => u.id == userId);
        });
        await _friendService.refreshSuggestions(forceRefresh: true);
      } else {
        SnackBarUtils.showError(context, response.result);
      }
    } catch (e) {
      if(mounted){
        SnackBarUtils.showError(context, 'Error: ${e.toString()}');
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return ChatBackground(
      child:Scaffold(
      backgroundColor: AppColors.backgroundTransparent,
      appBar: AppBar(
        title: const Text(
          'Pending Requests',
          style: TextStyle(color: AppColors.textColor),
        ),
        backgroundColor: AppColors.backgroundTransparent,
        centerTitle: true,
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
          onPressed: () => AppNavigator.pop(),
        ),
      ),
      
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.textColor),
            )
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 60, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(_error!, style: const TextStyle(color: AppColors.mutedTextColor)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadPendingRequests,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.buttonColor,
                        ),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _pendingRequests.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.person_add_disabled, size: 60, color: AppColors.mutedTextColor),
                          SizedBox(height: 16),
                          Text(
                            'No pending requests',
                            style: TextStyle(color: AppColors.mutedTextColor, fontSize: 16),
                          ),
                        ],
                      ),
                    )
              :  ListView.builder(
                padding: const EdgeInsets.only(top:10),
                itemCount: _pendingRequests.length,
                itemBuilder: (context, index) {
                  final user = _pendingRequests[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    color: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppColors.noAvatarBackground,
                        backgroundImage: user.photoUrl != null
                            ? NetworkImage(user.photoUrl!)
                            : null,
                        child: user.photoUrl == null
                            ? Text(
                                user.username.isNotEmpty
                                    ? user.username[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(color: AppColors.textColor),
                              )
                            : null,
                      ),
                      title: Text(
                        user.username,
                        style: const TextStyle(
                          color: AppColors.textColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: const Text(
                        'Sent you a friend request',
                        style: TextStyle(color: AppColors.mutedTextColor),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.red),
                            onPressed: () => _rejectRequest(user.id),
                          ),
                          IconButton(
                            icon: const Icon(Icons.check, color: Colors.green),
                            onPressed: () => _acceptRequest(user.id),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
    ) 
      );
  }

}