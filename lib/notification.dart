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
import 'child.dart';
import 'medication.dart';

// notification class: 

class medNotification {
  final String? brandName;
  final String genericName;
  String message;
  double? dosage;  
  Child? child; 
  bool isChecked;
  bool isRecurring; 
  bool notifsOn;
  // list representing days that medication is taken, 0 = sun, 1= mon, 2= tues, 3= wed, 4= thurs, 5= fri, 6=sat
  List<bool> daysUsed;
  Medication? medication;
  TimeOfDay? time; // time user gave

  medNotification({
    this.brandName,
    this.dosage = 0,
    required this.genericName,
    this.isChecked = false,
    this.isRecurring = false,
    this.notifsOn = false,
    required this.message,
    this.child,
    List<bool>? daysUsed,
    TimeOfDay? time,
    Medication? medication,
  }) : daysUsed = daysUsed ?? List.filled(7, false); 

}

// notification functions
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
  //print("made it here");
  final NotificationDetails details = NotificationDetails(iOS: iosDetails);
 // print("made it here 2");
  await flutterLocalNotificationsPlugin
    .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
    ?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );
  //print("made it here 3");
  await flutterLocalNotificationsPlugin.show(
    1,
    'NOTIFICATION',
    'yuhhhhhhhhh',
    details,
    payload: 'simple_payload',
  );
   print("made it here 4");
}

void rescheduleAllRecurringNotifications(List<Medication> meds) {
  for (var med in meds) {
    scheduleRecurringIOSNotification(med);
  }
}


// converts timeofday to an actual time in the users timezone
tz.TZDateTime _nextInstanceOfTime(TimeOfDay time) {
  final now = tz.TZDateTime.now(tz.local);
  tz.TZDateTime scheduledDate = tz.TZDateTime(
    tz.local,
    now.year,
    now.month,
    now.day,
    time.hour,
    time.minute,
  );

  // If the time has already passed today, schedule for tomorrow
  if (scheduledDate.isBefore(now)) {
    scheduledDate = scheduledDate.add(Duration(days: 1));
  }

  return scheduledDate;
}

Future<void> scheduleMedicationNotification(Medication medication) async {
  final notif = medication.notification;
  if (notif == null || notif.time == null || !medication.notifsOn) return;

  final scheduledDate = _nextInstanceOfTime(notif.time!);

  await flutterLocalNotificationsPlugin.zonedSchedule(
    medication.id.hashCode, // Unique ID for notification
    'Medication Reminder',
    '${medication.genericName} - ${medication.dosage ?? ''}mg', // TODO: change to notif message
    scheduledDate,
    const NotificationDetails(
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentSound: true,
        presentBadge: true,
      ),
    ),
    androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    matchDateTimeComponents: DateTimeComponents.time, // Recurring daily
  );
}

Future<void> scheduleRecurringIOSNotification(Medication medication) async {
  final notif = medication.notification;
  if (notif == null || notif.time == null || !medication.notifsOn || !medication.isRecurring) return;

  final now = DateTime.now();
  final time = notif.time!;
  final todayIndex = now.weekday % 7; // 0 = Sunday

  // Find the next day the med is taken
  int? nextDayOffset;
  for (int i = 0; i < 7; i++) {
    int checkDay = (todayIndex + i) % 7;
    if (medication.daysUsed[checkDay]) {
      nextDayOffset = i;
      break;
    }
  }

  if (nextDayOffset == null) return; // No valid days selected

  final scheduledDate = DateTime(
    now.year,
    now.month,
    now.day + nextDayOffset,
    time.hour,
    time.minute,
  );

  final delay = scheduledDate.difference(now);

  Timer(delay, () {
    flutterLocalNotificationsPlugin.show(
      medication.id.hashCode,
      'Medication Reminder',
      '${medication.genericName} - ${medication.dosage ?? ''}mg',
      const NotificationDetails(
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: 'medication_reminder',
    );
  });
}





