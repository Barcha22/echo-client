import 'dart:io';
import 'package:flutter/material.dart';
import 'package:glint/app/app_routes.dart';
import 'package:glint/core/backgrounds/chat_background.dart';
import 'package:glint/core/constants/app_colors.dart';
import 'package:glint/core/widgets/app_buttton.dart';
import 'package:image_picker/image_picker.dart';
import '../../../profile/repositories/profile_service.dart';
import '../../../../core/utils/snack_bar.dart';
import 'package:glint/config/injector.dart';

class ProfileSetup extends StatefulWidget {
  const ProfileSetup({super.key});
  static const String id = "Setup_Page";
  @override
  State<ProfileSetup> createState() => _ProfileSetupState();
}

class _ProfileSetupState extends State<ProfileSetup> {
  final _profileService = locator<ProfileService>();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();

  File? _selectedImage;
  bool _isLoading = false;

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 400,
        maxHeight: 400,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showError(
          context,
          'Error picking image: ${e.toString()}',
        );
      }
    }
  }

  Future<void> _removeImage() async {
    setState(() {
      _selectedImage = null;
    });
  }

  Future<void> _completeSetup() async {
    // Validate first name
    if (_firstNameController.text.trim().isEmpty) {
      SnackBarUtils.showError(context, 'Please enter your first name');
      return;
    }
    setState(() => _isLoading = true);
    try {
      final response = await _profileService.completeProfileSetup(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim().isNotEmpty
            ? _lastNameController.text.trim()
            : null,
        imageFile: _selectedImage,
      );
      if (!mounted) return;
      if (!response.isSuccess) {
        SnackBarUtils.showError(context, response.result);
        setState(() => _isLoading = false);
        return;
      }
      if (!mounted) return;
      SnackBarUtils.showSuccess(context, 'Profile setup complete!');
      AppNavigator.pushReplacement(AppRoutes.home);
    } catch (e) {
      SnackBarUtils.showError(context, 'Error: ${e.toString()}');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChatBackground(
      child: Scaffold(
        backgroundColor: AppColors.backgroundTransparent,
        appBar: AppBar(
          title: const Text(
            'Complete Your Profile',
            style: TextStyle(color: AppColors.textColor),
          ),
          backgroundColor: AppColors.backgroundTransparent,
          centerTitle: true,
          elevation: 0,
          automaticallyImplyLeading: false,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Profile Picture Section
                _buildProfilePictureSection(),

                const SizedBox(height: 32),

                // First Name
                _buildTextField(
                  controller: _firstNameController,
                  label: 'First Name',
                  hint: 'Enter your first name',
                  isRequired: true,
                ),

                const SizedBox(height: 16),

                // Last Name
                _buildTextField(
                  controller: _lastNameController,
                  label: 'Last Name',
                  hint: 'Enter your last name (optional)',
                  isRequired: false,
                ),

                const SizedBox(height: 32),

                // Complete Button
                _buildCompleteButton(),

                const SizedBox(height: 20),
                // skip button
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color.fromARGB(255, 78, 101, 108),
                  ),
                  onPressed: () =>
                      AppNavigator.pushAndRemoveUntil(AppRoutes.home),
                  child: Text('skip for now', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfilePictureSection() {
    return Column(
      children: [
        GestureDetector(
          onTap: _pickImage,
          child: Stack(
            children: [
              CircleAvatar(
                radius: 60,
                backgroundColor: AppColors.noAvatarBackground,
                backgroundImage: _selectedImage != null
                    ? FileImage(_selectedImage!)
                    : null,
                child: _selectedImage == null
                    ? Icon(Icons.person, size: 60, color: Colors.white70)
                    : null,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Colors.black,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.camera_alt,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Column(
          spacing: 4,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _selectedImage == null
                  ? 'Tap to add photo'
                  : 'Tap to change photo',
              style: TextStyle(color: AppColors.mutedTextColor, fontSize: 14),
            ),
            if (_selectedImage != null) ...[
              const SizedBox(width: 12),
              GestureDetector(
                onTap: _removeImage,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.close, size: 14, color: Colors.red[400]),
                      const SizedBox(width: 4),
                      Text(
                        'Remove',
                        style: TextStyle(color: Colors.red[400], fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
        Text(
          'Photo is optional',
          style: TextStyle(color: AppColors.mutedTextColor, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool isRequired,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[300],
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[500]),
            filled: true,
            fillColor: Colors.grey[800],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCompleteButton() {
    return CustomButton(
      textInfo: 'Save',
      onPressed: () => _completeSetup(),
      isLoading: _isLoading,
    );
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }
}
