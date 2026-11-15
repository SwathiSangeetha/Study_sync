
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../models/task_model.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static const String _enabledKey = 'study_notifications_enabled';

  static bool _initialized = false;

  static const AndroidNotificationDetails _androidDetails =
      AndroidNotificationDetails(
    'studysync_reminders',
    'StudySync Reminders',
    channelDescription: 'Reminders for upcoming study sessions and incomplete tasks',
    importance: Importance.max,
    priority: Priority.high,
  );

  static const NotificationDetails _notificationDetails =
      NotificationDetails(android: _androidDetails);

  // Initialize notifications.
  static Future<void> initialize() async {
    if (kIsWeb || _initialized) return;

    tz_data.initializeTimeZones();

    // India timezone. Change this if your phone uses another timezone.
    tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings settings =
        InitializationSettings(android: androidSettings);

    await _notifications.initialize(
         settings: settings,
        );

    _initialized = true;
  }

  // Request Android notification permission.
  static Future<bool> requestPermission() async {
    if (kIsWeb) return false;

    await initialize();

    final android = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    final granted = await android?.requestNotificationsPermission();

    return granted ?? false;
  }

  // Read notification preference.
  static Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_enabledKey) ?? true;
  }

  // Enable or disable notifications.
  static Future<void> setEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, enabled);

    if (!enabled) {
      await cancelAll();
    }
  }

  // Generate a stable notification ID from a task ID.
  static int _notificationId(String taskId, int type) {
    var hash = 0;

    for (final character in taskId.codeUnits) {
      hash = (hash * 31 + character) & 0x3fffffff;
    }

    return hash * 2 + type;
  }

  // Convert DateTime to the timezone-aware date required by the package.
  static tz.TZDateTime _toTZDateTime(DateTime dateTime) {
    return tz.TZDateTime.from(dateTime, tz.local);
  }

  // Schedule reminders for all incomplete tasks.
  static Future<void> scheduleTaskNotifications(
    List<Task> tasks,
  ) async {
    if (kIsWeb) return;

    await initialize();

    // Remove old reminders before rebuilding the schedule.
    await _notifications.cancelAll();

    if (!await isEnabled()) return;

    final now = DateTime.now();

    for (final task in tasks) {
      if (task.isCompleted) continue;

      // Reminder 1: 15 minutes before the study session.
      final reminderTime =
          task.startTime.subtract(const Duration(minutes: 15));

      if (reminderTime.isAfter(now)) {
        await _notifications.zonedSchedule(
          id: _notificationId(task.id, 0),
          title: 'Study session coming up 📚',
          body: '${task.title} starts in 15 minutes. Get ready!',
          scheduledDate: _toTZDateTime(reminderTime),
          notificationDetails: _notificationDetails,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          payload: task.id,
        );
      }

      // Reminder 2: At the end of the session if still incomplete.
      if (task.endTime.isAfter(now)) {
        await _notifications.zonedSchedule(
          id: _notificationId(task.id, 1),
          title: 'Study session reminder',
          body: 'Have you completed ${task.title}? Update your progress!',
          scheduledDate: _toTZDateTime(task.endTime),
          notificationDetails: _notificationDetails,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          payload: task.id,
        );
      }
    }
  }

  // Cancel every scheduled StudySync notification.
  static Future<void> cancelAll() async {
    if (kIsWeb) return;

    await initialize();
    await _notifications.cancelAll();
  }
}
