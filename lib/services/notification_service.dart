import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../models/user_settings.dart';
import 'morning_schedule.dart';
import 'question_bank.dart';

/// ローカル通知サービス
class NotificationService {
  NotificationService._();

  static final _plugin = FlutterLocalNotificationsPlugin();
  static const _morningChannelId = 'morning_notification';
  static const _morningChannelName = '朝の通知';
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;
    try {
      tz.initializeTimeZones();
      // 端末のタイムゾーンを使う(設定しないと UTC 扱いになり、朝7時が日本の16時になる)
      try {
        final local = await FlutterTimezone.getLocalTimezone();
        tz.setLocalLocation(tz.getLocation(local.identifier));
      } catch (e) {
        debugPrint('Timezone error: $e');
      }
      const android = AndroidInitializationSettings('@mipmap/ic_launcher');
      const darwin = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );
      await _plugin.initialize(
        const InitializationSettings(
          android: android,
          iOS: darwin,
          macOS: darwin,
        ),
      );
      _initialized = true;
    } catch (e) {
      debugPrint('NotificationService init error: $e');
    }
  }

  /// 通知許可をリクエスト
  static Future<bool> requestPermission() async {
    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      final granted = await ios.requestPermissions(
        alert: true,
        badge: false,
        sound: true,
      );
      return granted ?? false;
    }
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      final granted = await android.requestNotificationsPermission();
      return granted ?? false;
    }
    return false;
  }

  static Future<void> _queue = Future.value();
  static int _generation = 0;

  /// 最後に予約した中身(同じなら入れ直さない)
  static String? _scheduledSignature;

  /// 朝の通知を、日付ごとに先の60日分入れ直す
  /// (1件を毎日くり返す形だと、日数と問いが予約した日のまま止まるため)
  /// 呼ばれた順に1本ずつ走らせ、後から呼ばれたら古いほうは途中でやめる
  static Future<void> refresh(UserSettings settings, QuestionBank bank) {
    final generation = ++_generation;
    _queue = _queue
        .then((_) => _refresh(settings, bank, generation))
        .catchError((Object e) => debugPrint('Notification refresh error: $e'));
    return _queue;
  }

  static Future<void> _refresh(
      UserSettings settings, QuestionBank bank, int generation) async {
    bool stale() => generation != _generation;
    final birthDate = settings.birthDate;
    final enabled = settings.notificationEnabled &&
        settings.onboardingCompleted &&
        birthDate != null;
    final items = enabled
        ? buildMorningSchedule(
            now: DateTime.now(),
            birthDate: birthDate,
            hour: settings.notificationHour,
            minute: settings.notificationMinute,
            bank: bank,
          )
        : const <MorningItem>[];
    final signature =
        items.map((m) => '${m.id}|${m.when}|${m.title}|${m.body}').join('\n');
    if (signature == _scheduledSignature) return;

    await cancelMorningNotification();
    _scheduledSignature = null;
    for (final m in items) {
      if (stale()) return;
      await _plugin.zonedSchedule(
        m.id,
        m.title,
        m.body,
        tz.TZDateTime(tz.local, m.when.year, m.when.month, m.when.day,
            m.when.hour, m.when.minute),
        const NotificationDetails(
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: false,
            presentSound: true,
          ),
          android: AndroidNotificationDetails(
            _morningChannelId,
            _morningChannelName,
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        // 端末の時刻の「朝7時」として予約する(旅行先でも現地の朝に届く)
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.wallClockTime,
      );
    }
    if (!stale()) _scheduledSignature = signature;
  }

  static Future<void> cancelMorningNotification() async {
    // 0 は v1.0 系の毎日くり返す通知
    await _plugin.cancel(0);
    for (var i = 0; i < morningDays; i++) {
      await _plugin.cancel(morningIdBase + i);
    }
  }
}
