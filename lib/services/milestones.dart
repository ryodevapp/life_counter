import '../models/important_person.dart';

/// 節目の通知（家族の誕生日、母の日・父の日・敬老の日、帰省シーズンの前）
class Milestone {
  const Milestone(this.when, this.title, this.body);
  final DateTime when;
  final String title;
  final String body;
}

class Milestones {
  Milestones._();

  static const _hour = 9;
  static const _planBody = '次に会う日を入れておくと、楽しみに待てます';

  /// その月の n 番目の weekday（DateTime.sunday など）
  static DateTime nthWeekday(int year, int month, int weekday, int n) {
    var d = DateTime(year, month, 1);
    while (d.weekday != weekday) {
      d = d.add(const Duration(days: 1));
    }
    return d.add(Duration(days: 7 * (n - 1)));
  }

  /// これから1年のうちに来る節目（古い順）
  static List<Milestone> upcoming(List<ImportantPerson> persons, DateTime now) {
    final list = <Milestone>[];
    void add(DateTime day, String title, String body) {
      final when = DateTime(day.year, day.month, day.day, _hour);
      if (when.isAfter(now) && when.isBefore(now.add(const Duration(days: 366)))) {
        list.add(Milestone(when, title, body));
      }
    }

    for (final year in [now.year, now.year + 1]) {
      for (final p in persons) {
        add(DateTime(year, p.birthDate.month, p.birthDate.day),
            '今日は、${p.nickname}の誕生日です', 'おめでとうを伝えてみませんか');
      }
      if (persons.any((p) => p.relation == Relation.parent)) {
        add(nthWeekday(year, 5, DateTime.sunday, 2).subtract(const Duration(days: 7)),
            '来週の日曜日は、母の日です', 'ひとこと伝えるだけでも、うれしいものです');
        add(nthWeekday(year, 6, DateTime.sunday, 3).subtract(const Duration(days: 7)),
            '来週の日曜日は、父の日です', 'ひとこと伝えるだけでも、うれしいものです');
        add(nthWeekday(year, 9, DateTime.monday, 3).subtract(const Duration(days: 7)),
            '来週の月曜日は、敬老の日です', '電話ひとつでも、きっと喜ばれます');
      }
      if (persons.isNotEmpty) {
        add(DateTime(year, 8, 1), 'お盆の予定は、決まりましたか', _planBody);
        add(DateTime(year, 12, 1), '年末年始の予定は、決まりましたか', _planBody);
      }
    }
    list.sort((a, b) => a.when.compareTo(b.when));
    return list;
  }
}
