import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:life_counter/main.dart' as app;
import 'package:shared_preferences/shared_preferences.dart';
import 'helpers.dart';

/// v1.1 の主な画面を、ユーザーの流れのとおりに撮る(生年月日を入れた状態から始める)
/// 切り替えの途中(アニメーションの最中)も撮って、崩れがないかを見る
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<void> midShot(WidgetTester tester, String name) async {
    await tester.pump(const Duration(milliseconds: 90));
    await binding.takeScreenshot(name);
  }

  testWidgets('v1.1 screens', (tester) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);
    await prefs.setInt('birth_date', DateTime(1992, 4, 1).millisecondsSinceEpoch);
    await prefs.setString('gender', 'male');

    app.main();
    await wait(tester, 3500);

    // 今日: 気分のカードと、今日の問いのカード
    await shot(binding, tester, '01_today');
    await tester.tap(findText('うれしい'));
    await midShot(tester, '01m_mood_tapping');
    await wait(tester);
    await tester.enterText(find.byType(TextField).first,
        'ああいいと思います ああこれ入力されてるかどうかわかんなくない ああ文字反映されてますか あいうえおかきくけこさしすせそ');
    await wait(tester, 2600); // 2秒の自動保存を待つ
    FocusManager.instance.primaryFocus?.unfocus();
    await wait(tester);
    await tester.drag(find.byType(SingleChildScrollView).first, const Offset(0, -500));
    await wait(tester);
    await shot(binding, tester, '02_today_answered');

    // 記録: リスト → カレンダー(切り替えの途中も撮る)
    await tapText(tester, '記録');
    await shot(binding, tester, '03_records_list');
    await tester.tap(findText('カレンダー').last);
    await midShot(tester, '03m_switch_to_calendar');
    await wait(tester);
    await shot(binding, tester, '04_records_calendar');
    await tester.tap(findText('リスト').last);
    await midShot(tester, '05m_switch_to_list');
    await wait(tester);

    // 人生: やりたいこと(バケットリスト)を、書く → 追加 → できた → メニュー まで
    await tapText(tester, '人生');
    await tapText(tester, 'バケットリスト');
    await shot(binding, tester, '06_bucket_empty');
    await tester.enterText(find.byType(TextField).last, '家族で温泉に行く');
    await wait(tester);
    await shot(binding, tester, '07_bucket_typing');
    await tester.tap(find.bySemanticsLabel('追加'));
    await wait(tester);
    await tester.enterText(find.byType(TextField).last, 'オーロラを見る');
    await tester.tap(find.bySemanticsLabel('追加'));
    await wait(tester);
    FocusManager.instance.primaryFocus?.unfocus();
    await wait(tester);
    await shot(binding, tester, '08_bucket_two_items');
    await tester.tap(find.bySemanticsLabel('まだかなえていない').last);
    await wait(tester);
    await shot(binding, tester, '09_bucket_done');
    await tester.tap(findText('オーロラを見る').last);
    await wait(tester);
    await shot(binding, tester, '10_bucket_edit');
  });
}
