import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
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

  /// 朝の通知を、日付ごとに先の60日分入れ直す
  /// (1件を毎日くり返す形だと、日数と問いが予約した日のまま止まるため)
  static Future<void> refresh(UserSettings settings, QuestionBank bank) async {
    try {
      await cancelMorningNotification();
      final birthDate = settings.birthDate;
      if (!settings.notificationEnabled ||
          !settings.onboardingCompleted ||
          birthDate == null) {
        return;
      }
      final items = buildMorningSchedule(
        now: DateTime.now(),
        birthDate: birthDate,
        hour: settings.notificationHour,
        minute: settings.notificationMinute,
        bank: bank,
      );
      for (final m in items) {
        await _plugin.zonedSchedule(
          m.id,
          m.title,
          m.body,
          // 端末の時刻の日時を、そのままの瞬間として渡す(tz.local に頼らない)
          tz.TZDateTime.from(m.when, tz.UTC),
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
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
      }
    } catch (e) {
      debugPrint('Notification refresh error: $e');
    }
  }

  static Future<void> cancelMorningNotification() async {
    // 0 は v1.0 系の毎日くり返す通知
    await _plugin.cancel(0);
    for (var i = 0; i < morningDays; i++) {
      await _plugin.cancel(morningIdBase + i);
    }
  }
}
