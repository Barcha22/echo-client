// verify_reset_otp_page.dart
import 'package:flutter/material.dart';
import 'package:glint/app/app_routes.dart';
import 'package:glint/core/backgrounds/chat_background.dart';
import 'package:glint/core/constants/app_colors.dart';
import 'package:glint/core/utils/snack_bar.dart';
import 'package:glint/core/widgets/app_buttton.dart';
import 'package:glint/core/widgets/app_text_field.dart';
import 'package:glint/config/injector.dart';
import 'package:glint/features/auth/repositories/auth_service.dart';

class VerifyResetOtpPage extends StatefulWidget {
  static const String id = 'VerifyResetOtpPage';
  final String email;

  const VerifyResetOtpPage({super.key, required this.email});

  @override
  State<VerifyResetOtpPage> createState() => _VerifyResetOtpPageState();
}

class _VerifyResetOtpPageState extends State<VerifyResetOtpPage> {
  final _authService = locator<AuthService>();
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isResending = false;
  bool _otpVerified = false;
  int _resendTimer = 120; 
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && _resendTimer > 0) {
        setState(() {
          _resendTimer--;
        });
        _startTimer();
      } else if (mounted) {
        setState(() {
          _canResend = true;
        });
      }
    });
  }

  Future<void> _verifyOtp() async {
    if (_otpController.text.isEmpty) {
      SnackBarUtils.showError(context, 'Please enter the reset code');
      return;
    }

    setState(() => _isLoading = true);

    final response = await _authService.verifyResetOtp(
      email: widget.email,
      otp: _otpController.text,
    );

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (response.isSuccess) {
      setState(() {
        _otpVerified = true;
      });
      SnackBarUtils.showSuccess(
        context,
        'Code verified! Enter your new password.',
      );
    } else {
      SnackBarUtils.showError(context, response.result);
      _otpController.clear();
    }
  }

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    if (_newPasswordController.text != _confirmPasswordController.text) {
      SnackBarUtils.showError(context, 'Passwords do not match');
      return;
    }

    setState(() => _isLoading = true);

    final response = await _authService.resetPassword(
      email: widget.email,
      otp: _otpController.text,
      newPassword: _newPasswordController.text,
    );

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (response.isSuccess) {
      SnackBarUtils.showSuccess(context, 'Password reset successfully!');
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        AppNavigator.pushAndRemoveUntil(AppRoutes.login);
      }
    } else {
      SnackBarUtils.showError(context, response.result);
    }
  }

  Future<void> _resendOtp() async {
    if (!_canResend) return;

    setState(() => _isResending = true);

    final response = await _authService.resendResetOtp(email: widget.email);

    setState(() => _isResending = false);

    if (!mounted) return;

    if (response.isSuccess) {
      setState(() {
        _resendTimer = 120;
        _canResend = false;
      });
      _startTimer();
      SnackBarUtils.showSuccess(context, 'Reset code resent successfully!');
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
            'Reset Password',
            style: TextStyle(color: Colors.white),
          ),
        ),

        body: SafeArea(
          child: SingleChildScrollView(
            child: SizedBox(
              height: MediaQuery.of(context).size.height - 200,
              width: MediaQuery.of(context).size.width,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Icon
                  Icon(
                    _otpVerified ? Icons.check_circle : Icons.security,
                    size: 80,
                    color: _otpVerified
                        ? Colors.green[400]
                        : Colors.orange[400],
                  ),
                  const SizedBox(height: 24),

                  // Title
                  Text(
                    _otpVerified ? 'Set New Password' : 'Verify Reset Code',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Subtitle
                  Text(
                    _otpVerified
                        ? 'Enter your new password below.'
                        : 'Enter the 6-digit code sent to your email.',
                    style: TextStyle(
                      color: AppColors.mutedTextColor,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (!_otpVerified) ...[
                    const SizedBox(height: 8),
                    Text(
                      widget.email,
                      style: TextStyle(
                        color: Colors.orange[300],
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                  const SizedBox(height: 32),

                  // Form
                  Form(
                    key: _formKey,
                    child: SizedBox(
                      width: 320,
                      child: Column(
                        children: [
                          if (!_otpVerified) ...[
                            // OTP Input
                            CustomTextField(
                              controller: _otpController,
                              hintText: 'Enter 6-digit code',
                              prefixIcon: Icons.verified,
                              obscureText: false,
                              keyboardType: TextInputType.number,
                              maxLength: 6,
                              validator: (val) {
                                if (val == null || val.isEmpty) {
                                  return 'Reset code is required';
                                }
                                if (val.length != 6) {
                                  return 'Enter 6-digit code';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // Verify OTP Button
                            CustomButton(
                              textInfo: 'Verify Code',
                              isLoading: _isLoading,
                              onPressed: _verifyOtp,
                            ),

                            const SizedBox(height: 16),

                            // Resend with Timer
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "Didn't receive code?",
                                  style: TextStyle(color: Colors.grey[400]),
                                ),
                                const SizedBox(width: 8),
                                if (_canResend)
                                  TextButton(
                                    onPressed: _isResending ? null : _resendOtp,
                                    child: Text(
                                      _isResending ? 'Sending...' : 'Resend',
                                      style: const TextStyle(
                                        color: Colors.orange,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  )
                                else
                                  Text(
                                    'Resend in ${_resendTimer ~/ 60}:${(_resendTimer % 60).toString().padLeft(2, '0')}',
                                    style: TextStyle(
                                      color: Colors.grey[500],
                                      fontSize: 14,
                                    ),
                                  ),
                              ],
                            ),
                          ] else ...[
                            // New Password
                            CustomTextField(
                              controller: _newPasswordController,
                              hintText: 'New password',
                              prefixIcon: Icons.lock,
                              obscureText: true,
                              isPasswordField: true,
                              validator: (val) {
                                if (val == null || val.isEmpty) {
                                  return 'Password is required';
                                }
                                if (val.length < 6) {
                                  return 'Password must be at least 6 characters';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // Confirm Password
                            CustomTextField(
                              controller: _confirmPasswordController,
                              hintText: 'Confirm new password',
                              prefixIcon: Icons.lock_outline,
                              obscureText: true,
                              isPasswordField: true,
                              validator: (val) {
                                if (val == null || val.isEmpty) {
                                  return 'Please confirm your password';
                                }
                                if (val != _newPasswordController.text) {
                                  return 'Passwords do not match';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 24),

                            // Reset Password Button
                            CustomButton(
                              textInfo: 'Reset Password',
                              isLoading: _isLoading,
                              onPressed: _resetPassword,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _otpController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
