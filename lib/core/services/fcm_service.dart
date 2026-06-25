import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class LocalNotificationPayload {
  final String title;
  final String body;

  LocalNotificationPayload({required this.title, required this.body});
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (kDebugMode) {
    print("Handling a background message: ${message.messageId}");
  }
}

class FCMService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  
  final _notificationTapController = StreamController<String>.broadcast();
  Stream<String> get onNotificationTap => _notificationTapController.stream;

  final _foregroundMessageController = StreamController<RemoteMessage>.broadcast();
  Stream<RemoteMessage> get onForegroundMessage => _foregroundMessageController.stream;

  final _localNotificationController = StreamController<LocalNotificationPayload>.broadcast();
  Stream<LocalNotificationPayload> get onLocalNotification => _localNotificationController.stream;

  Future<void> init() async {
    // 1. Request permission
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (kDebugMode) {
      print('User granted permission: ${settings.authorizationStatus}');
    }

    // Register background handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 2. Configure listeners
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (kDebugMode) {
        print('Got a message whilst in the foreground!');
        print('Message data: ${message.data}');
      }
      _foregroundMessageController.add(message);
      
      // Also show local system notification in the foreground
      final notification = message.notification;
      if (notification != null) {
        showSystemNotification(
          title: notification.title ?? '',
          body: notification.body ?? '',
          taskId: message.data['taskId'] as String?,
        );
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      if (kDebugMode) {
        print('A new onMessageOpenedApp event was published!');
      }
      _handleMessageTap(message);
    });

    // Check if app was opened from terminated state via notification
    RemoteMessage? initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      _handleMessageTap(initialMessage);
    }

    // 3. Initialize Local Notifications for native platforms
    if (!kIsWeb) {
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const InitializationSettings initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
      );

      await _localNotifications.initialize(
        settings: initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          final payload = response.payload;
          if (payload != null && payload.isNotEmpty) {
            _notificationTapController.add(payload);
          }
        },
      );

      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'field_service_channel',
        'Field Service Notifications',
        description: 'Channel for Field Service updates',
        importance: Importance.max,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }
  }

  Future<String?> getToken() async {
    try {
      return await _fcm.getToken();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting FCM token: $e');
      }
      return null;
    }
  }

  Future<void> showSystemNotification({
    required String title,
    required String body,
    String? taskId,
  }) async {
    if (kIsWeb) {
      triggerLocalNotification(title, body);
    } else {
      try {
        const AndroidNotificationDetails androidPlatformChannelSpecifics =
            AndroidNotificationDetails(
          'field_service_channel',
          'Field Service Notifications',
          channelDescription: 'Channel for Field Service updates',
          importance: Importance.max,
          priority: Priority.high,
          ticker: 'ticker',
        );
        const NotificationDetails platformChannelSpecifics = NotificationDetails(
          android: androidPlatformChannelSpecifics,
        );

        await _localNotifications.show(
          id: DateTime.now().hashCode,
          title: title,
          body: body,
          notificationDetails: platformChannelSpecifics,
          payload: taskId,
        );
      } catch (e) {
        if (kDebugMode) {
          print('Error showing system notification: $e');
        }
      }
    }
  }

  void triggerLocalNotification(String title, String body) {
    _localNotificationController.add(LocalNotificationPayload(title: title, body: body));
  }

  void _handleMessageTap(RemoteMessage message) {
    final taskId = message.data['taskId'] as String?;
    if (taskId != null) {
      _notificationTapController.add(taskId);
    }
  }

  void dispose() {
    _notificationTapController.close();
    _foregroundMessageController.close();
    _localNotificationController.close();
  }
}
