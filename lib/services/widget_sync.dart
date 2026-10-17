import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import '../models/stamp.dart';
import '../repositories/daily_record_repository.dart';
import '../utils/date_only.dart';
import '../utils/day_key.dart';
import 'morning_schedule.dart';
import '../models/question.dart';
import 'question_bank.dart';

/// ウィジェットで押したスタンプ1件
class PendingStamp {
  const PendingStamp({required this.date, required this.stampId, required this.at});

  final DateTime date;

  /// null は取り消し
  final String? stampId;
  final DateTime at;
}

/// ウィジェットに渡すデータの日数(通知と同じ。しばらく開かなくても空にならない)
const widgetDays = morningDays;

/// ウィジェットに渡す日ごとのデータ。答えの文など個人的な内容は入れない
List<Map<String, Object?>> buildWidgetPayload({
  required DateTime today,
  required DateTime birthDate,
  required QuestionBank bank,
  int days = widgetDays,
}) {
  final start = dateOnly(today);
  return [
    for (var i = 0; i < days; i++)
      () {
        final d = DateTime(start.year, start.month, start.day + i);
        return <String, Object?>{
          'd': ymd(d),
          'n': lifeDaysOn(birthDate, d),
          'q': questionWithFollowUp(bank.forDate(d)),
        };
      }(),
  ];
}

/// ウィジェットで押したスタンプを、何日前の分まで取り込むか
/// (アプリをしばらく開かなくても、押した気分が消えないように)
const maxPendingStampDays = 7;

/// ウィジェットから受け取った JSON を安全に読む。壊れたものは捨てる
List<PendingStamp> parsePendingStamps(String? raw, DateTime now) {
  if (raw == null || raw.isEmpty) return const [];
  Object? decoded;
  try {
    decoded = jsonDecode(raw);
  } catch (_) {
    return const [];
  }
  if (decoded is! List) return const [];
  final today = dateOnly(now);
  final result = <PendingStamp>[];
  // 押した数には上限を置く(壊れたデータで延々と回らないように)
  for (final e in decoded.take(200)) {
    if (e is! Map) continue;
    final d = e['d'], s = e['s'], t = e['t'];
    if (d is! String || t is! num) continue;
    final date = DateTime.tryParse(d);
    if (date == null || ymd(date) != d) continue;
    // 今日から [maxPendingStampDays] 日前までを受け取る。未来の日は捨てる
    // (日数は年月日で数える。夏時間の切り替えで 23 時間・25 時間の日があってもずれない)
    final diff = DateTime.utc(today.year, today.month, today.day)
        .difference(DateTime.utc(date.year, date.month, date.day))
        .inDays;
    if (diff < 0 || diff > maxPendingStampDays) continue;
    final String? stampId;
    if (s == null || s == '') {
      stampId = null;
    } else if (s is String && stampById(s) != null) {
      stampId = s;
    } else {
      continue;
    }
    // 押した時刻は「その日の前日の 0:00 〜 今の1時間後」だけ受け取る
    // (極端な値で落ちたり、未来の値で後勝ちを奪ったりしないように。前日の分は地域の違いの余裕)
    final ms = t * 1000;
    if (!ms.isFinite) continue;
    final earliest = DateTime(date.year, date.month, date.day - 1)
        .millisecondsSinceEpoch;
    final latest = now.add(const Duration(hours: 1)).millisecondsSinceEpoch;
    if (ms < earliest || ms > latest) continue;
    final at = DateTime.fromMillisecondsSinceEpoch(ms.round());
    result.add(PendingStamp(date: dateOnly(date), stampId: stampId, at: at));
  }
  return result;
}

/// 取り込んだ束 [imported] に入っていた分を、今の束 [latest] から除いた JSON
String remainingAfterImport(String imported, String? latest) {
  if (latest == null || latest == imported) return '[]';
  try {
    final done = jsonDecode(imported);
    final now = jsonDecode(latest);
    if (done is! List || now is! List) return '[]';
    // Swift はキーの並びを決めずに書くので、値を決まった順でつないで見分ける
    String key(Object? e) => e is Map ? '${e['d']}|${e['s']}|${e['t']}' : '$e';
    final doneKeys = done.map(key).toSet();
    return jsonEncode([
      for (final e in now)
        if (!doneKeys.contains(key(e))) e,
    ]);
  } catch (_) {
    return '[]';
  }
}

/// ウィジェットで押したものを採るか。アプリで後から押し直していれば採らない
bool widgetStampWins(DateTime? appStampAt, DateTime widgetAt) =>
    appStampAt == null || widgetAt.isAfter(appStampAt);

/// 「yyyy-MM-dd」。記録の dayKey と同じ書き方
String ymd(DateTime d) => dayKeyOf(d);

/// ホーム画面のウィジェットと、App Group 経由でやりとりする
class WidgetSync {
  WidgetSync._();

  static const appGroup = 'group.com.lifecounter.lifeCounter';
  static const _kinds = ['LifeDaysWidget', 'TodayQuestionWidget'];
  static bool _ready = false;

  static Future<void> _ensureReady() async {
    if (_ready) return;
    await HomeWidget.setAppGroupId(appGroup);
    _ready = true;
  }

  /// ウィジェットで押されたスタンプを記録に取り込む。取り込んだ件数を返す
  static Future<int> importPending(
      DailyRecordRepository repo, QuestionBank bank) async {
    try {
      await _ensureReady();
      final raw = await HomeWidget.getWidgetData<String>('pendingStamps');
      if (raw == null || raw == '[]') return 0;
      var count = 0;
      // 取り込みは何度やっても結果が同じ(後勝ち)なので、取り込んでから消す
      for (final p in parsePendingStamps(raw, DateTime.now())) {
        try {
          // 比べるのと書くのは同じ書き込みの中で(アプリで後から押し直したほうを残す)
          final applied = await repo.setStamp(p.date, p.stampId,
              questionId: bank.forDate(p.date).id,
              at: p.at,
              onlyIf: (current) => widgetStampWins(current?.stampAt, p.at));
          if (applied) count++;
        } catch (e) {
          debugPrint('Widget stamp import error: $e');
        }
      }
      // 読んだあとにウィジェットで押された分は残す
      final latest = await HomeWidget.getWidgetData<String>('pendingStamps');
      await HomeWidget.saveWidgetData<String>(
          'pendingStamps', remainingAfterImport(raw, latest));
      return count;
    } catch (e) {
      debugPrint('Widget import error: $e');
      return 0;
    }
  }

  /// ウィジェットの表示を更新する
  static Future<void> update({
    required DateTime? birthDate,
    required QuestionBank bank,
    required String? todayStampId,
  }) async {
    try {
      await _ensureReady();
      final now = DateTime.now();
      final days = birthDate == null
          ? const <Map<String, Object?>>[]
          : buildWidgetPayload(today: now, birthDate: birthDate, bank: bank);
      await HomeWidget.saveWidgetData<String>('days', jsonEncode(days));
      await HomeWidget.saveWidgetData<String>(
          'todayStamp', jsonEncode({'d': ymd(now), 's': todayStampId ?? ''}));
      for (final kind in _kinds) {
        await HomeWidget.updateWidget(iOSName: kind);
      }
    } catch (e) {
      debugPrint('Widget update error: $e');
    }
  }
}
