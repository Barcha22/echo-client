import 'package:flutter/material.dart';
import 'package:glint/app/app_routes.dart';
import 'package:glint/config/injector.dart';
import 'package:glint/core/backgrounds/comets_background.dart';
import 'package:glint/core/network/socket_client.dart'; // ADD THIS IMPORT
import '../../profile/repositories/profile_service.dart';
import '../../auth/models/user.dart';
import '../../../core/constants/app_colors.dart';

class UserProfilePage extends StatefulWidget {
  final String userId;
  final String userName;
  final String? userPhoto;
  final String fullName;

  const UserProfilePage({
    super.key,
    required this.userId,
    required this.userName,
    required this.fullName,
    this.userPhoto,
  });

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  final _profileService = locator<ProfileService>();
  final _socketService = locator<SocketService>(); 
  
  User? _user;
  bool _isLoading = true;
  
  late bool _isLiveOnline; 

  late void Function(String) _onlineCallback;
  late void Function(String) _offlineCallback;

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
    _setupLiveStatus(); 
  }

  void _setupLiveStatus() {
    _onlineCallback = (userId) {
      if (userId == widget.userId) {
        setState(() => _isLiveOnline = true);
      }
    };

    _offlineCallback = (userId) {
      if (userId == widget.userId) {
        setState(() => _isLiveOnline = false);
      }
    };

    _socketService.onUserOnline(_onlineCallback);
    _socketService.onUserOffline(_offlineCallback);
  }

  Future<void> _fetchUserProfile() async {
    setState(() => _isLoading = true);
    try {
      final response = await _profileService.getUserById(widget.userId);
      if (mounted && response.isSuccess) {
        setState(() {
          _user = _profileService.parseUser(response);
          _isLiveOnline = _user?.isOnline ?? false; 
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _socketService.onUserOnlineCallbacks.remove(_onlineCallback);
    _socketService.onUserOfflineCallbacks.remove(_offlineCallback);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return NightSkyBackground(
      child:Scaffold(
      backgroundColor: AppColors.backgroundTransparent,
      appBar: AppBar(
        title: const Text(
          'Profile',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: AppColors.backgroundTransparent,
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => AppNavigator.pop(),
        ),
      ),
      
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.blue),
            )
          : Container(
              margin: const EdgeInsets.only(top:30), // Added const
              child: Column(
                children: [
                  // avatar photo
                  CircleAvatar( 
                    radius: 60,
                    backgroundColor: AppColors.noAvatarBackground,
                    backgroundImage: _user?.photoUrl != null
                        ? NetworkImage(_user!.photoUrl!)
                        : null,
                    child: _user?.photoUrl == null
                        ? Text(
                            widget.userName.isNotEmpty
                                ? widget.userName[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // full name
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Full Name : ', style: TextStyle(color: Colors.grey, fontSize: 15)),
                      Text(widget.fullName, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.normal)),
                    ],
                  ),
                  
                  const SizedBox(height: 10,),
                  
                  // username
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Username : ', style: TextStyle(color: Colors.grey, fontSize: 15)),
                      Text(widget.userName, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.normal)),
                    ],
                  ),

                  const SizedBox(height: 10),
                  
                  // user email
                  Text(
                    _user?.email ?? 'No email',
                    style: const TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                  
                  const SizedBox(height: 4),
                  
                  // CHANGED: Use _isLiveOnline instead of _user?.isOnline
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: _isLiveOnline ? Colors.green : Colors.grey, // CHANGED
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _isLiveOnline ? 'Online' : 'Offline', // CHANGED
                        style: TextStyle(
                          color: _isLiveOnline ? Colors.green : Colors.grey, // CHANGED
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    ) 
      );
  }
}