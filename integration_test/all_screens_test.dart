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
    await shot(binding, tester, '${prefix}05_life_you');
    await tapText(tester, '大切な人');
    await shot(binding, tester, '${prefix}06_life_people');
    await tapText(tester, 'やりたいこと');
    await shot(binding, tester, '${prefix}07_life_bucket');

    await tapText(tester, 'マイページ');
    await shot(binding, tester, '${prefix}08_my_page');
  });
}
