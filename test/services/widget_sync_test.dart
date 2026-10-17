import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_counter/models/question.dart';
import 'package:life_counter/services/morning_schedule.dart';
import 'package:life_counter/services/question_bank.dart';
import 'package:life_counter/services/widget_sync.dart';

void main() {
  final bank = QuestionBank([
    for (var d = 1; d <= 365; d++)
      Question(id: 'q$d', category: 'self', text: '問い$d', dayOfYear: d),
  ]);
  final birth = DateTime(1992, 4, 1);
  final now = DateTime(2026, 10, 15, 9);

  group('buildWidgetPayload', () {
    final days = buildWidgetPayload(today: now, birthDate: birth, bank: bank);
    test('60 days starting today, life days go up by one', () {
      expect(days.length, 60);
      expect(days.first['d'], '2026-10-15');
      expect(days.first['n'], lifeDaysOn(birth, now));
      for (var i = 1; i < days.length; i++) {
        expect(days[i]['n'], (days[i - 1]['n'] as int) + 1);
      }
    });
    test('question is the day\'s question, and nothing personal is included', () {
      expect(days.first['q'], questionWithFollowUp(bank.forDate(now)));
      expect(days.first.keys.toSet(), {'d', 'n', 'q'});
    });
  });

  group('parsePendingStamps', () {
    String enc(Object o) => jsonEncode(o);
    final t = now.millisecondsSinceEpoch / 1000;

    test('reads valid entries and a clear', () {
      final list = parsePendingStamps(
          enc([
            {'d': '2026-10-15', 's': 'happy', 't': t},
            {'d': '2026-10-14', 's': '', 't': t},
          ]),
          now);
      expect(list.length, 2);
      expect(list[0].stampId, 'happy');
      expect(list[0].date, DateTime(2026, 10, 15));
      expect(list[1].stampId, isNull);
    });

    test('drops broken input safely', () {
      expect(parsePendingStamps(null, now), isEmpty);
      expect(parsePendingStamps('not json', now), isEmpty);
      expect(parsePendingStamps(enc({'d': 'x'}), now), isEmpty);
      expect(
          parsePendingStamps(
              enc([
                {'d': '2026-10-15', 's': 'unknown', 't': t}, // 知らないスタンプ
                {'d': '2026-13-40', 's': 'happy', 't': t}, // ありえない日付
                {'d': '2026-10-07', 's': 'happy', 't': t}, // 古すぎる(8日前)
                {'d': '2026-10-16', 's': 'happy', 't': t}, // 未来
                {'d': '2026-10-15', 's': 'happy'}, // 時刻がない
                'string',
              ]),
              now),
          isEmpty);
    });

    test('keeps stamps from 3 days ago (app not opened for a while)', () {
      // 10/12 に押して、アプリを開いたのは 10/15
      final tapped = DateTime(2026, 10, 12, 21).millisecondsSinceEpoch / 1000;
      final list = parsePendingStamps(
          enc([
            {'d': '2026-10-12', 's': 'tired', 't': tapped},
            {'d': '2026-10-13', 's': '', 't': tapped + 86400},
          ]),
          now);
      expect(list.length, 2);
      expect(list[0].date, DateTime(2026, 10, 12));
      expect(list[0].stampId, 'tired');
      expect(list[0].at, DateTime(2026, 10, 12, 21));
      expect(list[1].date, DateTime(2026, 10, 13));
      expect(list[1].stampId, isNull);
    });

    test('accepts up to maxPendingStampDays days back, not more', () {
      final edge = DateTime(2026, 10, 15 - maxPendingStampDays, 12);
      final tooOld = DateTime(2026, 10, 15 - maxPendingStampDays - 1, 12);
      String entry(DateTime d) => enc([
            {'d': ymd(d), 's': 'calm', 't': d.millisecondsSinceEpoch / 1000},
          ]);
      expect(parsePendingStamps(entry(edge), now).length, 1);
      expect(parsePendingStamps(entry(tooOld), now), isEmpty);
    });

    test('a tap time long before the stamp day is dropped', () {
      // 10/12 の分なのに、押した時刻が 10/10 (前日の 0:00 より前)
      final t = DateTime(2026, 10, 10, 12).millisecondsSinceEpoch / 1000;
      expect(
          parsePendingStamps(
              enc([
                {'d': '2026-10-12', 's': 'happy', 't': t},
              ]),
              now),
          isEmpty);
    });

    test('an old widget stamp still loses to a later edit in the app', () {
      final tapped = DateTime(2026, 10, 12, 21);
      final p = parsePendingStamps(
              enc([
                {'d': '2026-10-12', 's': 'tired', 't': tapped.millisecondsSinceEpoch / 1000},
              ]),
              now)
          .single;
      expect(widgetStampWins(DateTime(2026, 10, 15, 8), p.at), isFalse);
      expect(widgetStampWins(DateTime(2026, 10, 12, 20), p.at), isTrue);
    });

    test('caps the number of entries', () {
      final many = List.generate(
          500, (_) => {'d': '2026-10-15', 's': 'calm', 't': t});
      expect(parsePendingStamps(enc(many), now).length, 200);
    });
  });

  test('drops times far in the past or future', () {
    final t = now.millisecondsSinceEpoch / 1000;
    expect(
        parsePendingStamps(
            jsonEncode([
              {'d': '2026-10-15', 's': 'happy', 't': 1e13},
              {'d': '2026-10-15', 's': 'happy', 't': t + 7200},
              {'d': '2026-10-15', 's': 'happy', 't': t - 3 * 86400},
            ]),
            now),
        isEmpty);
  });

  test('keeps stamps tapped while importing', () {
    final a = {'d': '2026-10-15', 's': 'happy', 't': 1};
    final b = {'d': '2026-10-15', 's': 'calm', 't': 2};
    expect(remainingAfterImport(jsonEncode([a]), jsonEncode([a, b])), jsonEncode([b]));
    expect(remainingAfterImport(jsonEncode([a]), jsonEncode([a])), '[]');
    expect(remainingAfterImport(jsonEncode([a]), null), '[]');
    // キーの並びが違っても同じ件とみなす
    expect(remainingAfterImport('[{"d":"2026-10-15","s":"happy","t":1}]',
        '[{"t":1,"d":"2026-10-15","s":"happy"}]'), '[]');
  });

  group('widgetStampWins', () {
    test('widget wins when the app has no stamp time or an older one', () {
      expect(widgetStampWins(null, now), isTrue);
      expect(widgetStampWins(now.subtract(const Duration(minutes: 1)), now), isTrue);
    });
    test('app wins when it was changed after the widget tap', () {
      expect(widgetStampWins(now.add(const Duration(minutes: 1)), now), isFalse);
    });
  });
}
