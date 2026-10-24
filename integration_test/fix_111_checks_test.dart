import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_widget/home_widget.dart';
import 'package:integration_test/integration_test.dart';
import 'package:life_counter/main.dart' as app;
import 'package:life_counter/providers/isar_provider.dart';
import 'package:life_counter/providers/question_bank_provider.dart';
import 'package:life_counter/services/widget_sync.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'helpers.dart';

/// 1.1.1 で直した3つを、シミュレーターの本物の仕組み(Isar のファイル・App Group・時間帯)で確かめる
/// 手順ごとに別のプロセスで動かす(記録は1回の起動で1度しか開けないため)。--dart-define=STEP=<手順>
///   tz_write  今日の気分を記録する(SIMCTL_CHILD_TZ=Asia/Tokyo で起動する)
///   tz_read   別の時間帯で起動し、記録が1件のままで日付も変わらないかを見る(SIMCTL_CHILD_TZ=Pacific/Honolulu)
///   open_error 記録のファイルを壊して起動 → 案内を撮る → 戻して「もう一度試す」でふだんの画面に進むか(LC-24)
///   widget    ウィジェットで3日前に押した気分を App Group に置いて起動し、記録に入るか(LC-25)
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  const step = String.fromEnvironment('STEP');

  Future<void> setUpPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);
    await prefs.setInt('birth_date', DateTime(1990, 1, 1).millisecondsSinceEpoch);
  }

  ProviderContainer containerOf(WidgetTester tester) =>
      ProviderScope.containerOf(tester.element(find.byType(MaterialApp).first));

  testWidgets(step, (tester) async {
    final now = DateTime.now();
    debugPrint('CHECK step=$step tz=${now.timeZoneName} now=$now');
    await setUpPrefs();

    switch (step) {
      case 'tz_write':
        app.main();
        await wait(tester, 3500);
        final container = containerOf(tester);
        final repo = container.read(dailyRecordRepositoryProvider);
        await repo.setStamp(now, 'calm',
            questionId: container.read(questionBankProvider).forDate(now).id);
        final all = await repo.getAll();
        debugPrint('CHECK records=${all.map((r) => '${r.dayKey}:${r.stamp}').toList()}');
        // 次の手順(別の時間帯)で同じ日を探すために残す
        await (await SharedPreferences.getInstance())
            .setString('check_tz_key', ymd(now));
        await shot(binding, tester, 'check_tz_write');

      case 'tz_read':
        app.main();
        await wait(tester, 3500);
        final repo = containerOf(tester).read(dailyRecordRepositoryProvider);
        final all = await repo.getAll();
        debugPrint('CHECK records=${all.map((r) => '${r.dayKey}:${r.stamp}').toList()}');
        final key = (await SharedPreferences.getInstance()).getString('check_tz_key');
        debugPrint('CHECK written key=$key today here=${ymd(now)}');
        expect(all.where((r) => r.dayKey == key).length, 1);
        expect(all.firstWhere((r) => r.dayKey == key).stamp, 'calm');
        await tapText(tester, '記録');
        await shot(binding, tester, 'check_tz_read_records');

      case 'open_error':
        final dir = await getApplicationDocumentsDirectory();
        final db = File('${dir.path}/default.isar');
        final backup = File('${dir.path}/default.isar.check-backup');
        if (db.existsSync()) db.renameSync(backup.path);
        db.writeAsStringSync('not an isar file');
        app.main();
        await wait(tester, 3500);
        expect(findText('もう一度試す'), findsOneWidget);
        await shot(binding, tester, 'check_open_error');
        db.deleteSync();
        if (backup.existsSync()) backup.renameSync(db.path);
        await tester.tap(findText('もう一度試す'));
        await wait(tester, 3500);
        expect(findText('もう一度試す'), findsNothing);
        await shot(binding, tester, 'check_open_error_retried');

      case 'widget':
        final day = DateTime(now.year, now.month, now.day - 3);
        await HomeWidget.setAppGroupId(WidgetSync.appGroup);
        await HomeWidget.saveWidgetData<String>(
            'pendingStamps',
            jsonEncode([
              {'d': ymd(day), 's': 'happy', 't': day.add(const Duration(hours: 9)).millisecondsSinceEpoch / 1000}
            ]));
        app.main();
        await wait(tester, 5000);
        final repo = containerOf(tester).read(dailyRecordRepositoryProvider);
        final record = await repo.getByDate(day);
        debugPrint('CHECK ${ymd(day)} stamp=${record?.stamp}');
        expect(record?.stamp, 'happy');
        debugPrint('CHECK pending after=${await HomeWidget.getWidgetData<String>('pendingStamps')}');
        await tapText(tester, '記録');
        await shot(binding, tester, 'check_widget_records');

      default:
        fail('STEP を指定する: tz_write・tz_read・open_error・widget');
    }
  });
}
