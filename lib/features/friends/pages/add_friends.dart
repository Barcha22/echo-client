import 'package:flutter/material.dart';
import 'package:glint/app/app_routes.dart';
import 'package:glint/core/constants/app_colors.dart';
import 'package:glint/features/auth/repositories/auth_service.dart';
import '../repositories/friend_service.dart';
import '../../auth/models/user.dart';
import '../../../core/utils/snack_bar.dart';
import 'package:glint/config/injector.dart';

class AddFriends extends StatefulWidget {
  const AddFriends({super.key});

  @override
  State<AddFriends> createState() => _AddFriendsState();
}

class _AddFriendsState extends State<AddFriends> {

  final _friendService = locator<FriendService>();
  final _authService = locator<AuthService>();
  
  final TextEditingController _searchController = TextEditingController();

  List<User> _searchResults = [];
  List<User> _suggestedUsers = [];
  bool _isSearching = false;
  bool _isLoadingSuggestions = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSuggestedUsers();
  }

  Future<void> _loadSuggestedUsers() async {
    setState((){
     _isLoadingSuggestions = true;
     _error=null;
    });
    try {
      final response = await _friendService.getSuggestedUsers(forceRefresh: true);
  
      if (!mounted) return;
  
      if (response.isSuccess) {
        final allUsers = _friendService.parseUsers(response);
        final currentUser = await _authService.getCurrentUser();
        final currentUserId = currentUser?.id;
  
        setState(() {
          _suggestedUsers = allUsers.where((user) =>
            user.id != currentUserId &&          
            user.requestStatus != 'recieved' && 
            user.requestStatus != 'sent'   
          ).toList();
          _isLoadingSuggestions = false;
        });
      } else {
        setState(() {
          _isLoadingSuggestions = false;
          _error=response.result;
        });
      }
    } catch (e) {
      setState(() {
         _isLoadingSuggestions = false;
         _error=e.toString();
      });
    }
  }

  Future<void> _searchUsers(String query) async {
    if (query.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }

    setState(() => _isSearching = true);

    try {
      final response = await _friendService.searchUsers(query);
      
      if (!mounted) return;

      if (response.isSuccess) {
        setState(() {
          _searchResults = _friendService.parseUsers(response);
          _isSearching = false;
        });
      } else {
        setState(() {
          _searchResults = [];
          _isSearching = false;
        });
      }
    } catch (e) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
    }
  }

  Future<void> _sendFriendRequest(String userId) async {
    try {
      final response = await _friendService.sendFriendRequest(userId);

      if (!mounted) return;

      if (response.isSuccess) {        
        if(mounted){
          SnackBarUtils.showSuccess(context, 'Friend request sent!');
        }
        setState(() {
          _searchResults.removeWhere((u) => u.id == userId);
          _suggestedUsers.removeWhere((u) => u.id == userId);
        });
      } else {
        SnackBarUtils.showError(context, response.result);
      }
    } catch (e) {
      if(mounted){
        SnackBarUtils.showError(context, 'Error: ${e.toString()}');
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if(_error!= null){
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.red, size: 60),
            SizedBox(height: 16),
            Text(_error!, style: TextStyle(color: AppColors.mutedTextColor)),
            SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.buttonColor),
              onPressed: _loadSuggestedUsers,
              child: Text('Retry',style: TextStyle(color: AppColors.textColor),),
            ),
          ],
        ),
      );
    }else{
      return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(color: AppColors.textColor),
                  decoration: InputDecoration(
                    hintText: 'Search for users...',
                    hintStyle: TextStyle(color: AppColors.mutedTextColor),
                    prefixIcon: const Icon(Icons.search, color: AppColors.mutedTextColor),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: AppColors.mutedTextColor),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchResults = []);
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.grey[900],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: _searchUsers,
                ),
              ),
            ],
          ),
        ),

        // Content
        Expanded(
          child: _isSearching
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.circularProgressIndicatorColor),
                )
              : _searchController.text.isNotEmpty
                  ? _buildSearchResults()
                  : _buildSuggestions(),
        ),
      ],
    );
    }
  }

  Widget _buildSuggestions() {
    if (_isLoadingSuggestions) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.blue),
      );
    }

    if (_suggestedUsers.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 60, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No suggestions',
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
            SizedBox(height: 8),
            Text(
              'Start searching for friends!',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 10,vertical: 5),
          child: Text(
            'People you may know',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 0),
            itemCount: _suggestedUsers.length,
            itemBuilder: (context, index) {
              final user = _suggestedUsers[index];
              return _buildUserCard(user);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSearchResults() {
    if (_searchResults.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 60, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No users found',
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 0),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final user = _searchResults[index];
        return _buildUserCard(user);
      },
    );
  }

  Widget _buildUserCard(User user) {
    String buttonText = 'Add';
    VoidCallback? onPressed = () => _sendFriendRequest(user.id);
    Color buttonColor = Colors.blue;

    if (user.requestStatus == 'sent') {
      buttonText = 'Sent';
      onPressed = null;
      buttonColor = Colors.grey[900]!;
    } else if (user.requestStatus == 'recieved') {
      buttonText = 'Received';
      onPressed = null;
      buttonColor = Colors.grey[900]!;
    } else if (user.requestStatus == 'accepted') {
      buttonText = 'Message';
      onPressed = () {
        AppNavigator.push(
          AppRoutes.message,
          arguments: {
            'friendId':user.id,
            'friendUserName': user.username,
            'friendPhotoUrl': user.photoUrl,
            'friendFullName':(user.lastName != null && user.lastName!.isNotEmpty) 
                            ? '${user.firstName} ${user.lastName}' 
                            : '${user.firstName}'
            }
          );
      };
      buttonColor = Colors.teal;
    }

    return SizedBox(
      width: double.infinity,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            /// Avatar
            CircleAvatar(
              radius: 26,
              backgroundColor: const Color(0xFF243B55),
              backgroundImage: user.photoUrl != null
                  ? NetworkImage(user.photoUrl!)
                  : null,
              child: user.photoUrl == null
                  ? Text(
                      user.username.isNotEmpty
                          ? user.username[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),

            const SizedBox(width: 12),

            /// Name + email
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.username,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),

            /// Action button
            ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: buttonColor,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: Text(
                buttonText,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  } 

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

}