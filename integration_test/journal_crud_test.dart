import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:life_counter/main.dart' as app;
import 'package:life_counter/models/daily_record.dart';
import 'package:life_counter/providers/isar_provider.dart';
import 'package:life_counter/providers/today_reload_provider.dart';
import 'package:life_counter/views/shared/app_card.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'helpers.dart';

/// 記録タブ(一覧・カレンダー)で、記録を作る・見る・直す・消すをひととおり試す
/// 画面で操作し、保存された中身をデータベースから読んで確かめる。日本語の端末として動かす
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  DateTime day(int ago) {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day - ago);
  }

  testWidgets('journal CRUD', (tester) async {
    binding.platformDispatcher.localeTestValue = const Locale('ja', 'JP');
    binding.platformDispatcher.localesTestValue = const [Locale('ja', 'JP')];
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    await prefs.setBool('onboarding_completed', true);
    await prefs.setInt('birth_date', DateTime(1990, 1, 1).millisecondsSinceEpoch);

    app.main();
    await wait(tester, 3500);
    final container =
        ProviderScope.containerOf(tester.element(find.byType(MaterialApp).first));
    final repo = container.read(dailyRecordRepositoryProvider);

    // 前の実行の記録を消してから、見本を入れる
    for (final r in await repo.getAll()) {
      await repo.delete(r.id);
    }
    Future<void> put(int ago, {String? stamp, String? answer, String? gratitude}) async {
      final r = DailyRecord()..date = day(ago);
      r.stamp = stamp;
      r.answer = answer;
      r.gratitude = gratitude;
      await repo.save(r);
    }

    await put(3, stamp: 'happy', answer: '答え3日前');
    await put(2, answer: '答え2日前');
    await put(5, stamp: 'sad', answer: '答え5日前');
    await put(10, gratitude: '古い版の感謝');

    Finder cardWith(String text) => find.ancestor(
        of: byText(text).first, matching: find.byType(AppCard));
    Future<void> editCardWith(String text) async {
      final pencil = find.descendant(
          of: cardWith(text), matching: find.byIcon(CupertinoIcons.pencil));
      await tester.ensureVisible(pencil);
      await wait(tester, 300);
      await tester.tap(pencil);
      await wait(tester);
    }

    Future<DailyRecord?> at(int ago) => repo.getByDate(day(ago));

    // 開いている編集のカード(「保存」があるカード)の中だけを探す
    Finder editCard() => find.ancestor(
        of: find.text('保存'), matching: find.byType(AppCard)).first;
    Finder inEdit(Finder f) => find.descendant(of: editCard(), matching: f);
    Future<void> pickMood(String label) async {
      await tester.tap(inEdit(find.text(label)).first);
      await wait(tester, 300);
    }
    Future<void> typeAnswer(String text) async {
      await tester.enterText(inEdit(find.byType(TextField)).first, text);
      await wait(tester, 300);
      FocusManager.instance.primaryFocus?.unfocus();
      await wait(tester, 300);
    }

    await tapText(tester, '記録');
    await wait(tester, 1200);

    // 見る: 一覧に気分の札・答え・古い版の欄が出る
    expect(byText('答え3日前'), findsOneWidget);
    expect(find.descendant(of: cardWith('答え3日前'), matching: find.text('うれしい')),
        findsOneWidget, reason: '一覧の気分の札');
    expect(byText('古い版の感謝'), findsOneWidget);
    await shot(binding, tester, 'j_01_list');

    // 直す(一覧): 気分を「おだやか」に、答えを書き換える
    await editCardWith('答え3日前');
    expect(find.text('気分'), findsOneWidget, reason: '編集に気分の欄がある');
    await shot(binding, tester, 'j_02_edit');
    await pickMood('おだやか');
    await typeAnswer('答え3日前(直した)');
    await tapText(tester, '保存');
    var r = await at(3);
    expect(r?.stamp, 'calm');
    expect(r?.answer, '答え3日前(直した)');
    expect(find.descendant(of: cardWith('答え3日前(直した)'), matching: find.text('おだやか')),
        findsOneWidget);

    // 直す: キャンセルすると元のまま
    await editCardWith('答え3日前(直した)');
    await pickMood('かなしい');
    await typeAnswer('保存しない文');
    await tapText(tester, 'キャンセル');
    r = await at(3);
    expect(r?.stamp, 'calm');
    expect(r?.answer, '答え3日前(直した)');

    // 消す: 同じ顔をもう一度押すと気分を取り消せる
    await editCardWith('答え3日前(直した)');
    await pickMood('おだやか');
    await tapText(tester, '保存');
    r = await at(3);
    expect(r?.stamp, isNull);
    expect(r?.answer, '答え3日前(直した)');

    // 消す: 答えを空にして保存すると、一覧から消える
    await editCardWith('答え2日前');
    await typeAnswer('');
    await tapText(tester, '保存');
    expect(byText('答え2日前'), findsNothing);
    expect((await at(2))?.answer, isNull);

    // 消す: 編集の右下のゴミ箱で記録ごと消える(古い版の記録)
    await editCardWith('古い版の感謝');
    final trash = inEdit(find.byIcon(CupertinoIcons.trash));
    await tester.ensureVisible(trash);
    await wait(tester, 300);
    await tester.tap(trash);
    await wait(tester);
    await shot(binding, tester, 'j_03_delete_confirm');
    await tester.tap(find.text('削除').last);
    await wait(tester, 1200);
    expect(await at(10), isNull);
    expect(byText('古い版の感謝'), findsNothing);
    await shot(binding, tester, 'j_04_list_after');

    // 消す: 一覧で左へスワイプして消す(確かめてから)
    await tester.drag(cardWith('答え3日前(直した)'), const Offset(-500, 0));
    await wait(tester, 1000);
    await shot(binding, tester, 'j_04b_swipe_confirm');
    await tester.tap(find.text('削除').last);
    await wait(tester, 1200);
    expect(await at(3), isNull);
    expect(byText('答え3日前(直した)'), findsNothing);

    // 見る(カレンダー): 選んだ日に気分の札が出る
    await tapText(tester, 'カレンダー');
    await wait(tester, 1000);
    await tester.tap(find.text('${day(5).day}').last);
    await wait(tester, 1200);
    expect(byText('答え5日前'), findsOneWidget);
    expect(find.descendant(of: cardWith('答え5日前'), matching: find.text('かなしい')),
        findsOneWidget, reason: 'カレンダーの気分の札');
    await shot(binding, tester, 'j_05_calendar');

    // 直す(カレンダー): 気分を「ふつう」に
    await editCardWith('答え5日前');
    await pickMood('ふつう');
    await tapText(tester, '保存');
    expect((await at(5))?.stamp, 'neutral');
    expect(find.descendant(of: cardWith('答え5日前'), matching: find.text('ふつう')),
        findsOneWidget);

    // 作る(カレンダー): 記録のない日を選んで、気分と答えを残す
    await tester.tap(find.text('${day(7).day}').last);
    await wait(tester, 1200);
    expect(find.text('記録なし'), findsOneWidget);
    await editCardWith('記録なし');
    await pickMood('うれしい');
    await typeAnswer('新しく書いた答え');
    await tapText(tester, '保存');
    r = await at(7);
    expect(r?.stamp, 'happy');
    expect(r?.answer, '新しく書いた答え');
    await shot(binding, tester, 'j_06_calendar_created');

    // 直す(今日): カレンダーで今日を直すと、今日の画面にも出る
    await tester.tap(find.text('${day(0).day}').last);
    await wait(tester, 1200);
    await editCardWith('記録なし');
    await pickMood('つかれた');
    await typeAnswer('今日の答え');
    await tapText(tester, '保存');
    expect((await at(0))?.stamp, 'tired');
    container.read(todayReloadProvider.notifier).state++;
    await tapText(tester, '今日');
    await wait(tester, 1500);
    final todayField = tester.widget<TextField>(find.byType(TextField).first);
    expect(todayField.controller?.text, '今日の答え');
    await shot(binding, tester, 'j_07_today_after_edit');

    // 一覧に戻ると、作った日と今日の分が並ぶ
    await tapText(tester, '記録');
    await tapText(tester, 'リスト');
    await wait(tester, 1000);
    expect(byText('新しく書いた答え'), findsOneWidget);
    expect(byText('今日の答え'), findsOneWidget);
    await shot(binding, tester, 'j_08_list_final');
  });
}
