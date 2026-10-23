import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:isar/isar.dart';
import 'package:life_counter/main.dart' as app;
import 'package:life_counter/models/bucket_item.dart';
import 'package:life_counter/models/daily_record.dart';
import 'package:life_counter/models/important_person.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'helpers.dart';

/// LC-30 v1.1.4 までに東京で入れた誕生日のまま、時間帯を西(ニューヨークなど)にして開く
///
/// 東京で 1990-01-01 を選んだときの保存(ミリ秒)と、大切な人(1960 年の明日の月日に生まれ、最後に会った日 2026-10-01)を置いて、
/// 今日・人生の大切な人・設定を撮る。直す前(feat/1.1.4)と後(fix/LC-30)で同じテストを流して見比べる。
/// 時間帯は flutter drive の前に `SIMCTL_CHILD_TZ=America/New_York` で渡す(ログの TZ= で確かめる)。
/// 画像の名前の頭に SHOT_PREFIX(before_・after_)を付ける
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  const prefix = String.fromEnvironment('SHOT_PREFIX', defaultValue: 'lc30_');

  // 東京の 0:00 を時刻の一点にしたもの(= UTC の前日 15:00)
  int tokyoMidnight(int y, int m, int d) => DateTime.utc(
    y,
    m,
    d,
  ).subtract(const Duration(hours: 9)).millisecondsSinceEpoch;

  testWidgets('LC-30 west time zone', (tester) async {
    final now = DateTime.now();
    // 大切な人の誕生日は「明日」の月日にする。1日前にずれると今日が誕生日になり、歳が1つ上に見える
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    // ignore: avoid_print
    print('LC30 TZ=${now.timeZoneName} offset=${now.timeZoneOffset}');

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);
    await prefs.setInt('birth_date', tokyoMidnight(1990, 1, 1));
    await prefs.setString('gender', 'male');
    // v1.1.4 までの保存と同じにする(新しいキーと済みの印は無い状態)
    await prefs.remove('birth_day_key');
    await prefs.remove('birth_day_key_migrated_v1');

    final dir = await getApplicationDocumentsDirectory();
    final isar =
        Isar.getInstance() ??
        await Isar.open([
          DailyRecordSchema,
          ImportantPersonSchema,
          BucketItemSchema,
        ], directory: dir.path);
    await isar.writeTxn(() async {
      await isar.importantPersons.clear();
      await isar.importantPersons.put(
        ImportantPerson()
          ..nickname = '母'
          ..birthDate = DateTime.fromMillisecondsSinceEpoch(
            tokyoMidnight(1960, tomorrow.month, tomorrow.day),
          )
          ..gender = Gender.female
          ..lastMetDate = DateTime.fromMillisecondsSinceEpoch(
            tokyoMidnight(2026, 10, 1),
          ),
      );
    });

    app.main();
    await wait(tester, 3500);
    await scrollToTop(tester);
    await shot(binding, tester, '${prefix}01_today');

    await tapText(tester, '人生');
    await tapText(tester, '大切な人');
    await shot(binding, tester, '${prefix}02_people');
    await tapVisible(tester, find.byIcon(CupertinoIcons.chevron_right).first);
    await shot(binding, tester, '${prefix}03_person_detail');

    await tester.tap(findText('設定').last);
    await shot(binding, tester, '${prefix}04_settings');

    // ignore: avoid_print
    print(
      'LC30 birth_day_key=${prefs.getString('birth_day_key')} '
      'migrated=${prefs.getBool('birth_day_key_migrated_v1')}',
    );
  });
}
