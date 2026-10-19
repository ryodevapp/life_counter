import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/daily_record.dart';

/// App Store のレビューのお願い(iOS 標準の小窓)。押し付けないよう、
/// 答えを書いた日が [answeredDaysToAsk] 日になったときに1回だけ出す。
/// 実際に出すかどうかと回数(年3回まで)は iOS が決める
class ReviewPrompt {
  ReviewPrompt._();

  static const answeredDaysToAsk = 7;
  static const _askedKey = 'review_asked';
  // 1.1.1 までの覚え方(2日目・7日目にお願いした印)。残っていれば、もうお願いした人として出さない
  static const _legacyAskedKeys = ['review_requested_day2', 'review_requested_day7'];
  static const _channel = MethodChannel('lifecounter/review');

  /// もうお願いしたか(1.1.1 までの印も見る)
  static bool alreadyAsked(SharedPreferences prefs) =>
      (prefs.getBool(_askedKey) ?? false) ||
      _legacyAskedKeys.any(prefs.containsKey);

  /// 出すかどうか(テストできるように、決め方だけを切り出す)
  static bool shouldAsk({required int answeredDays, required bool alreadyAsked}) =>
      !alreadyAsked && answeredDays >= answeredDaysToAsk;

  /// 答えを書いた日の数(空の答えは数えない)
  static int answeredDays(List<DailyRecord> records) => records
      .where((r) => (r.answer ?? '').trim().isNotEmpty)
      .length;

  static Future<void> maybeAsk(
      List<DailyRecord> records, SharedPreferences prefs) async {
    if (!shouldAsk(
        answeredDays: answeredDays(records),
        alreadyAsked: alreadyAsked(prefs))) {
      return;
    }
    await prefs.setBool(_askedKey, true);
    try {
      await _channel.invokeMethod('request');
    } catch (e) {
      debugPrint('Review prompt error: $e');
    }
  }
}
