import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../models/user_settings.dart';

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
        badge: true,
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

  static const _weekIds = [100, 101, 102, 103, 104, 105, 106];
  static List<String>? _questions;

  static Future<List<String>> _loadQuestions() async {
    if (_questions != null) return _questions!;
    try {
      final json =
          await rootBundle.loadString('assets/data/coaching_questions.json');
      _questions = (jsonDecode(json) as List)
          .map((q) => q['text'] as String)
          .toList();
    } catch (e) {
      debugPrint('Notification questions load error: $e');
      _questions = const ['今日、感謝できることは何ですか?'];
    }
    return _questions!;
  }

  /// 設定に合わせて、これから7日分の朝の通知を入れ直す
  /// （1件を毎日くり返す形だと、日数と問いかけが登録した日のまま止まるため）
  static Future<void> refresh(UserSettings settings) async {
    try {
      await cancelMorningNotification();
      final birthDate = settings.birthDate;
      if (!settings.notificationEnabled ||
          !settings.onboardingCompleted ||
          birthDate == null) {
        return;
      }
      final questions = await _loadQuestions();
      final fmt = NumberFormat('#,###', 'ja_JP');
      final first =
          _nextInstanceOfTime(settings.notificationHour, settings.notificationMinute);
      for (var i = 0; i < _weekIds.length; i++) {
        final when = first.add(Duration(days: i));
        final day = DateTime(when.year, when.month, when.day);
        final lifeDays = day.difference(DateTime(
                    birthDate.year, birthDate.month, birthDate.day))
                .inDays +
            1;
        final dayOfYear = day.difference(DateTime(day.year)).inDays;
        await _plugin.zonedSchedule(
          _weekIds[i],
          '人生 ${fmt.format(lifeDays)}日目',
          questions[dayOfYear % questions.length],
          when,
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
              UILocalNotificationDateInterpretation.wallClockTime,
        );
      }
    } catch (e) {
      debugPrint('Notification refresh error: $e');
    }
  }

  static Future<void> cancelMorningNotification() async {
    // 0 は v1.0 の毎日くり返す通知
    await _plugin.cancel(0);
    for (final id in _weekIds) {
      await _plugin.cancel(id);
    }
  }

  /// 次の指定時刻のTZDateTimeを返す
  static tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }
}
