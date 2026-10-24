import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:home_widget/home_widget.dart';
import 'package:integration_test/integration_test.dart';
import 'package:isar/isar.dart';
import 'package:life_counter/main.dart' as app;
import 'package:life_counter/models/bucket_item.dart';
import 'package:life_counter/models/daily_record.dart';
import 'package:life_counter/models/important_person.dart';
import 'package:life_counter/services/widget_sync.dart';
import 'package:life_counter/utils/day_key.dart';
import 'package:life_counter/utils/prefs_keys.dart';
import 'package:life_counter/views/onboarding/onboarding_page.dart';
import 'package:life_counter/views/startup/data_open_error_app.dart';
import 'package:life_counter/views/tab/main_tab_view.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers.dart';

/// LC-21 新しい iPhone に移したとき、記録が戻るか(バックアップ・復元)
///
/// 2段で動かす(tools/lc21_transfer.sh が順に呼ぶ)。
/// - `--dart-define=LC21_PHASE=write`: 移す元の端末で、記録・設定・ウィジェットの共有のデータを書く
/// - (ホストで、アプリのデータの入れ物と App Group の入れ物を、バックアップの対象の所だけ別の端末へ写す)
/// - `--dart-define=LC21_PHASE=verify`: 移した先の端末で、本物の起動(main)から開き、全部そろうかを見る
///
/// 起動の時刻のずれ(書いてから確かめるまでに日をまたぐ)を避けるため、0:00 の前後では走らせない
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  const phase = String.fromEnvironment('LC21_PHASE');

  // 書く日(今日・昨日・400日前)と中身。確かめる側も同じ値で比べる
  final today = DateTime.now();
  DateTime daysAgo(int n) => DateTime(today.year, today.month, today.day - n);
  final expected = <String, String>{
    dayKeyOf(daysAgo(0)): 'LC21 今日の答え',
    dayKeyOf(daysAgo(1)): 'LC21 昨日の答え',
    dayKeyOf(daysAgo(400)): 'LC21 400日前の答え',
  };
  final birth = DateTime(1990, 4, 15);

  testWidgets('LC-21 phase=$phase', (tester) async {
    expect(phase, anyOf('write', 'verify'),
        reason: '--dart-define=LC21_PHASE=write か verify を付ける');
    final docs = await getApplicationDocumentsDirectory();
    final support = await getApplicationSupportDirectory();
    final caches = await getApplicationCacheDirectory();
    final tmp = await getTemporaryDirectory();
    // ホストの手順が場所を読めるように出す
    // ignore: avoid_print
    print('LC21_PATHS docs=${docs.path} support=${support.path} '
        'caches=${caches.path} tmp=${tmp.path}');

    if (phase == 'write') {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      await prefs.setInt(PrefsKeys.birthDate, birth.millisecondsSinceEpoch);
      await prefs.setString(PrefsKeys.gender, 'female');
      await prefs.setBool(PrefsKeys.onboardingCompleted, true);
      await prefs.setBool(PrefsKeys.notificationEnabled, false);
      await prefs.setInt(PrefsKeys.nightModeHour, 21);
      await prefs.setBool(PrefsKeys.dayKeyMigrated, true);

      // アプリの main と同じ場所・同じ型で開く
      final isar = await Isar.open(
        [DailyRecordSchema, ImportantPersonSchema, BucketItemSchema],
        directory: docs.path,
      );
      await isar.writeTxn(() async {
        await isar.clear();
        for (final e in expected.entries) {
          final r = newDailyRecordFor(parseDayKey(e.key)!)
            ..answer = e.value
            ..stamp = 'happy'
            ..stampAt = DateTime.now().subtract(const Duration(hours: 2));
          await isar.dailyRecords.put(r);
        }
        await isar.importantPersons.put(ImportantPerson()
          ..nickname = 'LC21 母'
          ..birthDate = DateTime(1960, 1, 2));
        await isar.bucketItems.put(BucketItem()..title = 'LC21 富士山に登る');
      });
      await isar.close();

      // ウィジェットで押して、まだアプリに取り込んでいないスタンプ(App Group に残っている分)
      await HomeWidget.setAppGroupId(WidgetSync.appGroup);
      await HomeWidget.saveWidgetData<String>(
          'pendingStamps',
          jsonEncode([
            {
              'd': dayKeyOf(daysAgo(0)),
              's': 'calm',
              't': DateTime.now().millisecondsSinceEpoch / 1000,
            }
          ]));

      // 記録のデータベースがバックアップの対象の場所にあること(Caches・tmp ではない)
      final dbFiles = docs.listSync().whereType<File>().map((f) => f.path).toList();
      // ignore: avoid_print
      print('LC21_DB_FILES $dbFiles');
      expect(dbFiles.any((p) => p.endsWith('/default.isar')), isTrue);
      expect(docs.path.contains('/Library/Caches'), isFalse);
      expect(docs.path.startsWith(tmp.path), isFalse);
      return;
    }

    // verify: 移した先で、利用者と同じく本物の起動から開く
    app.main();
    await wait(tester, 5000);

    // 開けない画面・はじめての画面ではなく、いつもの画面が出る
    expect(find.byType(DataOpenErrorApp), findsNothing);
    expect(find.byType(OnboardingPage), findsNothing);
    expect(find.byType(MainTabView), findsOneWidget);

    final isar = Isar.getInstance()!;
    final records = await isar.dailyRecords.where().findAll();
    final got = {for (final r in records) r.dayKey: r.answer};
    // ignore: avoid_print
    print('LC21_RESTORED records=$got');
    expect(got, expected);
    expect((await isar.importantPersons.where().findAll()).single.nickname,
        'LC21 母');
    expect((await isar.bucketItems.where().findAll()).single.title,
        'LC21 富士山に登る');

    // ウィジェットで押したスタンプ(App Group)も移って取り込まれている
    final todayRecord = records.firstWhere((r) => r.dayKey == dayKeyOf(daysAgo(0)));
    expect(todayRecord.stamp, 'calm');

    // 設定(UserDefaults)
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt(PrefsKeys.birthDate), birth.millisecondsSinceEpoch);
    expect(prefs.getBool(PrefsKeys.onboardingCompleted), isTrue);
    expect(prefs.getInt(PrefsKeys.nightModeHour), 21);
    // ignore: avoid_print
    print('LC21_OK');
  });
}
