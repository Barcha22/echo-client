import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_response.dart';
import '../models/user.dart';
import '../../../core/network/api_client.dart';

class AuthService {
  final ApiService _api = ApiService();

  /* ============================ EMAIL VERIFICATION ============================ */
  // Send verification otp
  Future<ApiResponse> sendEmailVerificationOtp({required String email}) async {
    if (email.isEmpty) {
      return ApiResponse(status: 400, result: 'Email is required');
    }
    return await _api.post(ApiConstants.sendOtp, body: {'email': email});
  }

  // Verify OTP
  Future<ApiResponse> verifyEmailOtp({
    required String email,
    required String otp,
  }) async {
    if (email.isEmpty || otp.isEmpty) {
      return ApiResponse(status: 400, result: 'Email and OTP are required');
    }
    return await _api.post(
      ApiConstants.verifyOtp,
      body: {'email': email, 'otp': otp},
    );
  }

  // Resend OTP
  Future<ApiResponse> resendEmailVerificationOtp({
    required String email,
  }) async {
    if (email.isEmpty) {
      return ApiResponse(status: 400, result: 'Email is required');
    }
    return await _api.post(ApiConstants.resendOtp, body: {'email': email});
  }

  bool requiresVerification(ApiResponse response) {
    return response.status == 403 &&
        response.data != null &&
        response.data['requiresVerification'] == true;
  }

  String? getEmailFromVerificationResponse(ApiResponse response) {
    if (response.status == 403 && response.data != null) {
      return response.data['email']?.toString();
    }
    return null;
  }



  /* ============================ PASSWORD RESET ============================ */
  // Forgot Password - Send reset OTP
  Future<ApiResponse> forgotPassword({required String email}) async {
    if (email.isEmpty) {
      return ApiResponse(status: 400, result: 'Email is required');
    }
    return await _api.post(ApiConstants.forgotPass, body: {'email': email});
  }

  // Verify Reset OTP
  Future<ApiResponse> verifyResetOtp({
    required String email,
    required String otp,
  }) async {
    if (email.isEmpty || otp.isEmpty) {
      return ApiResponse(status: 400, result: 'Email and OTP are required');
    }
    return await _api.post(
      ApiConstants.verifyResetOtp,
      body: {'email': email, 'otp': otp},
    );
  }

  // Reset Password
  Future<ApiResponse> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    if (email.isEmpty || otp.isEmpty || newPassword.isEmpty) {
      return ApiResponse(
        status: 400,
        result: 'Email, OTP, and new password are required',
      );
    }
    if (newPassword.length < 6) {
      return ApiResponse(
        status: 400,
        result: 'Password must be at least 6 characters',
      );
    }
    return await _api.post(
      ApiConstants.resetPass,
      body: {'email': email, 'otp': otp, 'newPassword': newPassword},
    );
  }

  // Resend Reset OTP
  Future<ApiResponse> resendResetOtp({required String email}) async {
    if (email.isEmpty) {
      return ApiResponse(status: 400, result: 'Email is required');
    }
    return await _api.post(ApiConstants.resendResetOtp, body: {'email': email});
  }




  /* =============================SIGNIN AND SIGNUP AND LOGOUT AND FCM TOKEN SAVING====================== */
  // signup
  Future<ApiResponse> signup({
    required String email,
    required String username,
    required String password,
    bool isEmailVerified = false,
  }) async {
    final response = await _api.post(
      ApiConstants.signup,
      body: {
        'email': email,
        'username': username,
        'password': password,
        'isEmailVerified': isEmailVerified,
      },
    );

    // If signup successful, save token
    if (response.status == 200 && response.token != null) {
      // await _api.setToken(response.token!); //redirect user to login page after he registers not home
    }

    return response;
  }

  // signin
  Future<ApiResponse> signin({
    required String emailOrUsername,
    required String password,
  }) async {
    if (emailOrUsername.isEmpty) {
      return ApiResponse(status: 400, result: 'Email or username required');
    }
    if (password.isEmpty) {
      return ApiResponse(status: 400, result: 'Password cannot be empty');
    }

    final response = await _api.post(
      ApiConstants.signin,
      body: {
        'email': emailOrUsername,
        'username': emailOrUsername,
        'password': password,
      },
    );

    // Only save token if login is successful (status 200)
    if (response.status == 200 && response.token != null) {
      await _api.setToken(response.token!);
    }

    return response;
  }

  // logout
  Future<void> logout() async {
    await _api.clearToken();
  }

  //FCM Token for push notifications
  Future<ApiResponse> saveFcmToken(String fcmToken) async {
    if (fcmToken.isEmpty) {
      return ApiResponse(status: 400, result: 'FCM token cannot be empty');
    }
    return await _api.post(
      ApiConstants.saveFcmToken,
      body: {'fcmToken': fcmToken},
    );
  }



  /* ======================================== HELPERS ======================================== */
  // check if user is logged in
  Future<bool> isLoggedIn() async {
    final token = await _api.getToken();
    return token != null && token.isNotEmpty;
  }

  // get current user from response
  User? getUserFromResponse(ApiResponse response) {
    if (response.isSuccess && response.data != null) {
      if (response.data is Map<String, dynamic>) {
        return User.fromJson(response.data);
      }
      if (response.data is Map && response.data['user'] != null) {
        return User.fromJson(response.data['user']);
      }
    }
    return null;
  }

  // error message
  String getErrorMessage(ApiResponse response) {
    if (response.isError) {
      return response.result;
    }
    return 'Unknown error occurred';
  }

  // get current user from token
  Future<User?> getCurrentUser() async {
    final token = await _api.getToken();
    if (token == null) return null;

    try {
      final response = await _api.get(ApiConstants.getProfile);
      if (response.isSuccess && response.data != null) {
        if (response.data is Map<String, dynamic>) {
          return User.fromJson(response.data);
        }
        if (response.data is Map && response.data['user'] != null) {
          return User.fromJson(response.data['user']);
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
