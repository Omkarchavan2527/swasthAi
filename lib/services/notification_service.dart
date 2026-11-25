import 'dart:ui';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    try {
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const InitializationSettings initializationSettings =
          InitializationSettings(android: initializationSettingsAndroid);

      await flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
      );

      // Request notification permissions for Android 13+
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();

      _initialized = true;
    } catch (_) {
      // Safe fallback if notifications are disabled or unavailable
    }
  }

  Future<void> showMedicineReminder({
    required int id,
    required String medicineName,
    required String scheduledTime,
    required String dosage,
    int minutesBefore = 15,
  }) async {
    try {
      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        'medicine_reminders',
        'Medicine Reminders',
        channelDescription:
            'Advance reminder notifications for scheduled medicines',
        importance: Importance.max,
        priority: Priority.high,
        showWhen: true,
      );
      const NotificationDetails platformChannelSpecifics =
          NotificationDetails(android: androidPlatformChannelSpecifics);

      await flutterLocalNotificationsPlugin.show(
        id,
        '⏰ Medicine Reminder: $medicineName',
        'Upcoming dose ($dosage) scheduled at $scheduledTime (in $minutesBefore mins). Please take on time.',
        platformChannelSpecifics,
      );
    } catch (_) {}
  }

  Future<void> showCaretakerEscalation({
    required int id,
    required String patientName,
    required String medicineName,
    required String scheduledTime,
  }) async {
    try {
      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        'caretaker_alerts',
        'Caretaker Escalation Alerts',
        channelDescription:
            'Alerts sent to caretakers when medicine doses are missed',
        importance: Importance.max,
        priority: Priority.high,
        color: Color(0xFFEF4444),
      );
      const NotificationDetails platformChannelSpecifics =
          NotificationDetails(android: androidPlatformChannelSpecifics);

      await flutterLocalNotificationsPlugin.show(
        id,
        '🚨 Caretaker Alert: Missed Medicine',
        '$patientName has not confirmed taking $medicineName scheduled for $scheduledTime!',
        platformChannelSpecifics,
      );
    } catch (_) {}
  }
}
