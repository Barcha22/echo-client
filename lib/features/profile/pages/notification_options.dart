import 'package:flutter/material.dart';
import 'package:glint/app/app_routes.dart';
import 'package:glint/config/injector.dart';
import 'package:glint/core/backgrounds/chat_background.dart';
import 'package:glint/core/constants/app_colors.dart';
import 'package:glint/core/utils/snack_bar.dart';
import 'package:glint/features/profile/repositories/profile_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationOptions extends StatefulWidget {
  static const String id = 'NotificationPageId';
  const NotificationOptions({super.key});

  @override
  State<NotificationOptions> createState() => _NotificationOptionsState();
}

class _NotificationOptionsState extends State<NotificationOptions> {
  final _profileService = locator<ProfileService>();
  bool _pushNotificationsEnabled = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadPreference();
  }

  Future<void> _loadPreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final localValue = prefs.getBool('notifications_enabled');
      
      if (localValue != null) {
        setState(() => _pushNotificationsEnabled = localValue);
      }

      final response = await _profileService.getProfile();
      if (response.isSuccess) {
        final user = _profileService.parseUser(response);
        if (user != null) {
          setState(() {
            _pushNotificationsEnabled = user.notificationEnabled ?? true;
          });
          // Save to local
          await prefs.setBool('notifications_enabled', _pushNotificationsEnabled);
        }
      }
    } catch (e) {
      // Ignore error, use default or local value
    }
  }

  Future<void> _toggleNotifications(bool value) async {
    setState(() {
      _pushNotificationsEnabled = value;
      _isLoading = true;
    });

    try {
      final response = await _profileService.toggleNotifications(value);
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('notifications_enabled', value);

      if (response.isSuccess) {
        // Show success feedback (optional)
      } else {
        // Revert on error
        setState(() {
          _pushNotificationsEnabled = !value;
        });
        // Show error
        if(mounted){
          SnackBarUtils.showError(context, 'Failed to update notifications setting');
        }
      }
    } catch (e) {
      // Revert on error
      setState(() {
        _pushNotificationsEnabled = !value;
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChatBackground(
      child: Scaffold(
        backgroundColor: AppColors.backgroundTransparent,
        appBar: AppBar(
          title: const Text(
            'Notifications',
            style: TextStyle(color: AppColors.textColor),
          ),
          backgroundColor: AppColors.backgroundTransparent,
          centerTitle: true,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textColor),
            onPressed: () => AppNavigator.pop(),
          ),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: Card(
              color: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: ListTile(
                leading: const Icon(Icons.notifications_active, color: AppColors.textColor),
                title: const Text(
                  'Push Notifications',
                  style: TextStyle(
                    color: AppColors.textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                trailing: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.circularProgressIndicatorColor,
                        ),
                      )
                    : Switch(
                        value: _pushNotificationsEnabled,
                        onChanged: _toggleNotifications,
                        activeThumbColor: AppColors.noAvatarBackground,
                        activeTrackColor: Colors.blue,
                        inactiveTrackColor: AppColors.mutedTextColor,
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}