import 'dart:async';
import 'dart:convert';
import 'dart:io';
// ignore: unnecessary_import
import 'dart:typed_data';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as image;
import 'package:path_provider/path_provider.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;


final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> _configureLocalTimeZone() async {
  if (kIsWeb || Platform.isLinux) {
    return;
  }
  tz.initializeTimeZones();
  if (Platform.isWindows) {
    return;
  }
  final String? timeZoneName = await FlutterTimezone.getLocalTimezone();
  tz.setLocalLocation(tz.getLocation(timeZoneName!));
}


Future<void> initializeNotifications(Function(NotificationResponse) onSelectNotification) async {
  
  await _configureLocalTimeZone();

  final DarwinInitializationSettings initializationSettingsDarwin =
      DarwinInitializationSettings( );

  final InitializationSettings initializationSettings = InitializationSettings(

    iOS:  initializationSettingsDarwin,
    macOS:  initializationSettingsDarwin,

  );

  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: onSelectNotification,
  );

}

Future<void> showSimpleNotification() async {
  const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
    presentAlert: true,
    presentBadge: true,
    presentSound: true,
  );
  final NotificationDetails details = NotificationDetails(iOS: iosDetails);
  await flutterLocalNotificationsPlugin
    .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
    ?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );
  await flutterLocalNotificationsPlugin.show(
    1,
    'Reminder',
    'New medicine to take look at check list',
    details,
    payload: 'simple_payload',
  );
}
