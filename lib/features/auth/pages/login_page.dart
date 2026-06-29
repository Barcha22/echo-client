import 'package:flutter/material.dart';
import 'package:glint/app/app_routes.dart';
import 'package:glint/core/backgrounds/chat_background.dart';
import 'package:glint/core/constants/app_colors.dart';
import 'package:glint/features/friends/repositories/friend_service.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/app_buttton.dart';
import '../repositories/auth_service.dart';
import '../../../core/utils/snack_bar.dart';
import 'package:glint/config/injector.dart';
import '../../../core/network/fcm_client.dart';

class LoginPage extends StatefulWidget {
  static const String id = "LoginPageId";
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _authService = locator<AuthService>();
  final _friendService = locator<FriendService>();

  final TextEditingController _identityController = TextEditingController();
  final TextEditingController _passController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_isLoading) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _isLoading = true;
    });
    try {
      final response = await _authService.signin(
        emailOrUsername: _identityController.text,
        password: _passController.text,
      );
      if (!mounted) return;

      if (response.status == 403 &&
          _authService.requiresVerification(response)) {
        setState(() {
          _isLoading = false;
        });

        final email = _authService.getEmailFromVerificationResponse(response);

        if (email != null) {
          _showVerificationRequiredDialog(email);
        } else {
          SnackBarUtils.showInfo(
            context,
            'Please verify your email before logging in',
          );
        }
        return;
      }

      if (response.isSuccess) {
        final fcmToken = FcmService().fcmToken;
        if (fcmToken != null) {
          await _authService.saveFcmToken(fcmToken);
        }
        final user = _authService.getUserFromResponse(response);
        if (mounted) {
          SnackBarUtils.showSuccess(context, 'Login successful');
        }

        await _friendService.refreshSuggestions(
          forceRefresh: true,
        ); // Suggestions cache

        await _friendService.refreshFriendsCache();
        if (user != null && user.hasCompletedProfile == false) {
          await Future.delayed(Duration(seconds: 1));
          if (mounted) {
            AppNavigator.pushAndRemoveUntil(AppRoutes.profileSetup);
          }
        } else {
          await Future.delayed(const Duration(seconds: 1));
          if (mounted) {
            _friendService.refreshFriendsCache();
            AppNavigator.pushAndRemoveUntil(AppRoutes.home);
          }
        }
      } else {
        SnackBarUtils.showError(context, response.result);
        _passController.clear();
      }
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showInfo(context, 'Error: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showVerificationRequiredDialog(String email) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Email Verification Required'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Please verify your email address before logging in.',
              style: TextStyle(color: Colors.grey[700]),
            ),
            const SizedBox(height: 8),
            Text(
              'An OTP has been sent to:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            Text(
              email,
              style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Check your inbox and enter the 6-digit code.',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Navigate to OTP verification screen
              AppNavigator.push(
                AppRoutes.verifyOtp,
                arguments: {'email': email},
              );
            },
            child: const Text('Verify Now'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChatBackground(
      child: Scaffold(
        backgroundColor: AppColors.backgroundTransparent,
        body: SingleChildScrollView(
          child: Container(
            height: MediaQuery.of(context).size.height - 190,
            margin: EdgeInsets.only(top: 150),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                /* logo and description */
                SizedBox(
                  child: Column(
                    children: [
                      Image.asset('assets/icons/icon-white.png', height: 80),
                      Center(
                        child: Text(
                          "Welcome Back! Sign in to catch up with your circle",
                          style: TextStyle(
                            color: AppColors.mutedTextColor,
                            fontSize: 15,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),

                /* sign in form */
                SizedBox(
                  width: 320,
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        //gmail or username
                        CustomTextField(
                          controller: _identityController,
                          obscureText: false,
                          hintText: "gmail or username",
                          prefixIcon: Icons.mail,
                          validator: (val) {
                            if (val == null || val.isEmpty) {
                              return 'username or gmail required';
                            }
                            return null;
                          },
                          keyboardType: TextInputType.emailAddress,
                        ),
                        SizedBox(height: 20),

                        // password
                        CustomTextField(
                          controller: _passController,
                          hintText: "password",
                          prefixIcon: Icons.lock,
                          obscureText: true,
                          isPasswordField: true,
                          validator: (val) {
                            if (val == null || val.isEmpty) {
                              debugPrint('ts' * 20);
                              return 'password is required';
                            }
                            return null;
                          },
                          keyboardType: TextInputType.text,
                          onSubmitted: (_) {
                            FocusScope.of(context).unfocus();
                          },
                        ),

                        // forgot password
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton(
                            onPressed: () => AppNavigator.pushReplacement(AppRoutes.forgotPassword),
                            child: Text(
                              'Forgot Password?',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        ),
                        SizedBox(height: 20),

                        // login button
                        CustomButton(
                          textInfo: 'Sign In',
                          isLoading: _isLoading,
                          onPressed: () => _handleLogin(),
                        ),

                        SizedBox(height: 20),
                        //divider
                        Row(
                          children: [
                            Expanded(
                              child: Divider(
                                color: Colors.grey[400],
                                thickness: 1,
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                'or sign up',
                                style: TextStyle(color: Colors.grey[400]),
                              ),
                            ),
                            Expanded(
                              child: Divider(
                                color: Colors.grey[400],
                                thickness: 1,
                              ),
                            ),
                          ],
                        ),

                        //signup link
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Don't have an account?",
                              style: TextStyle(color: Colors.grey[300]),
                            ),
                            TextButton(
                              onPressed: () =>
                                  AppNavigator.push(AppRoutes.register),
                              child: Text(
                                'Sign Up',
                                style: TextStyle(color: Colors.blue),
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
      ),
    );
  }

  @override
  void dispose() {
    _identityController.dispose();
    _passController.dispose();
    super.dispose();
  }
}
