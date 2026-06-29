import 'dart:async';

import 'package:flutter/material.dart';
import 'package:glint/app/app_routes.dart';
import 'package:glint/core/backgrounds/chat_background.dart';
import 'package:glint/core/constants/app_colors.dart';
import 'package:glint/core/utils/snack_bar.dart';
import 'package:glint/core/widgets/app_buttton.dart';
import 'package:glint/core/widgets/app_text_field.dart';
import 'package:glint/config/injector.dart';
import 'package:glint/features/auth/repositories/auth_service.dart';

class ForgotPasswordPage extends StatefulWidget {
  static const String id = 'ForgotPasswordPage';
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _authService = locator<AuthService>();
  final TextEditingController _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  int _resendTimer = 60;
  bool _isSendDisabled = false;
  Timer? _timer;

  Future<void> _sendResetOtp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final response = await _authService.forgotPassword(
      email: _emailController.text.trim(),
    );

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (response.isSuccess) {
      _startForgotPageTimer();
      SnackBarUtils.showSuccess(context, 'Reset code sent to your email!');
      // Navigate to OTP verification
      AppNavigator.push(
        AppRoutes.verifyResetOtp,
        arguments: {'email': _emailController.text.trim()},
      );
    } else {
      SnackBarUtils.showError(context, response.result);
    }
  }

  void _startForgotPageTimer() {
    _timer?.cancel();

    setState(() {
      _resendTimer = 60;
      _isSendDisabled = true;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendTimer <= 0) {
        setState(() {
          _isSendDisabled = false;
        });
        timer.cancel();
      } else {
        setState(() {
          _resendTimer--;
        });
      }
    });
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
            'Forgot Password',
            style: TextStyle(color: Colors.white),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon
              Icon(Icons.lock_reset, size: 80, color: Colors.orange[400]),
              const SizedBox(height: 24),

              // Title
              const Text(
                'Reset Password',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              // Subtitle
              Text(
                'Enter your email address and we\'ll send you a code to reset your password.',
                style: TextStyle(color: AppColors.mutedTextColor, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Email Input
              Form(
                key: _formKey,
                child: SizedBox(
                  width: 320,
                  child: Column(
                    children: [
                      CustomTextField(
                        controller: _emailController,
                        hintText: 'Enter your email',
                        prefixIcon: Icons.email,
                        obscureText: false,
                        keyboardType: TextInputType.emailAddress,
                        validator: (val) {
                          if (val == null || val.isEmpty) {
                            return 'Email is required';
                          }
                          final emailRegex = RegExp(
                            r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
                          );
                          if (!emailRegex.hasMatch(val)) {
                            return 'Enter a valid email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),

                      // Send Button
                      CustomButton(
                        textInfo: _isSendDisabled
                            ? 'Wait ${_resendTimer}s'
                            : 'Send Reset Code',
                        isLoading: _isLoading,
                        onPressed: _isSendDisabled ? null : _sendResetOtp,
                      ),

                      const SizedBox(height: 16),

                      // Back to login
                      TextButton(
                        onPressed: () {
                          _timer?.cancel();
                          AppNavigator.pushAndRemoveUntil(AppRoutes.login);
                        },
                        child: Text(
                          'Back to Login',
                          style: TextStyle(color: Colors.grey[400]),
                        ),
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
    _emailController.dispose();
    _timer?.cancel();
    super.dispose();
  }
}
