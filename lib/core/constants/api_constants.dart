class ApiConstants {
  // Localhost
  // static const String baseUrl = 'http://localhost:5000/api';

  // Android emulator
  static const String baseUrl = 'http://10.0.2.2:5000/api';
  
  // physical device 
  // static const String baseUrl = 'http://192.168.18.54:5000/api';

  /* Auth endpoints */
  static const String signin = '$baseUrl/auth/signin';
  static const String signup = '$baseUrl/auth/signup';
  static const String saveFcmToken = '$baseUrl/auth/save-fcm-token';
  static const String deleteAccount = '$baseUrl/delete-account';

  /* Friends endpoints */
  static const String searchUsers = '$baseUrl/friends/search';
  static const String sendRequest = '$baseUrl/friends/send';
  static const String acceptRequest = '$baseUrl/friends/accept';
  static const String rejectRequest = '$baseUrl/friends/reject';
  static const String removeFriend = '$baseUrl/friends/remove';
  static const String getFriendsList = '$baseUrl/friends/list';
  static const String getPending = '$baseUrl/friends/pending';
  static const String suggestedUsers='$baseUrl/friends/suggested';

  /* Messages endpoints */
  static const String getMessages='$baseUrl/messages/get';
  static const String sendMessages='$baseUrl/messages/send';
  static const String deleteMessages='$baseUrl/messages/delete';
  static const String editMessages='$baseUrl/messages/edit';
  static const String markAsRead='$baseUrl/messages/mark-all-read';
  static const String reactToMessage='$baseUrl/messages/react';
  static const String replyMessage='$baseUrl/messages/reply';
  static const String getUnread='$baseUrl/messages/unread';
  static const String getRecentChats = '$baseUrl/messages/recent-chats';
  static const String deleteAllMessages = '$baseUrl/messages/delete-all-messages';


  /* profile endpoints */
  static const String updatePicture='$baseUrl/profile/update-picture';
  static const String updateName='$baseUrl/profile/update-name'; 
  static const String getProfile='$baseUrl/profile/me';
  static const String getUserById='$baseUrl/users';
  static const String oneTimeSetup='$baseUrl/profile/complete-setup';
  static const String toggleNotifications='$baseUrl/profile/toggle-notifications';
  static const String markUserProfileCompleted='$baseUrl/profile/mark-user-profile-completed';

  /* email verification endpoints */
  static const String sendOtp='$baseUrl/send-otp';
  static const String verifyOtp='$baseUrl/verify-otp';
  static const String resendOtp='$baseUrl/resend-otp';

  /* password reset endpoints */
  static const String forgotPass = '$baseUrl/forgot-password';  
  static const String verifyResetOtp = '$baseUrl/verify-reset-otp';  
  static const String resetPass = '$baseUrl/reset-password';  
  static const String resendResetOtp = '$baseUrl/resend-reset-otp';  



  /* Headers Helper */
  static Map<String,String> getHeaders (String? token){
    return {
        'Content-Type':'application/json',
        if(token != null) 
          'Authorization' : 'Bearer $token'  
    };
  }

}