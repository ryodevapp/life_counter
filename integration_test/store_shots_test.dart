import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:life_counter/main.dart' as app;
import 'package:life_counter/models/important_person.dart';
import 'package:life_counter/providers/isar_provider.dart';
import 'package:life_counter/providers/question_bank_provider.dart';
import 'package:life_counter/providers/today_reload_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'helpers.dart';

/// App Store のスクリーンショット用に、見本のデータを入れて5画面を撮る
/// --dart-define=LANG=en で英語(米国)、なければ日本語。撮影日は 2026-10-16 の前提で答えを合わせてある
/// --dart-define=THEME=dark で夜、--dart-define=TEXT=max で最大の文字(helpers.dart。名前の後ろに _dark・_ax5)
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  const lang = String.fromEnvironment('LANG', defaultValue: 'ja');
  final en = lang == 'en';

  // 日付 → (気分, 日本語の答え, 英語の答え)。それぞれの日の問いにかみ合う答え
  final entries = <DateTime, (String, String, String)>{
    DateTime(2026, 10, 12): (
      'calm',
      '両親と温泉に行きたい。父が前から行きたがっていた宿があって、今年こそ一緒に行けたらいいな。',
      'Take my parents to a hot spring. Dad has wanted to stay at one inn for years, and I\'d love to go this year.'
    ),
    DateTime(2026, 10, 13): (
      'tired',
      'よくがんばってるよ。今週は仕事がつまっていたけど、夜は早く寝られた。',
      'You\'re doing fine. A packed week at work, but I still got to bed early.'
    ),
    DateTime(2026, 10, 14): (
      'happy',
      '高校の友だちと「40歳になったら一緒に富士山に登ろう」と決めたこと。40歳まで2年、そろそろ計画を立てたい。',
      'With a high school friend: "Let\'s climb Mt. Fuji when we turn 40." Two years to go, so it\'s time to plan.'
    ),
    DateTime(2026, 10, 15): (
      'happy',
      '母がくれた料理の本。よく作ったページに母の字のメモがあって、開くたびに実家の台所を思い出す。',
      'The cookbook my mom gave me. Her handwritten notes on the pages I cook most always take me back to her kitchen.'
    ),
  };
  const todayJa = '実家の庭の草取り。父と並んで黙々と手を動かす時間が好きで、帰省するたびに一緒にやっている。';
  const todayEn =
      'Weeding my parents\' garden. I love working side by side with my dad in silence, so we do it every time I visit.';

  testWidgets('store screenshots', (tester) async {
    if (en) {
      binding.platformDispatcher.localeTestValue = const Locale('en', 'US');
      binding.platformDispatcher.localesTestValue = const [Locale('en', 'US')];
    } else {
      binding.platformDispatcher.localeTestValue = const Locale('ja', 'JP');
      binding.platformDispatcher.localesTestValue = const [Locale('ja', 'JP')];
    }
    applyShotConditions(binding);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);
    await prefs.setInt('birth_date', DateTime(1988, 6, 12).millisecondsSinceEpoch);
    await prefs.setString('gender', 'male');

    app.main();
    await wait(tester, 3500);

    // 見本のデータを入れる
    final container = ProviderScope.containerOf(
        tester.element(find.byType(MaterialApp).first));
    final records = container.read(dailyRecordRepositoryProvider);
    final bank = container.read(questionBankProvider);
    for (final e in entries.entries) {
      final q = bank.forDate(e.key).id;
      await records.setStamp(e.key, e.value.$1, questionId: q);
      await records.setAnswer(e.key, en ? e.value.$3 : e.value.$2,
          questionId: q);
    }
    final people = container.read(importantPersonRepositoryProvider);
    final mom = ImportantPerson()
      ..nickname = en ? 'Mom' : '母'
      ..birthDate = DateTime(1964, 5, 10)
      ..gender = Gender.female
      ..meetingFrequency = 4
      ..lastMetDate = DateTime(2026, 8, 14);
    final dad = ImportantPerson()
      ..nickname = en ? 'Dad' : '父'
      ..birthDate = DateTime(1962, 3, 2)
      ..gender = Gender.male
      ..meetingFrequency = 4
      ..lastMetDate = DateTime(2026, 8, 14);
    await people.add(mom);
    await people.add(dad);
    final buckets = container.read(bucketItemRepositoryProvider);
    await buckets.add(en ? 'Take a trip to a hot spring with my parents' : '両親と温泉旅行に行く');
    await buckets.add(en ? 'See the northern lights' : 'オーロラを見る');
    await buckets.add(en ? 'Climb Mt. Fuji with a high school friend' : '高校の友だちと富士山に登る');
    await buckets.add(en ? 'Get a family photo taken at a studio' : '家族で写真館の写真を撮る');
    final all = await buckets.getAll();
    await buckets.toggleDone(all
        .firstWhere((b) => b.title.contains(en ? 'family photo' : '写真館'))
        .id);
    container.read(todayReloadProvider.notifier).state++;
    await wait(tester, 1500);

    // 1. 今日
    await tester.tap(find.text(en ? 'Calm' : 'おだやか'));
    await wait(tester);
    await tester.enterText(find.byType(TextField).first, en ? todayEn : todayJa);
    await wait(tester, 2600);
    FocusManager.instance.primaryFocus?.unfocus();
    await wait(tester);
    await shot(binding, tester, 'store_${lang}_1_today$shotSuffix');

    // 2. 記録
    await tester.tap(find.byIcon(CupertinoIcons.book));
    await wait(tester, 1200);
    await shot(binding, tester, 'store_${lang}_2_journal$shotSuffix');

    // 3. 大切な人
    await tester.tap(find.byIcon(CupertinoIcons.heart));
    await wait(tester);
    await tapText(tester, en ? 'People' : '大切な人');
    await shot(binding, tester, 'store_${lang}_3_people$shotSuffix');

    // 4. バケットリスト
    await tapText(tester, en ? 'Bucket list' : 'バケットリスト');
    await shot(binding, tester, 'store_${lang}_4_bucket$shotSuffix');

    // 5. あなた
    await tapText(tester, en ? 'You' : 'あなた');
    await shot(binding, tester, 'store_${lang}_5_you$shotSuffix');
  });
}
