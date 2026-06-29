import 'package:flutter/material.dart';
import 'package:glint/app/app_routes.dart';
import 'package:glint/core/constants/app_colors.dart';
import '../repositories/auth_service.dart';
import 'package:glint/config/injector.dart';


class AuthCheck extends StatefulWidget {
  static const String id = "AuthCheckId";
  const AuthCheck({super.key});

  @override
  State<AuthCheck> createState() => _AuthCheckState();
}

class _AuthCheckState extends State<AuthCheck> {

  final _authService = locator<AuthService>();
  
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    setState(() => _isLoading = true);
    
    final isLoggedIn = await _authService.isLoggedIn();
    
    if (mounted) {
      setState(() => _isLoading = false);
    }

    if (isLoggedIn) {
      AppNavigator.pushAndRemoveUntil(AppRoutes.home);
    } else {
      AppNavigator.pushAndRemoveUntil(AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _isLoading
            ? const CircularProgressIndicator(color: AppColors.circularProgressIndicatorColor)
            : const SizedBox.shrink(),
      ),
    );
  }

}