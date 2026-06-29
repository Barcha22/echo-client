import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_response.dart';
import '../../auth/models/user.dart';
import '../../../core/network/api_client.dart';

class FriendService {
  final ApiService _api = ApiService();
  
  // ==================== SEPARATE CACHES ====================
  
  // cache for suggestions
  List<User> _cachedSuggestions = [];
  DateTime? _suggestionsLastFetchTime;
  final Duration _suggestionsCacheDuration = Duration(hours: 24);
  
  // cache for friends 
  List<User> _cachedFriends = [];
  DateTime? _friendsLastFetchTime;
  final Duration _friendsCacheDuration = Duration(minutes: 5);

  // ==================== FRIEND STATUS CHECK ====================

  Future<bool> isFriend(String userId) async {
    if (userId.isEmpty) return false;

    // Check friends cache
    if (_cachedFriends.isNotEmpty &&
        _friendsLastFetchTime != null &&
        DateTime.now().difference(_friendsLastFetchTime!) < _friendsCacheDuration) {
      return _cachedFriends.any((friend) => friend.id == userId);
    }

    // Fetch from API if cache expired
    final response = await getAllFriends();
    if (response.isSuccess) {
      _cachedFriends = parseFriends(response);
      _friendsLastFetchTime = DateTime.now();
      return _cachedFriends.any((friend) => friend.id == userId);
    }

    return false;
  }

  Future<void> refreshFriendsCache() async {
    final response = await getAllFriends();
    if (response.isSuccess) {
      _cachedFriends = parseFriends(response);
      _friendsLastFetchTime = DateTime.now();
    }
  }

  // ==================== SEARCH USERS ====================

  Future<ApiResponse> searchUsers(String query) async {
    if (query.isEmpty) {
      return ApiResponse(
        status: 400,
        result: 'Search query cannot be empty'
      );
    }
    return await _api.get(
      '${ApiConstants.searchUsers}?searched=$query'
    );
  }

  // ==================== PENDING REQUESTS ====================

  Future<ApiResponse> getPendingRequests() async {
    return await _api.get(ApiConstants.getPending);
  }
  
  // ==================== SUGGESTED USERS ====================

  Future<ApiResponse> getSuggestedUsers({
  int limit = 10, 
  bool forceRefresh = true
  }) async {

    if (!forceRefresh && 
        _cachedSuggestions.isNotEmpty && 
        _suggestionsLastFetchTime != null && 
        DateTime.now().difference(_suggestionsLastFetchTime!) < _suggestionsCacheDuration) {
        
      return ApiResponse(
        status: 200,
        result: 'Users found (cached)',
        data: _cachedSuggestions,
      );
    }
    final response = await _api.get('${ApiConstants.suggestedUsers}?limit=$limit');
    if (response.isSuccess && response.data != null) {
      _cachedSuggestions = parseUsers(response);
      _suggestionsLastFetchTime = DateTime.now();
    }

    return response;
  }

  Future<ApiResponse> refreshSuggestions({int limit = 10, bool forceRefresh = false}) async {
    return getSuggestedUsers(limit: limit, forceRefresh: forceRefresh);
  }

  void clearSuggestionsCache() {
    _cachedSuggestions = [];
    _suggestionsLastFetchTime = null;
  }

  // ==================== FRIEND REQUESTS ====================

  Future<ApiResponse> sendFriendRequest(String userId) async {
    if (userId.isEmpty) {
      return ApiResponse(
        status: 400,
        result: 'User id cannot be empty'
      );
    }
    return await _api.post(
      ApiConstants.sendRequest,
      body: {'friendId': userId}
    );
  }

  Future<ApiResponse> acceptFriendRequest(String friendId) async {
    if (friendId.isEmpty) {
      return ApiResponse(
        status: 400,
        result: 'RequestId cannot be empty'
      );
    }
    return await _api.post(
      ApiConstants.acceptRequest,
      body: {'friendId': friendId}
    );
  }

  Future<ApiResponse> rejectFriendRequest(String friendId) async {
    if (friendId.isEmpty) {
    return ApiResponse(
      status: 400,
      result: 'RequestId cannot be empty'
    );
    }
    return await _api.post(
      ApiConstants.rejectRequest,
      body: {'friendId': friendId}
    );
  }

  // ==================== REMOVE FRIEND ====================

  Future<ApiResponse> removeFriend(String friendId) async {
    if (friendId.isEmpty) {
      return ApiResponse(
        status: 400,
        result: 'friendId cannot be empty'
      );
    }
    return await _api.post(
      ApiConstants.removeFriend,
      body: {'friendId': friendId}
    );
  }

  // ==================== GET ALL FRIENDS ====================

  Future<ApiResponse> getAllFriends() async {
    return await _api.get(ApiConstants.getFriendsList);
  }

  // ==================== HELPER METHODS ====================

  // Parse friends from API response
  List<User> parseFriends(ApiResponse response) {
    if (!response.isSuccess || response.data == null) return [];

    dynamic data = response.data;

    // If already a List<User>
    if (data is List && data.isNotEmpty && data[0] is User) {
      return data.cast<User>();
    }

    if (data is List) {
      return data.map((item) {
        if (item is Map && item['user'] != null) {
          return User.fromJson(item['user']);
        }
        return User.fromJson(item);
      }).toList();
    }
    
    if (data is Map && data['friends'] != null) {
      final friendsData = data['friends'] as List;
      return friendsData.map((json) => User.fromJson(json)).toList();
    }
    
    if (data is Map && data['requests'] != null) {
      final requestsData = data['requests'] as List;
      return requestsData.map((json) {
        if (json is Map && json['user'] != null) {
          return User.fromJson(json['user']);
        }
        return User.fromJson(json);
      }).toList();
    }

    return [];
  }

  // Parse users from search/suggestions responses
  List<User> parseUsers(ApiResponse response) {
    if (!response.isSuccess || response.data == null) return [];
  
    dynamic data = response.data;
  
    if (data is List) {
      if (data.isEmpty) return [];
      if (data[0] is User) {
        return data.cast<User>();
      }
      return data.map((json) => User.fromJson(json)).toList();
    }
  
    if (data is Map<String, dynamic>) {
      if (data.containsKey('users') && data['users'] is List) {
        final list = data['users'] as List;
        if (list.isNotEmpty && list[0] is User) {
          return list.cast<User>();
        }
        return list.map((json) => User.fromJson(json)).toList();
      }
    }
  
    return [];
  }

  // Parse pending requests from API response
  List<User> parsePendingRequestsAsUsers(ApiResponse response) {
    if (!response.isSuccess || response.data == null) return [];

    dynamic data = response.data;
    if (data is List) {
      return data.map((item) {
        if (item is Map && item['user'] != null) {
          return User.fromJson(item['user'] as Map<String, dynamic>);
        }
        return null;
      }).whereType<User>().toList();
    }
    if (data is Map && data['requests'] != null) {
      final list = data['requests'] as List;
      return list.map((item) {
        if (item is Map && item['user'] != null) {
          return User.fromJson(item['user'] as Map<String, dynamic>);
        }
        return null;
      }).whereType<User>().toList();
    }

    return [];
  }
  
  // Get single user from response
  User? parseUser(ApiResponse response) {
    if (response.isSuccess && response.data != null) {
      if (response.data is Map<String, dynamic>) {
        return User.fromJson(response.data);
      }
    }
    return null;
  }

}