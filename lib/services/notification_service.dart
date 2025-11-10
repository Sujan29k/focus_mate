import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import '../models/task_model.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  // Initialize the notification service
  static Future<void> initialize() async {
    if (_initialized) return;

    // Initialize timezone data
    tz.initializeTimeZones();

    // Android settings
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS settings
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      settings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle notification tap
        print('Notification tapped: ${response.payload}');
      },
    );

    _initialized = true;
  }

  // Request notification permissions
  static Future<bool> requestPermissions() async {
    if (!_initialized) await initialize();

    final AndroidFlutterLocalNotificationsPlugin? androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    final bool? granted = await androidPlugin?.requestNotificationsPermission();

    return granted ?? true; // Return true for iOS (handled in initialize)
  }

  // Schedule notifications for a task (15 min before + at due time)
  static Future<void> scheduleTaskNotification(TaskModel task) async {
    if (!_initialized) await initialize();

    if (task.dueDate == null || !task.hasTimeSet) return;

    // Create notification details
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'task_reminders', // Channel ID
          'Task Reminders', // Channel name
          channelDescription: 'Notifications for upcoming tasks',
          importance: Importance.high,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
        );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    try {
      // NOTIFICATION 1: 15 minutes before due time
      final reminderTime = task.dueDate!.subtract(const Duration(minutes: 15));

      if (reminderTime.isAfter(DateTime.now())) {
        await _notifications.zonedSchedule(
          task.id.hashCode, // Unique ID for 15-min reminder
          'Task Due Soon! ⏰',
          '${task.title} is due at ${task.timeFormatted}',
          tz.TZDateTime.from(reminderTime, tz.local),
          details,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          payload: task.id,
        );
        print('15-min reminder scheduled for ${task.title} at $reminderTime');
      }

      // NOTIFICATION 2: At exact due time
      if (task.dueDate!.isAfter(DateTime.now())) {
        await _notifications.zonedSchedule(
          task.id.hashCode + 1, // Different ID for due time notification
          'Task Time is Up! ⏱️',
          'Time to complete: ${task.title}',
          tz.TZDateTime.from(task.dueDate!, tz.local),
          details,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          payload: task.id,
        );
        print(
          'Due time notification scheduled for ${task.title} at ${task.dueDate}',
        );
      }
    } catch (e) {
      print('Error scheduling notification: $e');
    }
  }

  // Cancel both notifications for a task (15-min reminder + due time)
  static Future<void> cancelTaskNotification(String taskId) async {
    if (!_initialized) return;

    // Cancel 15-minute reminder
    await _notifications.cancel(taskId.hashCode);
    // Cancel due time notification
    await _notifications.cancel(taskId.hashCode + 1);
    print('Both notifications cancelled for task $taskId');
  }

  // Cancel all notifications
  static Future<void> cancelAllNotifications() async {
    if (!_initialized) await initialize();

    await _notifications.cancelAll();
    print('All notifications cancelled');
  }

  // Show immediate notification (for testing)
  static Future<void> showImmediateNotification(
    String title,
    String body,
  ) async {
    if (!_initialized) await initialize();

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'task_reminders',
          'Task Reminders',
          importance: Importance.high,
          priority: Priority.high,
        );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      details,
    );
  }

  // Get pending notifications (for debugging)
  static Future<List<PendingNotificationRequest>>
  getPendingNotifications() async {
    if (!_initialized) await initialize();

    return await _notifications.pendingNotificationRequests();
  }

  // Schedule multiple reminders for a task
  static Future<void> scheduleMultipleReminders(
    TaskModel task,
    List<Duration> reminderTimes,
  ) async {
    if (!_initialized) await initialize();

    if (task.dueDate == null || !task.hasTimeSet) return;

    for (var i = 0; i < reminderTimes.length; i++) {
      final notificationTime = task.dueDate!.subtract(reminderTimes[i]);

      if (notificationTime.isBefore(DateTime.now())) continue;

      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
            'task_reminders',
            'Task Reminders',
            channelDescription: 'Notifications for upcoming tasks',
            importance: Importance.high,
            priority: Priority.high,
            playSound: true,
          );

      const NotificationDetails details = NotificationDetails(
        android: androidDetails,
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      );

      final reminderText = _formatReminderTime(reminderTimes[i]);

      try {
        await _notifications.zonedSchedule(
          task.id.hashCode + i, // Unique ID per reminder
          'Task Reminder! ⏰',
          '${task.title} is due $reminderText',
          tz.TZDateTime.from(notificationTime, tz.local),
          details,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          payload: task.id,
        );
      } catch (e) {
        print('Error scheduling reminder $i: $e');
      }
    }
  }

  // Format reminder time for notification
  static String _formatReminderTime(Duration duration) {
    if (duration.inDays > 0) {
      return 'in ${duration.inDays} day${duration.inDays == 1 ? '' : 's'}';
    } else if (duration.inHours > 0) {
      return 'in ${duration.inHours} hour${duration.inHours == 1 ? '' : 's'}';
    } else if (duration.inMinutes > 0) {
      return 'in ${duration.inMinutes} minute${duration.inMinutes == 1 ? '' : 's'}';
    }
    return 'now';
  }
}
