import 'dart:io';
import 'package:flutter/material.dart';
import 'package:glint/app/app_routes.dart';
import 'package:glint/core/backgrounds/chat_background.dart';
import 'package:glint/core/constants/app_colors.dart';
import 'package:glint/core/widgets/app_buttton.dart';
import 'package:image_picker/image_picker.dart';
import '../../profile/repositories/profile_service.dart';
import '../../../core/utils/snack_bar.dart';
import 'package:glint/config/injector.dart';
import 'package:glint/features/auth/models/user.dart';

class EditProfile extends StatefulWidget {
  const EditProfile({super.key});
  static const String id = "EditUserProfile";
  @override
  State<EditProfile> createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
  final _profileService = locator<ProfileService>();
  
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  
  File? _selectedImage;
  bool _isLoading = false;
  User? _currentUser;
  bool _isLoadingData = true;

  @override
  void initState(){
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoadingData = true);
    try {
      final response = await _profileService.getProfile();
      if (mounted && response.isSuccess) {
        _currentUser = _profileService.parseUser(response);
        _firstNameController.text = _currentUser?.firstName ?? '';
        _lastNameController.text = _currentUser?.lastName ?? '';
        if (_currentUser?.photoUrl != null) {
          // handling remaains ->  either download the image or display via NetworkImage
        }
      }
    } catch (e) {
      //
    } finally {
      if (mounted) setState(() => _isLoadingData = false);
    }
  }

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
      if(mounted){
        SnackBarUtils.showError(context, 'Error picking image: ${e.toString()}');
      }
    }
  }

  Future<void> _removeImage() async {
    setState(() {
      _selectedImage = null;
    });
  }

  Future<void> _saveChanges() async {
    // Validate first name
    if (_firstNameController.text.trim().isEmpty) {
      SnackBarUtils.showError(context, 'Please enter your first name');
      return;
    }
    setState(() => _isLoading = true);
    try {
      //  Update name
      final nameResponse = await _profileService.updateName(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim().isNotEmpty
            ? _lastNameController.text.trim()
            : null,
      );

      if (!mounted) return;

      if (!nameResponse.isSuccess) {
        SnackBarUtils.showError(context, 'Failed to update name: ${nameResponse.result}');
        setState(() => _isLoading = false);
        return;
      }

      //  Update profile picture if changed
      if (_selectedImage != null) {
        final photoResponse = await _profileService.updateProfilePicture(_selectedImage!);
        if (!mounted) return;
        if (!photoResponse.isSuccess) {
          SnackBarUtils.showError(context, 'Name updated but photo upload failed: ${photoResponse.result}');
        }
      }
      await _profileService.markUserProfileCompleted(); //mark user profile updated when he changes anything from settings too 

      if (!mounted) return;
      SnackBarUtils.showSuccess(context,'Changes saved');
      await Future.delayed(Duration(seconds: 2));
      if (mounted) {
        AppNavigator.pop();
      }
    } catch (e) {
      if(mounted){
        SnackBarUtils.showError(context, 'Error: ${e.toString()}');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChatBackground(
      child:Scaffold(
      backgroundColor: AppColors.backgroundTransparent,
      appBar: AppBar(
        title: const Text(
          'Edit Profile',
          style: TextStyle(color: AppColors.textColor),
        ),
        backgroundColor: AppColors.backgroundTransparent,
        centerTitle: true,
        elevation: 0,
        leading:IconButton(icon: Icon(Icons.arrow_back),color: AppColors.textColor,onPressed: ()=>AppNavigator.pop()),
      ),
      body: SafeArea(
        child: _isLoadingData
            ? const Center(child: CircularProgressIndicator(color: AppColors.textColor))
            : SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _buildProfilePictureSection(),
                    const SizedBox(height: 32),
                    _buildTextField(
                      controller: _firstNameController,
                      label: 'First Name',
                      hint: 'Enter your first name',
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _lastNameController,
                      label: 'Last Name',
                      hint: 'Enter your last name (optional)',
                    ),
                    const SizedBox(height: 32),
                    _buildSaveChangesButton(),
                  ],
                ),
              ),
      ),
    ) 
      );
  }

  Widget _buildProfilePictureSection() {
    final bool hasExistingPhoto = _currentUser?.photoUrl != null && _selectedImage == null;
    final bool hasSelectedImage = _selectedImage != null;
    final bool hasImage = hasExistingPhoto || hasSelectedImage;

    return Column(
      children: [
        GestureDetector(
          onTap: _pickImage,
          child: Stack(
            children: [
              CircleAvatar(
                radius: 60,
                backgroundColor: AppColors.mutedTextColor,
                backgroundImage: hasSelectedImage
                    ? FileImage(_selectedImage!) as ImageProvider
                    : hasExistingPhoto
                        ? NetworkImage(_currentUser!.photoUrl!) as ImageProvider
                        : null,
                child: (!hasSelectedImage && !hasExistingPhoto)
                    ? Icon(Icons.person, size: 60, color: AppColors.mutedTextColor)
                    : null,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: AppColors.textFieldBackgroundColor,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.camera_alt,
                    color: AppColors.textColor,
                    size: 20,
                  ),
                ),
              ),
              // 
              if (hasImage)
                Positioned(
                  top: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: _removeImage,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close, color: AppColors.textColor, size: 16),
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (hasImage)
          const SizedBox(height: 8),
        if (hasImage)
          TextButton(
            onPressed: _removeImage,
            child: const Text('Remove Photo', style: TextStyle(color: Colors.red)),
          ),
      ],
    );
  }
  
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppColors.mutedTextColor,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          style: const TextStyle(color: AppColors.textColor),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: AppColors.mutedTextColor),
            filled: true,
            fillColor: AppColors.textFieldBackgroundColor,
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

  Widget _buildSaveChangesButton() {
    return CustomButton(
      textInfo: 'Save',
      isLoading: _isLoading,
      onPressed: _saveChanges
      );
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }
}