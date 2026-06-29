import 'package:flutter/material.dart';
import 'package:glint/app/app_routes.dart';
import 'package:glint/core/backgrounds/chat_background.dart';
import 'package:glint/core/constants/app_colors.dart';
import 'package:glint/core/utils/snack_bar.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/app_buttton.dart';
import '../repositories/auth_service.dart';
import 'package:glint/config/injector.dart';

class RegisterPage extends StatefulWidget {
  static const String id = "RegisterPageId";
  const RegisterPage({super.key});
  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _authService = locator<AuthService>();
  final TextEditingController _gmailController = TextEditingController();
  final TextEditingController _userNameController = TextEditingController();
  final TextEditingController _passOneController = TextEditingController();
  final TextEditingController _passTwoController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _showOtpScreen = false;
  int _resendTimer = 120; // 2 minutes in seconds
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
  }

  // Send OTP to email
  Future<void> _sendOtp() async {
    if (_gmailController.text.isEmpty) {
      SnackBarUtils.showError(context, 'Please enter your email first');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _authService.sendEmailVerificationOtp(
        email: _gmailController.text,
      );

      if (!mounted) return;

      if (response.isSuccess) {
        SnackBarUtils.showSuccess(context, 'OTP sent to your email!');
        await Future.delayed(Duration(seconds: 1));
        setState(() {
          _showOtpScreen = true;
          _isLoading = false;
          _resendTimer = 120;
          _canResend = false;
        });
        // Start the timer
        _startTimer();
        
      } else {
        setState(() {
          _isLoading = false;
        });
        SnackBarUtils.showError(
          context,
          'Failed to send OTP: ${response.result}',
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        SnackBarUtils.showError(context, 'Error: ${e.toString()}');
      }
    }
  }

  // Timer for resend button
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

  // Verify OTP
  Future<void> _verifyOtp() async {
    if (_otpController.text.isEmpty) {
      SnackBarUtils.showError(context, 'Please enter the OTP');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _authService.verifyEmailOtp(
        email: _gmailController.text,
        otp: _otpController.text,
      );

      if (!mounted) return;

      if (response.isSuccess) {
        setState(() {
          _isLoading = false;
        });
        SnackBarUtils.showSuccess(context, 'Email verified!');
        await Future.delayed(Duration(seconds: 1));
        // Complete registration
        await _completeRegistration();
      } else {
        setState(() {
          _isLoading = false;
        });
        SnackBarUtils.showError(context, 'Invalid OTP: ${response.result}');
        _otpController.clear();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        SnackBarUtils.showError(context, 'Error: ${e.toString()}');
      }
    }
  }

  // Complete registration after email verification
  Future<void> _completeRegistration() async {
    try {
      final response = await _authService.signup(
        email: _gmailController.text,
        username: _userNameController.text,
        password: _passOneController.text,
        isEmailVerified: true,
      );

      if (!mounted) return;

      if (response.isSuccess) {
      SnackBarUtils.showSuccess(context, 'Registration successful!');
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        AppNavigator.pushAndRemoveUntil(AppRoutes.login);
      }
    } else {
        SnackBarUtils.showError(
          context,
          'Registration Failed: ${response.result}',
        );
        _passOneController.clear();
        _passTwoController.clear();
        setState(() {
          _showOtpScreen = false;
          _otpController.clear();
        });
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

  // Resend OTP
  Future<void> _resendOtp() async {
    if (!_canResend) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _authService.resendEmailVerificationOtp(
        email: _gmailController.text,
      );

      if (!mounted) return;

      if (response.isSuccess) {
        SnackBarUtils.showSuccess(context, 'OTP resent successfully!');
        await Future.delayed(Duration(seconds: 1));
        setState(() {
          _resendTimer = 120;
          _canResend = false;
          _isLoading = false;
        });
        _startTimer();
      } else {
        setState(() {
          _isLoading = false;
        });
        SnackBarUtils.showError(
          context,
          'Failed to resend OTP: ${response.result}',
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        SnackBarUtils.showError(context, 'Error: ${e.toString()}');
      }
    }
  }

  // Handle register button press
  void _handleRegister() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_isLoading) return;
    FocusScope.of(context).unfocus();

    await _sendOtp();
  }

  @override
  Widget build(BuildContext context) {
    return ChatBackground(
      child: Scaffold(
        backgroundColor: AppColors.backgroundTransparent,

        body: SingleChildScrollView(
          child: Container(
            height: MediaQuery.of(context).size.height - 100,
            margin: EdgeInsets.only(top: 60),
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
                          "Become a part of our community. Signup to connect and share",
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

                /* Text fields and sign up button */
                SizedBox(
                  child: Column(
                    children: [
                      SizedBox(height: 20),
                      /* Textfields */
                      SizedBox(
                        width: 320,
                        child: _showOtpScreen
                            ? _buildOtpVerificationWidget()
                            : _buildRegistrationForm(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Registration Form Widget
  Widget _buildRegistrationForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          CustomTextField(
            prefixIcon: Icons.mail,
            hintText: "gmail",
            obscureText: false,
            validator: (val) {
              final gmailRegex = RegExp(
                r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
              );
              if (val == null || val.isEmpty) {
                return 'gmail is required';
              } else if (!gmailRegex.hasMatch(val)) {
                return 'enter a valid gmail';
              }
              return null;
            },
            keyboardType: TextInputType.emailAddress,
            maxLength: 40,
            controller: _gmailController,
          ),
          const SizedBox(height: 30),

          Text(
            'username must start with an alphabet and atmost 1 underscore allowed',
            style: TextStyle(color: Colors.white, fontSize: 9),
          ),

          CustomTextField(
            prefixIcon: Icons.person,
            hintText: "username",
            obscureText: false,
            controller: _userNameController,
            validator: (val) {
              final userNameRegex = RegExp(
                r'^[a-zA-Z][a-zA-Z0-9]*_?[a-zA-Z0-9]*$',
              );
              if (val == null || val.isEmpty) {
                return 'username is required';
              } else if (!userNameRegex.hasMatch(val)) {
                return 'enter a valid username';
              }
              return null;
            },
            keyboardType: TextInputType.text,
            maxLength: 20,
          ),
          const SizedBox(height: 30),

          CustomTextField(
            prefixIcon: Icons.lock,
            hintText: "password",
            obscureText: true,
            controller: _passOneController,
            isPasswordField: true,
            validator: (val) {
              if (val == null || val.isEmpty) {
                return 'password is required';
              } else if (val.length < 6) {
                return 'password must be atleast 6 characters long';
              }
              return null;
            },
            keyboardType: TextInputType.text,
            maxLength: 30,
          ),
          const SizedBox(height: 30),

          CustomTextField(
            prefixIcon: Icons.lock,
            hintText: "confirm password",
            obscureText: true,
            controller: _passTwoController,
            isPasswordField: true,
            validator: (val) {
              if (val == null || val.isEmpty) {
                return 'password is required for confirmation';
              } else if (val != _passOneController.text) {
                _passOneController.clear();
                _passTwoController.clear();
                return 'passwords do not match';
              }
              return null;
            },
            keyboardType: TextInputType.text,
            onSubmitted: (_) {
              FocusScope.of(context).unfocus();
            },
            maxLength: 30,
          ),
          const SizedBox(height: 30),

          // Sign Up button
          CustomButton(
            textInfo: "Sign Up",
            isLoading: _isLoading,
            onPressed: () => _handleRegister(),
          ),

          // Sign in navigation
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Already have an account?',
                style: TextStyle(color: Colors.white),
              ),
              TextButton(
                onPressed: () {
                  AppNavigator.pushReplacement(AppRoutes.login);
                },
                child: Text('SignIn', style: TextStyle(color: Colors.blue)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // OTP Verification Widget
  Widget _buildOtpVerificationWidget() {
    return Column(
      children: [
        // OTP Title
        Text(
          'Email Verification',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Enter the 6-digit code sent to',
          style: TextStyle(color: AppColors.mutedTextColor, fontSize: 14),
        ),
        Text(
          _gmailController.text,
          style: TextStyle(
            color: Colors.blue,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 30),

        // OTP Input
        Column(
          children: [
            CustomTextField(
              prefixIcon: Icons.verified,
              hintText: "Enter OTP",
              obscureText: false,
              controller: _otpController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              validator: (val) {
                if (val == null || val.isEmpty) {
                  return 'OTP is required';
                } else if (val.length != 6) {
                  return 'Enter 6-digit OTP';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            // Verify OTP button
            CustomButton(
              textInfo: "Verify Email",
              isLoading: _isLoading,
              onPressed: () => _verifyOtp(),
            ),

            const SizedBox(height: 16),

            // Resend OTP with Timer
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Didn't receive code?",
                  style: TextStyle(color: Colors.white),
                ),
                const SizedBox(width: 8),
                if (_canResend)
                  TextButton(
                    onPressed: _isLoading ? null : _resendOtp,
                    child: Text(
                      'Resend',
                      style: TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                else
                  Text(
                    'Resend in ${_resendTimer}s',
                    style: TextStyle(color: Colors.grey[400], fontSize: 14),
                  ),
              ],
            ),

            const SizedBox(height: 8),

            // Back to registration
            TextButton(
              onPressed: () {
                setState(() {
                  _showOtpScreen = false;
                  _otpController.clear();
                  _resendTimer = 120;
                  _canResend = false;
                });
              },
              child: Text(
                'Back to registration',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  void dispose() {
    _gmailController.dispose();
    _userNameController.dispose();
    _passOneController.dispose();
    _passTwoController.dispose();
    _otpController.dispose();
    super.dispose();
  }
}
