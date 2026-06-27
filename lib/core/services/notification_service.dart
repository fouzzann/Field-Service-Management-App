import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// This service is responsible for showing system push notifications on the user's phone.
class NotificationService {
  // Create an instance of the flutter_local_notifications plugin.
  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  // Initializes notification settings for Android and iOS when the app starts.
  Future<void> init() async {
    // 1. Android Specific Settings: Uses the default launcher icon of the app.
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // 2. iOS Specific Settings: Requests permissions for alerts, badges, and sounds.
    const DarwinInitializationSettings initializationSettingsIOS = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    // 3. Combine both platforms' settings.
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    // 4. Initialize the plugin.
    await _notificationsPlugin.initialize(
      settings: initializationSettings,
    );
  }

  // Shows a banner notification immediately.
  Future<void> showNotification({
    required int id, // Unique number/id for this specific notification.
    required String title, // Header text of the notification banner.
    required String body, // Main text body under the title.
    String? payload, // Hidden data that can be read if the user clicks the notification.
  }) async {
    // Android specific detail configurations (importance, channel, sound priority).
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'field_service_tasks_channel', // Channel ID.
      'Task Notifications', // Channel Name.
      channelDescription: 'Notifications for field service management tasks',
      importance: Importance.max,
      priority: Priority.high,
    );

    // iOS specific detail configurations.
    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails();

    // Group details together.
    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Trigger the notification popup.
    await _notificationsPlugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: notificationDetails,
      payload: payload,
    );
  }
}
