import 'package:flutter_test/flutter_test.dart';
import 'package:life_counter/models/important_person.dart';
import 'package:life_counter/services/milestones.dart';

void main() {
  test('母の日は5月の第2日曜(2027年は5/9)', () {
    expect(Milestones.nthWeekday(2027, 5, DateTime.sunday, 2), DateTime(2027, 5, 9));
    expect(Milestones.nthWeekday(2027, 9, DateTime.monday, 3), DateTime(2027, 9, 20));
  });

  test('親がいれば母の日・父の日・敬老の日の1週間前、帰省前、誕生日', () {
    final mother = ImportantPerson()
      ..nickname = 'お母さん'
      ..birthDate = DateTime(1960, 11, 3)
      ..relation = Relation.parent;
    final list = Milestones.upcoming([mother], DateTime(2026, 10, 10));
    final titles = list.map((m) => m.title).toList();
    expect(list.first.when, DateTime(2026, 11, 3, 9));
    expect(titles, contains('今日は、お母さんの誕生日です'));
    expect(titles, contains('年末年始の予定は、決まりましたか'));
    expect(list.any((m) => m.when == DateTime(2027, 5, 2, 9)), isTrue); // 母の日 5/9 の1週間前
    expect(list.every((m) => m.when.isAfter(DateTime(2026, 10, 10))), isTrue);
  });

  test('家族がいなければ何もない', () {
    expect(Milestones.upcoming([], DateTime(2026, 10, 10)), isEmpty);
  });
}
