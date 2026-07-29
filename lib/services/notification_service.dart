import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import '../models/app_models.dart';

class NotificationService {
  static final NotificationService instance = NotificationService._();
  NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;

  static const String localTimezone = 'Asia/Dhaka';

  static const List<Duration> _offsets = [
    Duration(days: 1),
    Duration(hours: 12),
    Duration(hours: 6),
    Duration(hours: 1),
  ];

  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      'task_reminders',
      'Task Reminders',
      channelDescription: 'Reminders before assignment / task deadlines',
      importance: Importance.high,
      priority: Priority.high,
    ),
    iOS: DarwinNotificationDetails(),
  );

  Future<void> init() async {
    if (_ready) return;
    tzdata.initializeTimeZones();
    try {
      tz.setLocalLocation(tz.getLocation(localTimezone));
    } catch (_) {

    }
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    await _plugin.initialize(const InitializationSettings(android: android, iOS: ios));
    await _requestPermissions();
    _ready = true;
  }

  Future<void> _requestPermissions() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await android?.requestNotificationsPermission();

    final ios = _plugin
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    await ios?.requestPermissions(alert: true, badge: true, sound: true);
  }

  /// Cancels all reminders and reschedules them from [assignments].
  /// Call this whenever the task list changes.
  Future<void> syncAll(List<Assignment> assignments) async {
    if (!_ready) {
      try {
        await init();
      } catch (_) {
        return;
      }
    }
    await _plugin.cancelAll();

    final now = DateTime.now();
    var id = 1000;
    for (final a in assignments) {
      if (a.status == 'done') continue;
      for (final off in _offsets) {
        final when = a.dueDate.subtract(off);
        if (when.isAfter(now)) {
          await _schedule(id++, a, when, off);
          if (id > 9000) return;
        }
      }
    }
  }

  Future<void> _schedule(int id, Assignment a, DateTime when, Duration before) async {
    try {
      await _plugin.zonedSchedule(
        id,
        '⏰ ${a.title}',
        'Due ${_label(before)} · ${_fmt(a.dueDate)}',
        tz.TZDateTime.from(when, tz.local),
        _details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (_) {

    }
  }

  String _label(Duration d) {
    if (d.inDays >= 1) return 'in 1 day';
    if (d.inHours == 12) return 'in 12 hours';
    if (d.inHours == 6) return 'in 6 hours';
    return 'in 1 hour';
  }

  String _fmt(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final ap = d.hour < 12 ? 'AM' : 'PM';
    final m = d.minute.toString().padLeft(2, '0');
    return '${months[d.month - 1]} ${d.day}, $h:$m $ap';
  }
}