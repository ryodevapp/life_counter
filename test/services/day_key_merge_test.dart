import 'package:flutter_test/flutter_test.dart';
import 'package:life_counter/models/daily_record.dart';
import 'package:life_counter/services/day_key_merge.dart';

void main() {
  DailyRecord rec(int id, DateTime date, DateTime updatedAt) => DailyRecord()
    ..id = id
    ..date = date
    ..createdAt = updatedAt
    ..updatedAt = updatedAt;

  group('mergeSameDayRecords', () {
    test('keeps the newer record id and every non-empty field', () {
      final older = rec(1, DateTime(2026, 10, 15), DateTime(2026, 10, 15, 9))
        ..gratitude = '家族'
        ..greatPersonId = 'p1'
        ..morningQuestionId = 'q-old';
      final newer = rec(2, DateTime(2026, 10, 15), DateTime(2026, 10, 15, 21))
        ..todayGoal = '散歩'
        ..morningQuestionId = 'q-new';
      final m = mergeSameDayRecords([older, newer]);
      expect(m.id, 2);
      expect(m.gratitude, '家族');
      expect(m.todayGoal, '散歩');
      expect(m.greatPersonId, 'p1');
      expect(m.morningQuestionId, 'q-new');
      expect(m.createdAt, DateTime(2026, 10, 15, 9));
      expect(m.updatedAt, DateTime(2026, 10, 15, 21));
    });

    test('never drops text: different texts are joined, newer first', () {
      final older = rec(1, DateTime(2026, 10, 15), DateTime(2026, 10, 15, 9))
        ..answer = '朝の答え'
        ..reflectionGood = '同じ文';
      final newer = rec(2, DateTime(2026, 10, 15), DateTime(2026, 10, 15, 21))
        ..answer = '夜の答え'
        ..reflectionGood = '同じ文'
        ..tomorrowMessage = '   ';
      final m = mergeSameDayRecords([older, newer]);
      expect(m.answer, '夜の答え\n\n朝の答え');
      expect(m.reflectionGood, '同じ文'); // 同じ文は2回つながない
      expect(m.tomorrowMessage, isNull); // 空白だけは文として数えない
    });

    test('stamp follows the latest stampAt, even from the older record', () {
      final older = rec(1, DateTime(2026, 10, 15), DateTime(2026, 10, 15, 9))
        ..stamp = 'happy'
        ..stampAt = DateTime(2026, 10, 15, 22);
      final newer = rec(2, DateTime(2026, 10, 15), DateTime(2026, 10, 15, 23))
        ..stamp = 'sad'
        ..stampAt = DateTime(2026, 10, 15, 8);
      final m = mergeSameDayRecords([newer, older]);
      expect(m.stamp, 'happy');
      expect(m.stampAt, DateTime(2026, 10, 15, 22));
    });

    test('a later clear (null stamp with stampAt) wins over an older stamp',
        () {
      final older = rec(1, DateTime(2026, 10, 15), DateTime(2026, 10, 15, 9))
        ..stamp = 'happy'
        ..stampAt = DateTime(2026, 10, 15, 9);
      final newer = rec(2, DateTime(2026, 10, 15), DateTime(2026, 10, 15, 10))
        ..stamp = null
        ..stampAt = DateTime(2026, 10, 15, 10);
      expect(mergeSameDayRecords([older, newer]).stamp, isNull);
    });

    test('without stampAt, the stamp of the newer record is kept', () {
      final older = rec(1, DateTime(2026, 10, 15), DateTime(2026, 10, 15, 9))
        ..stamp = 'calm';
      final newer = rec(2, DateTime(2026, 10, 15), DateTime(2026, 10, 15, 10));
      expect(mergeSameDayRecords([older, newer]).stamp, 'calm');
    });
  });

  group('planDayKeyMigration across a time-zone shift', () {
    const tokyo = Duration(hours: 9);
    const losAngeles = Duration(hours: -7);

    // v1.1.0 を東京で使い、ロサンゼルスへ移ったあと、旧版が 10/15 を見つけられずに
    // もう1件作ってしまった状態
    List<DailyRecord> shifted() => [
          rec(1, DateTime.utc(2026, 10, 13, 15), DateTime.utc(2026, 10, 14, 11))
            ..answer = '14日の答え', // 東京の 10/14
          rec(2, DateTime.utc(2026, 10, 14, 15), DateTime.utc(2026, 10, 15, 0))
            ..answer = '東京で書いた'
            ..stamp = 'happy'
            ..stampAt = DateTime.utc(2026, 10, 15, 0), // 東京の 10/15
          rec(3, DateTime.utc(2026, 10, 15, 7), DateTime.utc(2026, 10, 16, 4))
            ..answer = 'LAで書いた', // ロサンゼルスの 10/15
        ];

    test('records keep their day and duplicates are merged', () {
      final plan = planDayKeyMigration(shifted(), localOffset: losAngeles);
      expect(plan.deleteIds, [2]);
      final byKey = {for (final r in plan.put) r.dayKey: r};
      expect(byKey.keys.toSet(), {'2026-10-14', '2026-10-15'});
      expect(byKey['2026-10-14']!.id, 1);
      final oct15 = byKey['2026-10-15']!;
      expect(oct15.id, 3);
      expect(oct15.answer, 'LAで書いた\n\n東京で書いた');
      expect(oct15.stamp, 'happy');
    });

    test('same result when migrating back in the original zone', () {
      final plan = planDayKeyMigration(shifted(), localOffset: tokyo);
      expect(plan.deleteIds, [2]);
      expect(plan.put.map((r) => r.dayKey).toSet(),
          {'2026-10-14', '2026-10-15'});
    });

    test('records that already have a key are left alone', () {
      final r = rec(9, DateTime.utc(2026, 10, 14, 15), DateTime.utc(2026, 10, 15))
        ..dayKey = '2026-10-15';
      final plan = planDayKeyMigration([r], localOffset: losAngeles);
      expect(plan.put, isEmpty);
      expect(plan.deleteIds, isEmpty);
    });

    test('a key already set and an old record for the same day are merged', () {
      final kept = rec(9, DateTime.utc(2026, 10, 15, 7), DateTime.utc(2026, 10, 16))
        ..dayKey = '2026-10-15'
        ..answer = '新しい版で書いた';
      final old = rec(2, DateTime.utc(2026, 10, 14, 15), DateTime.utc(2026, 10, 15))
        ..gratitude = '友だち';
      final plan = planDayKeyMigration([kept, old], localOffset: losAngeles);
      expect(plan.deleteIds, [2]);
      expect(plan.put.single.id, 9);
      expect(plan.put.single.answer, '新しい版で書いた');
      expect(plan.put.single.gratitude, '友だち');
    });
  });
}
