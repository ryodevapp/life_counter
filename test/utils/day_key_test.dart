import 'package:flutter_test/flutter_test.dart';
import 'package:life_counter/models/daily_record.dart';
import 'package:life_counter/utils/day_key.dart';

void main() {
  const tokyo = Duration(hours: 9);
  const losAngeles = Duration(hours: -7);
  const india = Duration(hours: 5, minutes: 30);

  group('dayKeyOf / parseDayKey', () {
    test('formats yyyy-MM-dd with zero padding', () {
      expect(dayKeyOf(DateTime(2026, 1, 5)), '2026-01-05');
      expect(dayKeyOf(DateTime(2026, 10, 15, 23, 59)), '2026-10-15');
      expect(dayKeyOf(DateTime(987, 3, 4)), '0987-03-04');
    });

    test('round-trips to local midnight', () {
      expect(parseDayKey('2026-10-15'), DateTime(2026, 10, 15));
      expect(dayKeyOf(parseDayKey('2028-02-29')!), '2028-02-29');
    });

    test('rejects broken or impossible keys', () {
      expect(parseDayKey(''), isNull);
      expect(parseDayKey('2026-1-5'), isNull);
      expect(parseDayKey('2026-02-30'), isNull);
      expect(parseDayKey('2026-13-01'), isNull);
      expect(parseDayKey('2026-10-15T00:00'), isNull);
    });

    test('keys sort in date order as strings', () {
      final keys = ['2026-10-02', '2025-12-31', '2026-01-10', '2026-10-15'];
      keys.sort();
      expect(keys, ['2025-12-31', '2026-01-10', '2026-10-02', '2026-10-15']);
    });
  });

  group('monthDayKeyRange', () {
    test('first and last day of the month', () {
      expect(monthDayKeyRange(2026, 10), ('2026-10-01', '2026-10-31'));
      expect(monthDayKeyRange(2026, 2), ('2026-02-01', '2026-02-28'));
      expect(monthDayKeyRange(2028, 2), ('2028-02-01', '2028-02-29'));
    });
    test('month overflow rolls into the next year', () {
      expect(monthDayKeyRange(2026, 13), ('2027-01-01', '2027-01-31'));
    });
    test('a month range on keys does not include the next month', () {
      final (first, last) = monthDayKeyRange(2026, 10);
      bool inRange(String k) =>
          k.compareTo(first) >= 0 && k.compareTo(last) <= 0;
      expect(inRange('2026-10-01'), isTrue);
      expect(inRange('2026-10-31'), isTrue);
      expect(inRange('2026-09-30'), isFalse);
      expect(inRange('2026-11-01'), isFalse);
    });
  });

  group('legacyDayKey (date saved by v1.1.0 as local midnight)', () {
    // 東京で作った 10/15 の記録 = 10/14 15:00 UTC
    final tokyoOct15 = DateTime.utc(2026, 10, 14, 15);
    // ロサンゼルスで作った 10/15 の記録 = 10/15 07:00 UTC
    final laOct15 = DateTime.utc(2026, 10, 15, 7);

    test('same zone as when it was made: that day', () {
      expect(legacyDayKey(tokyoOct15, localOffset: tokyo), '2026-10-15');
      expect(legacyDayKey(laOct15, localOffset: losAngeles), '2026-10-15');
    });

    test('after moving to another zone, still the day it was made', () {
      // 東京 → ロサンゼルス。今の地域で読むと 10/14 8:00 だが、10/15 のまま
      expect(legacyDayKey(tokyoOct15, localOffset: losAngeles), '2026-10-15');
      // ロサンゼルス → 東京。今の地域で読むと 10/15 16:00 だが、10/15 のまま
      expect(legacyDayKey(laOct15, localOffset: tokyo), '2026-10-15');
      // 30分ずれの地域でも
      final indiaOct15 = DateTime.utc(2026, 10, 14, 18, 30);
      expect(legacyDayKey(indiaOct15, localOffset: tokyo), '2026-10-15');
    });

    test('two possible zones: the one closer to the current zone wins', () {
      // 11:00 UTC は UTC+13 の 0:00 (翌日) にも UTC-11 の 0:00 (同じ日) にもなる
      final t = DateTime.utc(2026, 10, 14, 11);
      expect(legacyDayKey(t, localOffset: const Duration(hours: 12)),
          '2026-10-15');
      expect(legacyDayKey(t, localOffset: const Duration(hours: -10)),
          '2026-10-14');
    });

    test('a time that is not midnight anywhere falls back to the local day',
        () {
      // どの地域(15分刻みの時差)でも 0:00 にならない時刻(30秒ずれ)
      final t = DateTime.utc(2026, 10, 14, 15, 0, 30);
      expect(legacyDayKey(t, localOffset: tokyo), '2026-10-15');
      expect(legacyDayKey(t, localOffset: india), '2026-10-14');
    });
  });

  group('DailyRecord day', () {
    test('new records carry the key of their day', () {
      final r = newDailyRecordFor(DateTime(2026, 10, 15, 21, 30));
      expect(r.dayKey, '2026-10-15');
      expect(r.date, DateTime(2026, 10, 15));
      expect(r.day, DateTime(2026, 10, 15));
    });

    test('day follows dayKey, not the saved instant', () {
      // 東京で作った記録を、時差の違う地域で読んだときのように date をずらす
      final r = DailyRecord()
        ..dayKey = '2026-10-15'
        ..date = DateTime(2026, 10, 14, 8);
      expect(r.day, DateTime(2026, 10, 15));
    });

    test('records without a key (before migration) use their date', () {
      final r = DailyRecord()..date = DateTime(2026, 10, 15);
      expect(r.day, DateTime(2026, 10, 15));
    });
  });
}
