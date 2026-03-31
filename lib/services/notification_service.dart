// lib/services/notification_service.dart
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

class NotificationService {
  // FIX: 'static const' removed — FlutterLocalNotificationsPlugin() is NOT a
  // const constructor. Using 'static final' instead.
  static final _plugin = FlutterLocalNotificationsPlugin();

  static const _morningId    = 1;
  static const _nightId      = 2;
  static const _dangerZoneId = 3;
  static const _channelId    = 'guardian_reminders';

  Future<void> init() async {
    tz_data.initializeTimeZones();

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);

    await _plugin.initialize(settings);
    await _createChannel();
  }

  Future<void> _createChannel() async {
    const channel = AndroidNotificationChannel(
      _channelId,
      'Guardian Reminders',
      description: 'Daily streak reminders and danger zone alerts',
      importance: Importance.defaultImportance,
    );
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  Future<void> scheduleMorningReminder(int currentStreak) async {
    await _plugin.zonedSchedule(
      _morningId,
      'Good morning — Day $currentStreak 🔥',
      'You made it through the night. Keep going.',
      _nextInstance(8, 0),
      _details(),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> scheduleNightReminder(int currentStreak) async {
    await _plugin.zonedSchedule(
      _nightId,
      'Almost midnight — stay strong',
      'Day $currentStreak is almost complete. Phone down.',
      _nextInstance(22, 0),
      _details(),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> scheduleDangerZoneAlert(int day) async {
    if (day < 14 || day > 21) return;
    await _plugin.show(
      _dangerZoneId,
      'Danger Zone: Day $day',
      'Days 14–21 are the hardest. Guardian has your back — stay the course.',
      _details(),
    );
  }

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  NotificationDetails _details() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        'Guardian Reminders',
        channelDescription: 'Daily streak reminders',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        icon: '@mipmap/ic_launcher',
      ),
    );
  }

  tz.TZDateTime _nextInstance(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
        tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }
}
