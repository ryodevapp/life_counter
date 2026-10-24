import 'package:flutter_test/flutter_test.dart';
import 'package:life_counter/models/important_person.dart';
import 'package:life_counter/services/great_person_service.dart';
import 'package:life_counter/services/life_calculator.dart';
import 'package:life_counter/services/morning_schedule.dart';
import 'package:life_counter/utils/date_only.dart';
import 'package:life_counter/views/life/important_people_section.dart';

/// 夏時間の間の深夜0時台に、日数が1日少なく出ないか(LC-30 の続き)。
///
/// 冬(標準時)に生まれた人の誕生日 0:00 から、夏(夏時間)の日の 0:00〜0:59 までは、
/// 時刻の差で数えると「暦の日数 × 24 時間 − 1 時間」になり、inDays が1つ減る。
/// 端末の時間帯は `tools/test_tz.sh` が `TZ=America/New_York` などで流して変える。
/// 夏時間の無い時間帯(東京など)では、どの式でも同じ値になるので、ただ通る。
void main() {
  final zone = DateTime(2026, 7, 15).timeZoneName;
  final hasDst =
      DateTime(2026, 1, 15).timeZoneOffset != DateTime(2026, 7, 15).timeZoneOffset;

  // 冬生まれ(標準時)。夏時間の期間の深夜の時刻を並べる
  final birth = DateTime(1990, 1, 15);
  final nights = [
    DateTime(2026, 7, 15, 0, 0),
    DateTime(2026, 7, 15, 0, 30),
    DateTime(2026, 7, 15, 0, 59, 59),
    DateTime(2026, 3, 9, 0, 15), // 夏時間に入った次の日(米国は 2026-03-08 から)
    DateTime(2026, 10, 31, 0, 45), // 夏時間の終わる前の日(米国は 2026-11-01 まで)
  ];
  // 暦の日で数えた正しい値(UTC の年月日で数えるので時間帯に左右されない)
  int calendarDays(DateTime from, DateTime to) =>
      DateTime.utc(to.year, to.month, to.day)
          .difference(DateTime.utc(from.year, from.month, from.day))
          .inDays;

  group('夏時間の深夜0時台($zone, 夏時間 ${hasDst ? 'あり' : 'なし'})', () {
    for (final now in nights) {
      final label = now.toIso8601String();

      test('人生◯日目(LifeCalculator.lifeDays) $label', () {
        expect(LifeCalculator.lifeDays(birth, now),
            calendarDays(birth, now) + 1);
        // 今日の画面・ウィジェット・通知の数え方(lifeDaysOn)と同じ値
        expect(LifeCalculator.lifeDays(birth, now), lifeDaysOn(birth, now));
      });

      test('一緒に過ごしてきた日数(sharedDays) $label', () {
        final theirs = DateTime(1960, 12, 1);
        expect(sharedDays(birth, theirs, now), calendarDays(birth, now) + 1);
      });

      test('最後に会ってからの日数(daysSince) $label', () {
        final lastMet = DateTime(2026, 2, 1);
        expect(daysSince(lastMet, now), calendarDays(lastMet, now));
      });

      test('健康寿命までの残り日数 $label', () {
        final hl = LifeCalculator.healthyLifespan(Gender.unspecified);
        expect(
            LifeCalculator.healthyRemainingDays(
                birth, Gender.unspecified, now),
            (hl * 365.25 - calendarDays(birth, now)).floor());
      });

      test('いまの年齢(exactAge) $label', () {
        expect(LifeCalculator.exactAge(birth, now),
            calendarDays(birth, now) / 365.25);
      });

      test('偉人エピソードの年の何日目 $label', () {
        expect(GreatPersonService.dayOfYear(now),
            calendarDays(DateTime(now.year), now));
      });
    }
  });

  test('夏時間の切り替えの日の前後でも、1日に1つずつ増える($zone)', () {
    // 2026-03-07 〜 2026-03-10 と 2026-10-31 〜 2026-11-02 の 0:30
    final days = [
      for (final d in [7, 8, 9, 10]) DateTime(2026, 3, d, 0, 30),
      for (final d in [
        DateTime(2026, 10, 31, 0, 30),
        DateTime(2026, 11, 1, 0, 30),
        DateTime(2026, 11, 2, 0, 30),
      ])
        d,
    ];
    for (var i = 1; i < 4; i++) {
      expect(LifeCalculator.lifeDays(birth, days[i]),
          LifeCalculator.lifeDays(birth, days[i - 1]) + 1);
    }
    for (var i = 5; i < 7; i++) {
      expect(LifeCalculator.lifeDays(birth, days[i]),
          LifeCalculator.lifeDays(birth, days[i - 1]) + 1);
    }
  });

  test('calendarDaysBetween は時刻を見ず、暦の日の差を返す', () {
    expect(calendarDaysBetween(DateTime(2026, 3, 7, 23, 59), DateTime(2026, 3, 8)),
        1);
    expect(calendarDaysBetween(DateTime(1990, 1, 15), DateTime(2026, 7, 15, 0, 30)),
        calendarDays(DateTime(1990, 1, 15), DateTime(2026, 7, 15)));
    expect(calendarDaysBetween(DateTime(2026, 7, 15), DateTime(2026, 7, 14)), -1);
  });
}
