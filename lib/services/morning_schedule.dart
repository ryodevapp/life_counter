import '../l10n/l10n.dart';
import '../utils/date_only.dart';
import 'question_bank.dart';

/// 朝の通知1件分
class MorningItem {
  const MorningItem({
    required this.id,
    required this.when,
    required this.title,
    required this.body,
  });

  final int id;

  /// 端末の時刻での予約日時
  final DateTime when;
  final String title;
  final String body;
}

/// 朝の通知の id の範囲(100〜159)。v1.0 系の毎日くり返す通知は id 0
const morningIdBase = 100;
const morningDays = 60;

/// 生まれた日を1日目として、その日が人生の何日目か
int lifeDaysOn(DateTime birthDate, DateTime date) {
  final b = dateOnly(birthDate);
  final d = dateOnly(date);
  // 夏時間で1日が23時間になる地域でもずれないよう、UTC の日付で数える
  final diff = DateTime.utc(d.year, d.month, d.day)
      .difference(DateTime.utc(b.year, b.month, b.day))
      .inDays;
  return diff + 1;
}

/// これから [days] 日分の朝の通知。今日の時刻を過ぎていれば明日から
/// 題は [languageCode] の言語で(既定は日本語「人生 12,617日目」)
List<MorningItem> buildMorningSchedule({
  required DateTime now,
  required DateTime birthDate,
  required int hour,
  required int minute,
  required QuestionBank bank,
  int days = morningDays,
  String languageCode = 'ja',
}) {
  final l = appLocalizationsFor(languageCode);
  var first = DateTime(now.year, now.month, now.day, hour, minute);
  if (!first.isAfter(now)) {
    first = DateTime(now.year, now.month, now.day + 1, hour, minute);
  }
  return [
    for (var i = 0; i < days; i++)
      () {
        // 日付は足し算ではなく日の値で作る(夏時間で時刻がずれないように)
        final when = DateTime(first.year, first.month, first.day + i, hour, minute);
        return MorningItem(
          id: morningIdBase + i,
          when: when,
          title: l.notificationTitle(lifeDaysOn(birthDate, when)),
          body: bank.forDate(when).text,
        );
      }(),
  ];
}
