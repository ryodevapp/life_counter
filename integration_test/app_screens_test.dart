import 'package:isar/isar.dart';
import 'package:life_counter/models/daily_record.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:life_counter/main.dart' as app;
import 'package:shared_preferences/shared_preferences.dart';
import 'helpers.dart';

/// オンボーディングを終えた状態から、家族の登録・記録・各タブ
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('app screens', (tester) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('birth_date', DateTime(1986, 5, 1).millisecondsSinceEpoch);
    await prefs.setString('gender', 'male');
    await prefs.setBool('onboarding_completed', true);
    await prefs.setBool('notification_enabled', false);

    app.main();
    await wait(tester, 3000);
    await shot(binding, tester, '10_family_empty');

    // 親を追加(初期値: 65歳・年に1〜2回)
    await tapText(tester, '家族を追加する');
    await shot(binding, tester, '11_form_parent');
    await tester.enterText(find.byType(EditableText).first, 'お母さん');
    await wait(tester);
    await tapText(tester, '追加');

    // 子どもを追加(初期値: 6歳・18歳まで)
    await tapText(tester, '+ 家族を追加');
    await tapText(tester, '子ども');
    await tester.enterText(find.byType(EditableText).first, 'ゆい');
    await wait(tester);
    await shot(binding, tester, '12_form_child');
    await tapText(tester, '追加');
    await shot(binding, tester, '13_family_list');

    // 電話した(ワンタップ)→ 取り消しの案内を撮る
    await tapText(tester, '電話した');
    await shot(binding, tester, '13b_quick_call');
    // 会えた日を残す(シート)
    await tester.ensureVisible(find.text('会えた').first);
    await tester.tap(find.text('会えた').first);
    await wait(tester);
    await tester.enterText(find.byType(EditableText).last, '母と温泉。よく笑ってた');
    await wait(tester);
    await shot(binding, tester, '14_log_sheet');
    await tapText(tester, '残す');
    await wait(tester, 2000);

    // 詳細
    await tester.ensureVisible(find.text('お母さん').first);
    await wait(tester, 400);
    await tester.tap(find.text('お母さん').first);
    await shot(binding, tester, '15_detail');
    await tester.pageBack();
    await wait(tester);

    // 以前からの利用者の日記(v1.0 のデータ)を入れて、記録タブを見る
    final isar = Isar.getInstance()!;
    await isar.writeTxn(() => isar.dailyRecords.put(DailyRecord()
      ..date = DateTime.now().subtract(const Duration(days: 30))
      ..gratitude = '家族が元気でいること'
      ..reflectionGood = '夕焼けがきれいだった'));
    await tester.tap(find.text('家族').last);
    await wait(tester);
    await tester.tap(find.text('記録').last);
    await shot(binding, tester, '20_records');
    await tester.tap(byText('ふりかえりを見る').first);
    await shot(binding, tester, '23_review_free');
    await tester.pageBack();
    await wait(tester);
    await tester.tap(find.text('設定').last);
    await shot(binding, tester, '21_settings');
    await tester.tap(byText('LifeCounter Pro').first);
    await shot(binding, tester, '22_pro_sheet');
  });
}
