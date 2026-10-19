import 'package:flutter_test/flutter_test.dart';
import 'package:life_counter/models/daily_record.dart';
import 'package:life_counter/services/review_prompt.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  test('1.1.1 までに2日目か7日目のお願いをした人には、もう出さない', () async {
    Future<bool> asked(Map<String, Object> values) async {
      SharedPreferences.setMockInitialValues(values);
      return ReviewPrompt.alreadyAsked(await SharedPreferences.getInstance());
    }

    expect(await asked({}), isFalse);
    expect(await asked({'review_asked': true}), isTrue);
    expect(await asked({'review_requested_day2': true}), isTrue);
    expect(await asked({'review_requested_day7': true}), isTrue);
  });
}
