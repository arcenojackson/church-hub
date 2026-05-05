import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';

import '../../../core/config/firebase_config.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  String? _fcmToken;

  String? get fcmToken => _fcmToken;

  Future<void> initialize() async {
    if (_initialized) return;
    if (kIsWeb) {
      _initialized = true;
      return;
    }

    try {
      await _requestPermissions();
      await _initLocal();
      _fcmToken = await _messaging.getToken();

      _messaging.onTokenRefresh.listen(_onTokenRefresh);
      FirebaseMessaging.onMessage.listen(_handleForeground);
      FirebaseMessaging.onMessageOpenedApp.listen(_handleOpened);

      _initialized = true;
    } catch (e) {
      debugPrint('NotificationService init error: $e');
    }
  }

  Future<void> _requestPermissions() async {
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  Future<void> _initLocal() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    await _localNotifications.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );
  }

  Future<void> _onTokenRefresh(String token) async {
    _fcmToken = token;
    await _saveTokenToFirestore(token);
  }

  Future<void> _handleForeground(RemoteMessage message) async {
    await _showLocal(message);
  }

  void _handleOpened(RemoteMessage message) {
    // Navigation handled by app layer
    debugPrint('Notification opened app: ${message.data}');
  }

  Future<void> _showLocal(RemoteMessage message) async {
    const androidDetails = AndroidNotificationDetails(
      'church_hub_channel',
      'Church Hub',
      channelDescription: 'Notificações do Church Hub',
      importance: Importance.high,
      priority: Priority.high,
    );
    const details = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(presentAlert: true, presentBadge: true, presentSound: true),
    );
    await _localNotifications.show(
      message.hashCode,
      message.notification?.title ?? 'Notificação',
      message.notification?.body ?? '',
      details,
    );
  }

  Future<void> _saveTokenToFirestore(String token) async {
    try {
      final user = FirebaseConfig.auth.currentUser;
      if (user != null) {
        await FirebaseConfig.firestore
            .collection('users')
            .doc(user.uid)
            .update({'fcmToken': token});
      }
    } catch (_) {}
  }

  Future<bool> areEnabled() async {
    final settings = await _messaging.getNotificationSettings();
    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  }
}
