import 'package:flutter/material.dart';
import 'package:glint/app/app_routes.dart';
import 'package:glint/config/injector.dart';
import 'package:glint/core/constants/app_colors.dart';
import 'package:glint/core/network/socket_client.dart';
import '../../auth/repositories/auth_service.dart';
import '../repositories/profile_service.dart';
import '../../auth/models/user.dart';
import '../../../core/utils/snack_bar.dart';

class Settings extends StatefulWidget {
  const Settings({super.key});

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  final _authService = locator<AuthService>();
  final _profileService = locator<ProfileService>();

  final _deleteController = TextEditingController();

  User? _currentUser;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final response = await _profileService.getProfile();
      if (!mounted) return;
      if (response.isSuccess) {
        setState(() {
          _currentUser = _profileService.parseUser(response);
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _error = response.result;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  String _getDisplayName() {
    if (_currentUser == null) return 'Your Name';
    if (_currentUser!.firstName != null && _currentUser!.lastName != null) {
      return '${_currentUser!.firstName} ${_currentUser!.lastName}';
    }
    if (_currentUser!.firstName != null) return _currentUser!.firstName!;
    if (_currentUser!.lastName != null) return _currentUser!.lastName!;
    return _currentUser!.username;
  }

  String _getStatus() {
    if (_currentUser == null) return 'Available';
    return _currentUser!.isOnline ? '🟢 Online' : '⚪ Offline';
  }

  void _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        backgroundColor: AppColors.alertDialogBackgroundColor,
        titleTextStyle: const TextStyle(
          color: AppColors.textColor,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        contentTextStyle: const TextStyle(color: AppColors.mutedTextColor),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.mutedTextColor),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await _authService.logout();
    if (mounted) {
      SnackBarUtils.showSuccess(context, 'Logout Successful');
      locator<SocketService>().disconnect(); // then disconnect the socket
      AppNavigator.pushReplacement(AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.red, size: 60),
            SizedBox(height: 16),
            Text(_error!, style: TextStyle(color: AppColors.mutedTextColor)),
            SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.buttonColor,
              ),
              onPressed: _loadUserProfile,
              child: Text(
                'Retry',
                style: TextStyle(color: AppColors.textColor),
              ),
            ),
          ],
        ),
      );
    } else {
      return _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: AppColors.circularProgressIndicatorColor,
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.only(left: 20, right: 20),
              child: Column(
                children: [
                  // Profile Section
                  _buildProfileSection(),
                  const SizedBox(height: 32),

                  // Settings Options
                  _buildSettingTile(
                    icon: Icons.person_outline,
                    title: 'Edit Profile',
                    onTap: () async {
                      await AppNavigator.push(AppRoutes.currentUserProfileEdit);
                      _loadUserProfile();
                    },
                  ),
                  _buildSettingTile(
                    icon: Icons.notifications_outlined,
                    title: 'Notifications',
                    onTap: () async {
                      await AppNavigator.push(AppRoutes.notificationPush);
                    },
                  ),
                  _buildSettingTile(
                    icon: Icons.help_outline,
                    title: 'Help & Support',
                    onTap: () async {
                      await AppNavigator.push(AppRoutes.helpSupport);
                    },
                  ),
                  _buildSettingTile(
                    icon: Icons.info_outline,
                    title: 'About',
                    onTap: () async {
                      await AppNavigator.push(AppRoutes.about);
                    },
                  ),

                  const SizedBox(height: 24),

                  // Logout Button
                  _buildLogoutButton(),

                  const SizedBox(height: 24),
                  _buildAccountDeletionButton(),
                ],
              ),
            );
    }
  }

  Widget _buildProfileSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF000000),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          // Profile Picture
          CircleAvatar(
            radius: 40,
            backgroundColor: AppColors.noAvatarBackground,
            backgroundImage: _currentUser?.photoUrl != null
                ? NetworkImage(_currentUser!.photoUrl!)
                : null,
            child: _currentUser?.photoUrl == null
                ? const Icon(Icons.person, size: 40, color: AppColors.textColor)
                : null,
          ),
          const SizedBox(width: 20),
          // Name and Status
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getDisplayName(),
                  style: const TextStyle(
                    color: AppColors.textColor,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _getStatus(),
                  style: TextStyle(color: AppColors.textColor, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF000000),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: AppColors.textColor),
        title: Text(
          title,
          style: const TextStyle(color: AppColors.textColor, fontSize: 16),
        ),
        trailing: const Icon(
          Icons.chevron_right,
          color: AppColors.mutedTextColor,
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildLogoutButton() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextButton(
        onPressed: _handleLogout,
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout, color: Colors.white),
            SizedBox(width: 8),
            Text(
              'Logout',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountDeletionButton() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextButton(
        onPressed: () => _showDeleteDialog(context),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 8),
            Text(
              'Delete Account',
              style: TextStyle(
                color: Colors.red,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    _deleteController.clear();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            bool isConfirmed = _deleteController.text == 'DELETE';

            return AlertDialog(
              backgroundColor: const Color(0xFF243B55),
              title: Text(
                'Delete Account',
                style: TextStyle(color: Colors.white),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'This action cannot be undone. All your data will be permanently deleted.',
                    style: TextStyle(color: Colors.white70),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 16),
                  TextField(
                    controller: _deleteController,
                    onChanged: (value) {
                      setDialogState(() {});
                    },
                    decoration: InputDecoration(
                      hintText: '',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      fillColor: Colors.white70,
                      filled: true,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      errorText: isConfirmed
                          ? null
                          : 'Type "DELETE" to confirm',
                      errorStyle: TextStyle(color: Colors.red, fontSize: 12),
                    ),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    _deleteController.clear();
                    Navigator.pop(dialogContext);
                  },
                  child: Text('Cancel', style: TextStyle(color: Colors.white)),
                ),
                ElevatedButton(
                  onPressed: isConfirmed
                      ? () {
                          Navigator.pop(dialogContext);
                          _performDeleteAccount();
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isConfirmed ? Colors.red : Colors.grey,
                  ),
                  child: Text('Delete', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    ).then((_) {
      _deleteController.clear();
    });
  }

  Future<void> _performDeleteAccount() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) =>
          const Center(child: CircularProgressIndicator(color: Colors.red)),
    );

    try {
      await _profileService.deleteAccountPermenantly();

      if (mounted) {
        Navigator.pop(context);
        SnackBarUtils.showSuccess(context, 'Account deleted successfully');
        await Future.delayed(Duration(seconds: 1));
        await _authService.logout(); //for clearing out token and going to log in page
        AppNavigator.pushAndRemoveUntil(AppRoutes.login);
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        SnackBarUtils.showError(
          context,
          'Failed to delete account: ${e.toString()}',
        );
      }
    } finally {
      _deleteController.clear();
    }
  }

  @override
  void dispose() {
    _deleteController.dispose();
    super.dispose();
  }
}
