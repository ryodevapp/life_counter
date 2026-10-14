import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:life_counter/main.dart' as app;
import 'package:shared_preferences/shared_preferences.dart';
import 'helpers.dart';

/// v1.1 の主な画面を撮る(生年月日を入れた状態から始める)
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('v1.1 screens', (tester) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);
    await prefs.setInt('birth_date', DateTime(1992, 4, 1).millisecondsSinceEpoch);
    await prefs.setString('gender', 'male');

    app.main();
    await wait(tester, 3500);

    // 今日: 問い・スタンプ・答える欄
    expect(byText('今日の問い'), findsWidgets);
    await shot(binding, tester, '01_today');

    await tester.tap(find.text('😊'));
    await wait(tester);
    await tester.enterText(find.byType(TextField).first, '近所を散歩して、金木犀の香りがした');
    await wait(tester, 2600); // 2秒の自動保存を待つ
    await shot(binding, tester, '02_today_answered');

    // 記録: カレンダーにスタンプ
    await tapText(tester, '記録');
    await shot(binding, tester, '03_records');

    // 人生: やりたいことリスト
    await tapText(tester, '人生');
    await tester.drag(find.byType(SingleChildScrollView).last, const Offset(0, -800));
    await wait(tester);
    expect(byText('やりたいこと'), findsWidgets);
    await shot(binding, tester, '04_life_bucket');

    // マイページ: 記録を書き出す
    await tapText(tester, 'マイページ');
    await shot(binding, tester, '05_my_page');
  });
}
