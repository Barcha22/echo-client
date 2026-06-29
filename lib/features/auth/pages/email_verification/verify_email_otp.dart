import 'package:flutter/material.dart';
import 'package:glint/app/app_routes.dart';
import 'package:glint/core/backgrounds/chat_background.dart';
import 'package:glint/core/constants/app_colors.dart';
import 'package:glint/core/utils/snack_bar.dart';
import 'package:glint/core/widgets/app_buttton.dart';
import 'package:glint/core/widgets/app_text_field.dart';
import 'package:glint/config/injector.dart';
import '../../repositories/auth_service.dart';

class VerifyOtpPage extends StatefulWidget {
  static const String id = 'VerifyOtpPage';
  final String email;
  
  const VerifyOtpPage({super.key, required this.email});

  @override
  State<VerifyOtpPage> createState() => _VerifyOtpPageState();
}

class _VerifyOtpPageState extends State<VerifyOtpPage> {
  final _authService = locator<AuthService>();
  final TextEditingController _otpController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isResending = false;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _verifyOtp() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    final response = await _authService.verifyEmailOtp(
      email: widget.email,
      otp: _otpController.text,
    );
    
    setState(() => _isLoading = false);
    
    if (!mounted) return;
    
    if (response.isSuccess) {
      if (mounted) {
        AppNavigator.pushAndRemoveUntil(AppRoutes.login);
      }
    } else {
      SnackBarUtils.showError(context, response.result);
      _otpController.clear();
    }
  }

  Future<void> _resendOtp() async {
    setState(() => _isResending = true);
    
    final response = await _authService.resendEmailVerificationOtp(
      email: widget.email,
    );
    
    setState(() => _isResending = false);
    
    if (!mounted) return;
    
    if (response.isSuccess) {
      SnackBarUtils.showSuccess(context, 'OTP resent successfully!');
    } else {
      SnackBarUtils.showError(context, response.result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChatBackground(
      child: Scaffold(
        backgroundColor: AppColors.backgroundTransparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Verify Email',
            style: TextStyle(color: Colors.white),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon
              Icon(
                Icons.email_rounded,
                size: 80,
                color: Colors.blue[400],
              ),
              const SizedBox(height: 24),
              
              // Title
              const Text(
                'Email Verification',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              
              // Subtitle
              Text(
                'Enter the 6-digit code sent to',
                style: TextStyle(
                  color: AppColors.mutedTextColor,
                  fontSize: 14,
                ),
              ),
              Text(
                widget.email,
                style: TextStyle(
                  color: Colors.blue[300],
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 32),
              
              // OTP Input
              Form(
                key: _formKey,
                child: SizedBox(
                  width: 320,
                  child: Column(
                    children: [
                      CustomTextField(
                        controller: _otpController,
                        hintText: 'Enter 6-digit OTP',
                        prefixIcon: Icons.verified,
                        obscureText: false,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        validator: (val) {
                          if (val == null || val.isEmpty) {
                            return 'OTP is required';
                          }
                          if (val.length != 6) {
                            return 'Enter 6-digit OTP';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      
                      // Verify Button
                      CustomButton(
                        textInfo: 'Verify Email',
                        isLoading: _isLoading,
                        onPressed: _verifyOtp,
                      ),
                      const SizedBox(height: 16),
                      
                      // Resend
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Didn't receive code?",
                            style: TextStyle(color: Colors.grey[400]),
                          ),
                          TextButton(
                            onPressed: _isResending ? null : _resendOtp,
                            child: Text(
                              _isResending ? 'Sending...' : 'Resend',
                              style: TextStyle(
                                color: Colors.blue,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }
}