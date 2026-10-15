import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:life_counter/main.dart' as app;
import 'package:shared_preferences/shared_preferences.dart';
import 'helpers.dart';

/// v1.1 の主な画面を、ユーザーの流れのとおりに撮る(生年月日を入れた状態から始める)
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('v1.1 screens', (tester) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);
    await prefs.setInt('birth_date', DateTime(1992, 4, 1).millisecondsSinceEpoch);
    await prefs.setString('gender', 'male');

    app.main();
    await wait(tester, 3500);

    // 今日: 気分のカードと、今日の問いのカード
    await shot(binding, tester, '01_today');
    await tester.drag(find.byType(SingleChildScrollView).first, const Offset(0, -400));
    await wait(tester);
    await shot(binding, tester, '01b_today_scrolled');
    await tester.drag(find.byType(SingleChildScrollView).first, const Offset(0, 400));
    await wait(tester);

    await tester.tap(find.text('うれしい'));
    await wait(tester);
    await tester.enterText(find.byType(TextField).first, '近所を散歩して、金木犀の香りがした');
    await wait(tester, 2600); // 2秒の自動保存を待つ
    FocusManager.instance.primaryFocus?.unfocus();
    await wait(tester);
    await shot(binding, tester, '02_today_answered');

    // 記録: 一覧(日付と気分 → 問い → 答え)
    await tapText(tester, '記録');
    await shot(binding, tester, '03_records_list');
    await tapText(tester, 'ふりかえり');
    await shot(binding, tester, '04_records_reflection');

    // 人生: やりたいこと(バケットリスト)
    await tapText(tester, '人生');
    await tapText(tester, 'やりたいこと');
    await shot(binding, tester, '05_life_bucket');
  });
}
