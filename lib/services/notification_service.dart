import 'package:flutter_local_notifications/flutter_local_notifications.dart'
    as fln;
import 'package:flutter/material.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'package:flutter_timezone/flutter_timezone.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final fln.FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      fln.FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz.initializeTimeZones();
    final timeZoneName = await FlutterTimezone.getLocalTimezone();
    String timeZoneId = timeZoneName.toString();
    // Handle the case where the return value is a TimezoneInfo object string
    if (timeZoneId.startsWith('TimezoneInfo')) {
      final match = RegExp(r'TimezoneInfo\(([^,]+),').firstMatch(timeZoneId);
      if (match != null) {
        timeZoneId = match.group(1) ?? timeZoneId;
      }
    }
    tz.setLocalLocation(tz.getLocation(timeZoneId));

    const fln.AndroidInitializationSettings initializationSettingsAndroid =
        fln.AndroidInitializationSettings('@mipmap/ic_launcher');

    const fln.DarwinInitializationSettings initializationSettingsDarwin =
        fln.DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const fln.InitializationSettings initializationSettings =
        fln.InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsDarwin,
          macOS: initializationSettingsDarwin,
        );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (fln.NotificationResponse response) {
        // Handle notification tap
      },
    );
  }

  Future<bool> requestPermissions() async {
    final fln.AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
              fln.AndroidFlutterLocalNotificationsPlugin
            >();

    final bool? androidGranted = await androidImplementation
        ?.requestNotificationsPermission();

    await androidImplementation?.requestExactAlarmsPermission();

    final fln.IOSFlutterLocalNotificationsPlugin? iosImplementation =
        flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
              fln.IOSFlutterLocalNotificationsPlugin
            >();

    final bool? iosGranted = await iosImplementation?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );

    final fln.MacOSFlutterLocalNotificationsPlugin? macosImplementation =
        flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
              fln.MacOSFlutterLocalNotificationsPlugin
            >();

    final bool? macosGranted = await macosImplementation?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );

    return androidGranted ?? iosGranted ?? macosGranted ?? false;
  }

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const fln.AndroidNotificationDetails androidNotificationDetails =
        fln.AndroidNotificationDetails(
          'timer_channel',
          'Timer Notifications',
          channelDescription: 'Notifications for timer and break updates',
          importance: fln.Importance.max,
          priority: fln.Priority.high,
        );

    const fln.NotificationDetails notificationDetails = fln.NotificationDetails(
      android: androidNotificationDetails,
      iOS: fln.DarwinNotificationDetails(),
      macOS: fln.DarwinNotificationDetails(),
    );

    await flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }

  Future<void> scheduleDailyNotification({
    required int id,
    required String title,
    required String body,
    required TimeOfDay time,
    String? payload,
  }) async {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    print('Scheduling notification for: $scheduledDate (Local: ${tz.local})');

    await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      const fln.NotificationDetails(
        android: fln.AndroidNotificationDetails(
          'daily_reminder_channel',
          'Daily Reminders',
          channelDescription: 'Daily scheduled reminders',
          importance: fln.Importance.max,
          priority: fln.Priority.high,
        ),
        iOS: fln.DarwinNotificationDetails(),
        macOS: fln.DarwinNotificationDetails(),
      ),
      androidScheduleMode: fln.AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: fln.DateTimeComponents.time,
      payload: payload,
    );
  }

  Future<void> cancelNotification(int id) async {
    await flutterLocalNotificationsPlugin.cancel(id);
  }

  Future<void> cancelAllNotifications() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }
}
