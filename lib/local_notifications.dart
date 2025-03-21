import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class LocalNotifications {

  final FlutterLocalNotificationsPlugin notificationsPlugin = FlutterLocalNotificationsPlugin();

  Future<void> initNotifications() async {
    var initalizationSettingIOS = DarwinInitializationSettings (
    requestAlertPermission: true,
    requestBadgePermission: true,
    requestSoundPermission: true,
    onDidRecieveLocalNotification: (int id, String? title, String? body, String? payload) async {});

    var initializationSettings = InitializationSettings(
    iOS: initalizationSettingIOS );

    await notificationsPlugin.initialize(initializationSettings, 
    onDidReceiveNotificationResponse:
    (NotificationResponse notificationResponse) async {});
  }

  notificationDetails(){
    return const NotificationDetails(
      iOS: DarwinNotificationDetails()
    );
  }

  Future <void> showNotification({
    int id = 0, String? title, String? body, String? payload
  }) async{
    return notificationsPlugin.show(id, title, body, await notificationDetails());
  }


}
