import '../models/bucket_item.dart';
import '../models/daily_record.dart';
import '../models/stamp.dart';
import 'question_bank.dart';

/// 記録をテキストにする(日付の古い順、最後にやりたいこと)。空の項目は書かない
String exportRecordsAsText(
  List<DailyRecord> records,
  List<BucketItem> buckets,
  QuestionBank bank, {
  Map<int, String> personNames = const {},
}) {
  final out = StringBuffer('LifeCounter の記録\n');
  final sorted = [...records]..sort((a, b) => a.date.compareTo(b.date));
  for (final r in sorted) {
    final lines = <String>[];
    void add(String label, String? value) {
      if (value != null && value.trim().isNotEmpty) lines.add('$label: $value');
    }

    final question =
        r.morningQuestionId == null ? null : bank.byId(r.morningQuestionId!);
    if (r.stamp != null || r.answer != null) add('問い', question?.text);
    add('スタンプ', stampById(r.stamp)?.emoji);
    add('答え', r.answer);
    add('感謝していること', r.gratitude);
    add('今日を素晴らしい一日にするために', r.todayGoal);
    add('嬉しかったこと', r.reflectionGood);
    add('なぜ', r.reflectionWhy);
    add('明日の楽しみ', r.reflectionTomorrow);
    add('明日の自分へ', r.tomorrowMessage);
    add('今週のハイライト', r.weeklyReflectionHighlight);
    add('来週変えること', r.weeklyReflectionChange);
    if (lines.isEmpty) continue;
    final d = r.date;
    out
      ..writeln()
      ..writeln('${d.year}-${_two(d.month)}-${_two(d.day)}')
      ..writeAll(lines.map((l) => '$l\n'));
  }
  if (buckets.isNotEmpty) {
    out
      ..writeln()
      ..writeln('バケットリスト');
    for (final b in buckets) {
      final mark = b.doneAt != null ? '[かなえた] ' : '';
      final who = personNames[b.personId];
      out.writeln('- $mark${b.title}${who != null ? '($whoと)' : ''}');
    }
  }
  return out.toString();
}

String _two(int n) => n.toString().padLeft(2, '0');
