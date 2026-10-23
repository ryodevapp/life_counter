import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:life_counter/l10n/phrase_break.dart';
import 'package:life_counter/main.dart' as app;
import 'package:life_counter/providers/isar_provider.dart';
import 'package:life_counter/providers/question_bank_provider.dart';
import 'package:life_counter/providers/today_reload_provider.dart';
import 'package:life_counter/utils/date_only.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'helpers.dart';

/// 利用者の書いた文を文節で折る前と後を撮る(LC 日本語の改行。1.1.4)。
/// やりたいことの項目・入力欄の案内・今日の画面の「1年前の答え」・記録の一覧(1年前の今日と各日の答え)。
/// 40字より長い答えは文節で折らず OS の標準の折り(PhraseBreak.maxLength。decisions 2026-10-23 夕方)。
/// --dart-define=PHRASE=off で折る前(辞書を外す)。名前は phrase_(on か off)_(画面)(shotSuffix)
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  const phrase = String.fromEnvironment('PHRASE', defaultValue: 'on');

  const answers = [
    '両親と温泉に行きたい。父が前から行きたがっていた宿があって、今年こそ一緒に行けたらいいな。',
    '高校の友だちと「40歳になったら一緒に富士山に登ろう」と決めたこと。そろそろ計画を立てたい。',
    '母がくれた料理の本。よく作ったページに母の字のメモがあって、開くたびに実家の台所を思い出す。',
  ];
  const lastYear = '実家の庭の草取り。父と並んで黙々と手を動かす時間が好きで、帰省するたびに一緒にやっている。';
  const buckets = ['家族で温泉に行く', '高校の友だちと富士山に登る', '両親と温泉旅行に行く', 'オーロラを見る'];

  testWidgets('phrase break shots ($phrase)', (tester) async {
    binding.platformDispatcher.localeTestValue = const Locale('ja', 'JP');
    binding.platformDispatcher.localesTestValue = const [Locale('ja', 'JP')];
    applyShotConditions(binding);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);
    await prefs.setInt('birth_date', DateTime(1988, 6, 12).millisecondsSinceEpoch);
    await prefs.setString('gender', 'male');

    app.main();
    await wait(tester, 3500);
    if (phrase == 'off') PhraseBreak.model = null;

    final container = ProviderScope.containerOf(
        tester.element(find.byType(MaterialApp).first));
    final records = container.read(dailyRecordRepositoryProvider);
    final bank = container.read(questionBankProvider);
    final today = dateOnly(DateTime.now());
    for (var i = 0; i < answers.length; i++) {
      final day = today.subtract(Duration(days: i + 1));
      final q = bank.forDate(day).id;
      await records.setStamp(day, 'calm', questionId: q);
      await records.setAnswer(day, answers[i], questionId: q);
    }
    // 1年前の今日に、今日と同じ問いへ答えておく(今日の画面と記録の上に出る)
    final ago = oneYearAgo(today);
    await records.setAnswer(ago, lastYear, questionId: bank.forDate(today).id);
    final bucketRepo = container.read(bucketItemRepositoryProvider);
    // 何度撮っても同じ項目が増えないように、無いものだけ足す(前の撮影のデータは消さない)
    final have = (await bucketRepo.getAll()).map((b) => b.title).toSet();
    for (final b in buckets.where((b) => !have.contains(b))) {
      await bucketRepo.add(b);
    }
    container.read(todayReloadProvider.notifier).state++;
    await wait(tester, 1500);

    final name = 'phrase_$phrase';
    // 1. 今日(1年前の答え)
    await shotAt(binding, tester, findText(lastYear).last, '${name}_today$shotSuffix');

    // 2. 記録(1年前の今日と、各日の答え)
    await tester.tap(find.byIcon(CupertinoIcons.book));
    await wait(tester, 1200);
    await shot(binding, tester, '${name}_journal$shotSuffix');
    await shotAt(binding, tester, findText(answers[1]).last,
        '${name}_journal_answers$shotSuffix');

    // 3. バケットリスト(項目と入力欄の案内)
    await tester.tap(find.byIcon(CupertinoIcons.heart));
    await wait(tester);
    await tapText(tester, 'バケットリスト');
    await shot(binding, tester, '${name}_bucket$shotSuffix');
    await shotAt(binding, tester, findText(buckets.last).last,
        '${name}_bucket_items$shotSuffix');
    await shotAt(binding, tester, find.byType(TextField).last,
        '${name}_bucket_hint$shotSuffix');
  });
}
