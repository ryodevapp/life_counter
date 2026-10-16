import 'package:flutter_test/flutter_test.dart';
import 'package:life_counter/models/daily_record.dart';
import 'package:life_counter/services/review_prompt.dart';

void main() {
  DailyRecord rec(String? answer) => DailyRecord()
    ..date = DateTime(2026, 10, 1)
    ..answer = answer;

  test('答えを書いた日だけを数える(空や空白だけは数えない)', () {
    expect(ReviewPrompt.answeredDays([rec('a'), rec(''), rec('  '), rec(null), rec('b')]), 2);
  });

  test('7日目に1回だけお願いする', () {
    expect(ReviewPrompt.shouldAsk(answeredDays: 6, alreadyAsked: false), isFalse);
    expect(ReviewPrompt.shouldAsk(answeredDays: 7, alreadyAsked: false), isTrue);
    expect(ReviewPrompt.shouldAsk(answeredDays: 30, alreadyAsked: true), isFalse);
  });
}
