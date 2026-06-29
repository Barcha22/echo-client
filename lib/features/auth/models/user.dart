class User {
  final String id;
  final String? firstName;
  final String? lastName;
  final String username;
  final String email;
  final String? photoUrl; 
  final bool isOnline;
  final DateTime? createdAt;
  final bool hasCompletedProfile;
  final String? requestStatus;
  final bool? notificationEnabled;
  final bool isEmailVerified;

  User({
    required this.id,
    this.firstName,
    this.lastName,
    required this.username,
    required this.email,
    this.photoUrl, 
    this.isOnline = false,
    this.createdAt,
    this.hasCompletedProfile=false,
    this.requestStatus,
    this.notificationEnabled,
    this.isEmailVerified=false,
    
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id'] ?? json['id'] ?? '',
      firstName: json['first_name'],
      lastName: json['last_name'],
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      photoUrl: json['photoUrl'], 
      isOnline: json['isOnline'] ?? false,
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : null,
      hasCompletedProfile: json['hasCompletedProfile'] ?? false,
      requestStatus: json['requestStatus'],
      notificationEnabled: json['notificationsEnabled'],
      isEmailVerified:json['isEmailVerified'] ?? false
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'first_name': firstName,
      'last_name': lastName,
      'username': username,
      'email': email,
      'photoUrl': photoUrl, 
      'isOnline': isOnline,
      'createdAt': createdAt?.toIso8601String(),
      'hasCompletedProfile':hasCompletedProfile,
      'requestStatus': requestStatus,
      'notificationEnabled': notificationEnabled,
      'isEmailVerified': isEmailVerified,
    };
  }
}