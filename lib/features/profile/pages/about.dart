import 'package:flutter/material.dart';
import 'package:glint/app/app_routes.dart';
import 'package:glint/core/backgrounds/chat_background.dart';
import 'package:glint/core/constants/app_colors.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  String _appVersion = '1.0.0';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      setState(() {
        _appVersion = packageInfo.version;
      });
    } catch (e) {
      // Fallback if package_info_plus fails
      _appVersion = '1.0.0';
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChatBackground(
      child:Scaffold(
      backgroundColor: AppColors.backgroundTransparent,
      appBar: AppBar(
        title: const Text(
          'About',
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
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              // App Logo / Icon
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppColors.noAvatarBackground,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(
                  Icons.chat_bubble,
                  color: AppColors.textColor,
                  size: 48,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Glint',
                style: TextStyle(
                  color: AppColors.textColor,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Version $_appVersion',
                style: const TextStyle(
                  color: AppColors.mutedTextColor,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 24),
              const Divider(color: AppColors.mutedTextColor, thickness: 1),
              const SizedBox(height: 16),
              const Text(
                'Glint is a simple and secure messaging app for staying connected with your friends.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.mutedTextColor,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 24),
              const Divider(color: AppColors.mutedTextColor, thickness: 1),
              const SizedBox(height: 16),
              _buildInfoRow(Icons.person, 'Developed by', '------'),
              _buildInfoRow(Icons.email, 'Email', '----------'),
              _buildInfoRow(Icons.web, 'Website', '-----------'),
              const SizedBox(height: 32),
              const Text(
                '© 2026 Glint. All rights reserved.',
                style: TextStyle(
                  color: AppColors.mutedTextColor,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    ) 
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey, size: 20),
          const SizedBox(width: 16),
          Text(
            '$label: ',
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 15,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}