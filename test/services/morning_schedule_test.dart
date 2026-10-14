import 'package:flutter_test/flutter_test.dart';
import 'package:life_counter/models/question.dart';
import 'package:life_counter/services/morning_schedule.dart';
import 'package:life_counter/services/question_bank.dart';

void main() {
  final bank = QuestionBank([
    for (var d = 1; d <= 365; d++)
      Question(id: 'q$d', category: 'self', text: '問い$d', dayOfYear: d),
  ]);
  final birth = DateTime(1992, 4, 1);

  List<MorningItem> build(DateTime now) => buildMorningSchedule(
      now: now, birthDate: birth, hour: 7, minute: 0, bank: bank);

  test('60 items with ids 100..159', () {
    final items = build(DateTime(2026, 10, 15, 6, 0));
    expect(items.length, 60);
    expect(items.first.id, 100);
    expect(items.last.id, 159);
  });

  test('starts today if the time has not passed, otherwise tomorrow', () {
    expect(build(DateTime(2026, 10, 15, 6, 59)).first.when, DateTime(2026, 10, 15, 7));
    expect(build(DateTime(2026, 10, 15, 7, 0)).first.when, DateTime(2026, 10, 16, 7));
  });

  test('life days go up by one each day and the body is that day\'s question', () {
    final items = build(DateTime(2026, 10, 15, 6, 0));
    expect(items[0].title, '人生 ${_fmt(lifeDaysOn(birth, DateTime(2026, 10, 15)))}日目');
    for (var i = 1; i < items.length; i++) {
      expect(lifeDaysOn(birth, items[i].when), lifeDaysOn(birth, items[i - 1].when) + 1);
      expect(items[i].body, bank.forDate(items[i].when).text);
      expect(items[i].when.hour, 7);
    }
  });

  test('crosses the year end', () {
    final items = build(DateTime(2027, 12, 20, 8, 0));
    expect(items.first.when, DateTime(2027, 12, 21, 7));
    expect(items.any((m) => m.when == DateTime(2028, 1, 1, 7)), isTrue);
  });

  test('includes a leap day with the Feb 28 question', () {
    final items = build(DateTime(2028, 1, 15, 8, 0));
    final leap = items.firstWhere((m) => m.when == DateTime(2028, 2, 29, 7));
    expect(leap.body, bank.forDate(DateTime(2027, 2, 28)).text);
  });

  test('birth day counts as day 1', () {
    expect(lifeDaysOn(birth, birth), 1);
    expect(lifeDaysOn(birth, DateTime(1992, 4, 2, 23, 59)), 2);
  });

  test('no forbidden words in titles', () {
    for (final m in build(DateTime(2026, 10, 15))) {
      for (final w in ['余命', '寿命', '死ぬまで', 'あと何日']) {
        expect(m.title.contains(w), isFalse);
      }
    }
  });
}

String _fmt(int n) => n.toString().replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},');
