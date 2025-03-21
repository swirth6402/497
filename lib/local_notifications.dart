import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class LocalNotifications {

  final FlutterLocalNotificationsPlugin notificationsPlugin = FlutterLocalNotificationsPlugin();

  Future<void> initNotifications() async {
    // Set up the initialization settings for iOS
    var initializationSettingsIOS = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    // General initialization settings for the platform
    var initializationSettings = InitializationSettings(
      iOS: initializationSettingsIOS,
    );

    // Initialize the plugin
    await notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse notificationResponse) async {
        // Handle notification response (tap or action)
        // You can use the payload or take action based on notificationResponse
      },
    );
  }

  // Define notification details, including iOS-specific settings
  notificationDetails() {
    return const NotificationDetails(
      iOS: DarwinNotificationDetails(),
    );
  }

  // Show a notification with specified parameters
  Future showNotification({
    int id = 0, String? title, String? body, String? payload,
  }) async {
    // Show notification with provided details
    return notificationsPlugin.show(id, title, body, await notificationDetails());
  }
}
