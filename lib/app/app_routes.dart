// whole apps routes
import 'package:flutter/material.dart';
import 'package:glint/features/auth/pages/auth_check.dart';
import 'package:glint/features/auth/pages/login_page.dart';
import 'package:glint/features/auth/pages/profile_setup/profile_setup.dart';
import 'package:glint/features/auth/pages/register_page.dart';
import 'package:glint/features/friends/pages/add_friends.dart';
import 'package:glint/features/chat/pages/home_page.dart';
import 'package:glint/features/friends/pages/myfriends.dart';
import 'package:glint/features/profile/pages/settings.dart';
import 'package:glint/features/chat/pages/message_page.dart';
import 'package:glint/features/friends/pages/pending_request.dart';
import 'package:glint/features/user_profile/pages/user_profile.dart';
import 'package:page_transition/page_transition.dart';
import 'package:glint/features/profile/pages/edit_current_user_profile.dart';
import 'package:glint/features/profile/pages/notification_options.dart';
import 'package:glint/features/profile/pages/about.dart';
import 'package:glint/features/profile/pages/help_and_support.dart';
import 'package:glint/features/auth/pages/email_verification/verify_email_otp.dart';
import 'package:glint/features/auth/pages/password_reset/forgot_password_page.dart';
import 'package:glint/features/auth/pages/password_reset/verify_reset_otp_page.dart';

class AppRoutes {
  // Auth related
  static const authCheck = '/auth-check';
  static const login = '/login';
  static const register = '/register';
  static const profileSetup = '/profile-setup'; //this is during first login ever
  static const currentUserProfileEdit = '/profile-edit'; //this is profile edit
  static const notificationPush = '/notifications-push';

  static const verifyOtp = 'verify-otp';

  static const forgotPassword = '/forgot-password';
  static const verifyResetOtp = '/verify-reset-otp';


  // Main app routes
  static const home = '/home'; 
  static const message= '/message'; 
  static const myFriends = '/my-friends';
  static const addFriends = '/add-friends'; 
  static const setting = '/setting';
  static const pendingRequests='/pending-requests';
  static const userProfile = '/user-profile';
  
  static const about = '/about';
  static const helpSupport = '/help';

  /* ROUTE GENERATORS */
  static Route<dynamic>? generateRoute(RouteSettings settings){
    switch(settings.name){
      case authCheck: return _buildPageTransition(const AuthCheck());
      case login: return _buildPageTransition(const LoginPage());
      case register: return _buildPageTransition(const RegisterPage());
      case profileSetup: return _buildPageTransition(const ProfileSetup());
      case verifyOtp: 
      final args = settings.arguments as Map<String,dynamic>;
      return _buildPageTransition(
        VerifyOtpPage(
          email: args['email'])
        );

      case forgotPassword: return _buildPageTransition(const ForgotPasswordPage());
      case verifyResetOtp: 
      final args = settings.arguments as Map<String,dynamic>;
      return _buildPageTransition(
        VerifyResetOtpPage(email:args['email']));

      case home: return _buildPageTransition(const HomePage());
      case message: 
        final args = settings.arguments as Map<String,dynamic>;
        return _buildPageTransition(
          MessagePage(
            friendId: args['friendId'], 
            friendUserName: args['friendUserName'], 
            friendPhotoUrl: args['friendPhotoUrl'],
            friendFullName: args['friendFullName']
            )
          );

      case myFriends: return _buildPageTransition(const MyFriends());
      case addFriends: return _buildPageTransition(const AddFriends());
      case setting: return _buildPageTransition(const Settings());
      case pendingRequests: return _buildPageTransition(const PendingRequests());

      case userProfile: 
        final args = settings.arguments as Map<String,dynamic>;
        return _buildPageTransition(
          UserProfilePage(
            userId: args['userId'], 
            userName: args['userName'],
            fullName: args['fullName'],
            userPhoto: args['userPhoto'],
            )
          );
      
      case currentUserProfileEdit: return _buildPageTransition(const EditProfile());
      case notificationPush: return _buildPageTransition(const NotificationOptions());
      case helpSupport: return _buildPageTransition(const HelpSupportPage());
      case about: return _buildPageTransition(const AboutPage());
      
      default : return _buildPageTransition(const LoginPage());
    }
  }

  /* HELPERS */
  static Route<dynamic> _buildPageTransition(Widget page){
    return PageTransition(
      type: PageTransitionType.fade,
      child:page, 
      );
  }
}


class AppNavigator{
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static BuildContext get context => navigatorKey.currentContext!;

  static Future<void> push(String routeName, {Map<String, dynamic>? arguments}) {
    ScaffoldMessenger.of(navigatorKey.currentContext!).clearSnackBars();
    return navigatorKey.currentState!.pushNamed(
      routeName,
      arguments: arguments,
    );
  }
  
  static Future<void> pushReplacement(String routeName, {Map<String, dynamic>? arguments}) {
    ScaffoldMessenger.of(navigatorKey.currentContext!).clearSnackBars();
    return navigatorKey.currentState!.pushReplacementNamed(
      routeName,
      arguments: arguments,
    );
  }
  
  static Future<void> pushAndRemoveUntil(String routeName, {Map<String, dynamic>? arguments}) {
    ScaffoldMessenger.of(navigatorKey.currentContext!).clearSnackBars();
    return navigatorKey.currentState!.pushNamedAndRemoveUntil(
      routeName,
      (route) => false,
      arguments: arguments,
    );
  }
  
  static void pop() {
    ScaffoldMessenger.of(navigatorKey.currentContext!).clearSnackBars();
    navigatorKey.currentState!.pop();
  }
 }
