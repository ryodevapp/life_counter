import 'package:flutter_test/flutter_test.dart';
import 'package:life_counter/models/bucket_item.dart';
import 'package:life_counter/models/daily_record.dart';
import 'package:life_counter/models/question.dart';
import 'package:life_counter/services/question_bank.dart';
import 'package:life_counter/services/record_export.dart';

void main() {
  final bank = QuestionBank([
    for (var d = 1; d <= 365; d++)
      Question(id: 'q$d', category: 'self', text: '問い$d', dayOfYear: d),
  ]);

  DailyRecord rec(DateTime date) => DailyRecord()..date = date;

  test('oldest first, new and old fields, empty items skipped, buckets last', () {
    final text = exportRecordsAsText(
      [
        rec(DateTime(2026, 10, 15))
          ..morningQuestionId = 'q288'
          ..stamp = 'happy'
          ..answer = '散歩した',
        rec(DateTime(2026, 4, 1))..gratitude = '家族',
        rec(DateTime(2026, 5, 1)), // 空の日は書かない
      ],
      [
        BucketItem()
          ..title = '温泉に行く'
          ..personId = 1,
        BucketItem()
          ..title = '富士山'
          ..doneAt = DateTime(2026, 8, 1),
      ],
      bank,
      personNames: {1: '母'},
    );
    expect(text.indexOf('2026-04-01'), lessThan(text.indexOf('2026-10-15')));
    expect(text.contains('2026-05-01'), isFalse);
    expect(text, contains('感謝していること: 家族'));
    expect(text, contains('問い: 問い288'));
    expect(text, contains('気分: うれしい'));
    expect(text, contains('答え: 散歩した'));
    expect(text.indexOf('バケットリスト'), greaterThan(text.indexOf('2026-10-15')));
    expect(text, contains('- 温泉に行く(母と)'));
    expect(text, contains('- [かなえた] 富士山'));
  });
}
