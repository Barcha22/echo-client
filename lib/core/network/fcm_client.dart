import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:glint/core/network/notification_navigation.dart';

class FcmService {
  static final FcmService _instance = FcmService._internal();
  factory FcmService() => _instance;
  FcmService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  String? _fcmToken;
  bool _isInitialized = false;

  // ==================== INITIALIZATION ====================

  Future<void> init() async {
    if (_isInitialized) return;

    // Request permissions
    await _requestPermissions();

    // Initialize local notifications
    await _initLocalNotifications();

    // Get FCM token
    _fcmToken = await _fcm.getToken();

    // Listen for foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Listen for background messages
    FirebaseMessaging.onBackgroundMessage(_handleBackgroundMessage);

    // Listen for when app is opened from notification
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    _isInitialized = true;
  }

  // ==================== PERMISSIONS ====================

  Future<void> _requestPermissions() async {
    await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  // ==================== LOCAL NOTIFICATIONS ====================

  Future<void> _initLocalNotifications() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings();

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(settings:settings);
  }

  Future<void> _showLocalNotification({
    required String title,
    required String body,
    Map<String, dynamic>? payload,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'glint_channel',
      'Glint Notifications',
      channelDescription: 'Notifications for messages and friend requests',
      importance: Importance.high,
      priority: Priority.high,
      sound: RawResourceAndroidNotificationSound('default'),
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails();

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      id: DateTime.now().millisecond,
      title: title,
      body: body,
      notificationDetails: details,
      payload: payload?.toString(),
    );
  }

  // ==================== MESSAGE HANDLERS ====================

  void _handleForegroundMessage(RemoteMessage message) {
    
    final String type = message.data['type'] ?? '';
    
    if (type == 'friend_request' || type == 'friend_accepted') {
      _showLocalNotification(
        title: message.notification?.title ?? 'New Notification',
        body: message.notification?.body ?? '',
        payload: message.data,
      );
      return;
    }

  }

  @pragma('vm:entry-point')
  static Future<void> _handleBackgroundMessage(RemoteMessage message) async {
    // System handles the notification automatically
  }

  void _handleMessageOpenedApp(RemoteMessage message) {    
    final String type = message.data['type'] ?? '';
    final String? senderId = message.data['senderId'];
    final String? senderName = message.data['senderName'];
    final String? senderPhoto = message.data['senderPhoto'];
    
    if (type == 'message' && senderId != null) {
      _navigateToMessagePage(senderId, senderName ?? 'User', senderPhoto);
    } else if (type == 'friend_request') {
      _navigateToPendingRequests();
    } else if (type == 'friend_accepted') {
      // 
      _navigateToHome();
    }
  }

  // ==================== NAVIGATION HELPERS ====================

  void _navigateToMessagePage(String friendId, String friendUserName, String? friendPhotoUrl) {
    NotificationNavigation.navigateToMessagePage(
      friendId: friendId,
      friendUserName: friendUserName,
      friendPhotoUrl: friendPhotoUrl,
    );
  }

  void _navigateToPendingRequests() {
    NotificationNavigation.navigateToPendingRequests();
  }

  void _navigateToHome() {
    NotificationNavigation.navigateToHome();
  }
  
  // ==================== GETTERS ====================

  String? get fcmToken => _fcmToken;

  Future<void> refreshToken() async {
    _fcmToken = await _fcm.getToken();
  }
}