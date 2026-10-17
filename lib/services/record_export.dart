import '../l10n/l10n.dart';
import '../models/bucket_item.dart';
import '../models/daily_record.dart';
import '../models/stamp.dart';
import '../utils/day_key.dart';
import 'question_bank.dart';

/// 記録をテキストにする(日付の古い順、最後にやりたいこと)。空の項目は書かない
/// 見出しは [languageCode] の言語で(既定は日本語)
String exportRecordsAsText(
  List<DailyRecord> records,
  List<BucketItem> buckets,
  QuestionBank bank, {
  Map<int, String> personNames = const {},
  String languageCode = 'ja',
}) {
  final l = appLocalizationsFor(languageCode);
  final out = StringBuffer('${l.exportTitle}\n');
  final sorted = [...records]..sort((a, b) => a.day.compareTo(b.day));
  for (final r in sorted) {
    final lines = <String>[];
    void add(String label, String? value) {
      if (value != null && value.trim().isNotEmpty) lines.add('$label: $value');
    }

    final question =
        r.morningQuestionId == null ? null : bank.byId(r.morningQuestionId!);
    if (r.stamp != null || r.answer != null) {
      add(l.exportQuestion, question?.text);
    }
    final mood = stampById(r.stamp);
    add(l.exportMood, mood == null ? null : moodLabelOf(l, mood.id));
    add(l.exportAnswer, r.answer);
    add(l.fieldGratitude, r.gratitude);
    add(l.exportTodayGoal, r.todayGoal);
    add(l.fieldGoodThing, r.reflectionGood);
    add(l.exportWhy, r.reflectionWhy);
    add(l.fieldTomorrowJoy, r.reflectionTomorrow);
    add(l.fieldTomorrowMessage, r.tomorrowMessage);
    add(l.fieldWeeklyHighlight, r.weeklyReflectionHighlight);
    add(l.fieldWeeklyChange, r.weeklyReflectionChange);
    if (lines.isEmpty) continue;
    out
      ..writeln()
      ..writeln(dayKeyOf(r.day))
      ..writeAll(lines.map((l) => '$l\n'));
  }
  if (buckets.isNotEmpty) {
    out
      ..writeln()
      ..writeln(l.exportBucketList);
    for (final b in buckets) {
      final mark = b.doneAt != null ? l.exportDoneMark : '';
      final who = personNames[b.personId];
      out.writeln('- $mark${b.title}${who != null ? l.exportWithPerson(who) : ''}');
    }
  }
  return out.toString();
}
