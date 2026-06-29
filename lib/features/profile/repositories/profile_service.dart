import 'dart:io';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_response.dart';
import '../../auth/models/user.dart';
import '../../../core/network/api_client.dart';

class ProfileService {
  final ApiService _api = ApiService();

  Future<ApiResponse> updateProfilePicture(File imageFile) async {
    try {
      // Validate file exists
      if (!await imageFile.exists()) {
        return ApiResponse(status: 400, result: 'Image file does not exist');
      }

      // Validate file size (max 5MB)
      final fileSize = await imageFile.length();
      if (fileSize > 5 * 1024 * 1024) {
        return ApiResponse(
          status: 400,
          result: 'Image size must be less than 5MB',
        );
      }

      // Use multipartPost for file upload
      return await _api.multipart(
        ApiConstants.updatePicture,
        imageFile.path,
        'image', // Field name - matches your backend
      );
    } catch (e) {
      return ApiResponse(
        status: 500,
        result: 'Error uploading image: ${e.toString()}',
      );
    }
  }

  Future<ApiResponse> updateName({String? firstName, String? lastName}) async {
    // Validate at least one field is provided
    if ((firstName == null || firstName.isEmpty) &&
        (lastName == null || lastName.isEmpty)) {
      return ApiResponse(
        status: 400,
        result: 'At least one name field is required',
      );
    }

    // Build body with only provided fields
    final Map<String, dynamic> body = {};
    if (firstName != null && firstName.isNotEmpty) {
      body['first_name'] = firstName.trim();
    }
    if (lastName != null && lastName.isNotEmpty) {
      body['last_name'] = lastName.trim();
    }

    return await _api.put(ApiConstants.updateName, body: body);
  }

  //@Depracated : used by devs to tell other devs to use a newer function instead -> sending warnings
  @Deprecated('Use updateName() instead')
  Future<ApiResponse> updateProfileName(String newName) async {
    if (newName.isEmpty) {
      return ApiResponse(status: 400, result: 'Name cannot be empty');
    }
    if (newName.length < 3) {
      return ApiResponse(
        status: 400,
        result: 'Name must be at least 3 characters',
      );
    }
    if (newName.length > 20) {
      return ApiResponse(
        status: 400,
        result: 'Name cannot exceed 20 characters',
      );
    }
    return await _api.post(ApiConstants.updateName, body: {'newName': newName});
  }

  Future<ApiResponse> getProfile() async {
    return await _api.get(ApiConstants.getProfile);
  }

  Future<ApiResponse> getUserById(String userId) async {
    if (userId.isEmpty) {
      return ApiResponse(status: 400, result: 'User ID cannot be empty');
    }
    return await _api.get('${ApiConstants.getUserById}/$userId');
  }

  Future<ApiResponse> searchUsers(String query) async {
    if (query.isEmpty) {
      return ApiResponse(status: 400, result: 'Search query cannot be empty');
    }
    return await _api.get('${ApiConstants.searchUsers}?searched=$query');
  }

  Future<ApiResponse> completeProfileSetup({
    required String firstName,
    String? lastName,
    File? imageFile,
  }) async {
    try {
      // If there's an image, use multipart
      if (imageFile != null) {
        return await _api.multipart(
          ApiConstants.oneTimeSetup,
          imageFile.path,
          'image',
          fields: {
            'first_name': firstName,
            if (lastName != null && lastName.isNotEmpty) 'last_name': lastName,
          },
        );
      }
      final Map<String, dynamic> body = {'first_name': firstName};
      if (lastName != null && lastName.isNotEmpty) {
        body['last_name'] = lastName;
      }

      return await _api.post(ApiConstants.oneTimeSetup, body: body);
    } catch (e) {
      return ApiResponse(status: 500, result: 'Error: ${e.toString()}');
    }
  }

  Future<ApiResponse> toggleNotifications(bool enabled) async {
    return await _api.post(
      ApiConstants.toggleNotifications,
      body: {'enabled': enabled},
    );
  }

  Future<ApiResponse> markUserProfileCompleted() async {
    return await _api.post(ApiConstants.markUserProfileCompleted);
  }

  Future<ApiResponse> deleteAccountPermenantly() async {
    return await _api.post(ApiConstants.deleteAccount);
  }

  // ============= HELPER METHODS =============
  // Parse user from response
  User? parseUser(ApiResponse response) {
    if (response.isSuccess && response.data != null) {
      if (response.data is Map<String, dynamic>) {
        return User.fromJson(response.data);
      }
      // Handle case where user is inside 'user' field
      if (response.data is Map && response.data['user'] != null) {
        return User.fromJson(response.data['user']);
      }
    }
    return null;
  }

  // Parse users list from response
  List<User> parseUsers(ApiResponse response) {
    if (response.isSuccess && response.data != null) {
      if (response.data is List) {
        return (response.data as List)
            .map((json) => User.fromJson(json))
            .toList();
      }
      if (response.data is Map && response.data['users'] != null) {
        final List<dynamic> usersData = response.data['users'];
        return usersData.map((json) => User.fromJson(json)).toList();
      }
    }
    return [];
  }

  // Get error message from response
  String getErrorMessage(ApiResponse response) {
    if (response.isError) {
      return response.result;
    }
    return 'Unknown error occurred';
  }
}
