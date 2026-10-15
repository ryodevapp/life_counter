import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:life_counter/main.dart' as app;
import 'package:shared_preferences/shared_preferences.dart';
import 'helpers.dart';

/// デザインの見直し用に、すべてのタブと切り替えを撮る(生年月日を入れた状態から始める)
/// 画像の名前の頭に SHOT_PREFIX(なければ a_)を付けて、直す前と後を並べて比べられるようにする
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  const prefix = String.fromEnvironment('SHOT_PREFIX', defaultValue: 'a_');

  testWidgets('all screens', (tester) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);
    await prefs.setInt('birth_date', DateTime(1992, 4, 1).millisecondsSinceEpoch);
    await prefs.setString('gender', 'male');

    app.main();
    await wait(tester, 3500);

    await tester.tap(find.text('おだやか'));
    await wait(tester);
    await tester.enterText(find.byType(TextField).first, '近所を散歩して、金木犀の香りがした');
    await wait(tester, 2600);
    FocusManager.instance.primaryFocus?.unfocus();
    await wait(tester);
    await tester.drag(find.byType(SingleChildScrollView).first, const Offset(0, 800));
    await wait(tester);
    await shot(binding, tester, '${prefix}01_today');

    await tapText(tester, '記録');
    await shot(binding, tester, '${prefix}02_records_list');
    await tapText(tester, 'カレンダー');
    await shot(binding, tester, '${prefix}03_records_calendar');
    await tapText(tester, 'ふりかえり');
    await shot(binding, tester, '${prefix}04_records_reflection');

    await tapText(tester, '人生');
    await tapText(tester, 'あなた');
    // 押した切り替えが見える位置まで送られているので、題が見える位置に戻す
    await tester.ensureVisible(find.text('人生').first);
    await wait(tester);
    await shot(binding, tester, '${prefix}05_life_you');
    await tapText(tester, '大切な人');
    await shot(binding, tester, '${prefix}06_life_people');
    await tapText(tester, 'やりたいこと');
    await shot(binding, tester, '${prefix}07_life_bucket');
    await tester.enterText(find.byType(TextField).last, '家族で温泉に行く');
    await wait(tester);
    await shot(binding, tester, '${prefix}07b_bucket_typing');
    await tester.tap(find.bySemanticsLabel('リストに足す'));
    await wait(tester);
    await tester.enterText(find.byType(TextField).last, 'オーロラを見る');
    await wait(tester, 300);
    await tester.tap(find.bySemanticsLabel('リストに足す'));
    await wait(tester, 300);
    FocusManager.instance.primaryFocus?.unfocus();
    await wait(tester);
    await tester.tap(find.bySemanticsLabel('押すと、できたにする').last);
    await shot(binding, tester, '${prefix}07c_bucket_items');

    // 下のタブの印が動いている途中(伸びているか)と、止まったところ
    await tester.tap(find.text('マイページ').last);
    await tester.pump(const Duration(milliseconds: 90));
    await binding.takeScreenshot('${prefix}08m_tab_moving');
    await shot(binding, tester, '${prefix}08_my_page');
  });
}
