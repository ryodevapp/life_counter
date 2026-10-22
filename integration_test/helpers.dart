import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/common.dart';
import 'package:integration_test/integration_test.dart';

import '../test/support/text_truncation.dart';

/// アニメーションが止まらない画面があるので、pumpAndSettle の代わりに時間で進める
Future<void> wait(WidgetTester tester, [int ms = 800]) async {
  for (var i = 0; i < ms ~/ 100; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> shot(IntegrationTestWidgetsFlutterBinding binding,
    WidgetTester tester, String name) async {
  await wait(tester, 1200);
  await binding.takeScreenshot(name);
  recordTruncatedText(binding, tester, name);
}

/// 撮るたびに、文字が「…」や行数の上限で切れていないかを見る(test/support/text_truncation.dart)。
/// 1枚目で止めずに最後まで撮り、テストの終わりに切れた所を全部並べて失敗にする。
/// 同じ文が何枚にも写るときは、最初に見つけた画像の名前で1回だけ出す。
/// 終わりの片付け(addTearDown)での失敗は flutter drive の合否に入らない(テストの本体の結果しか見ない)ので、
/// binding.results にも失敗を足す(足さないと「All tests passed.」のまま終わる。10/23 に確かめた)
void recordTruncatedText(IntegrationTestWidgetsFlutterBinding binding,
    WidgetTester tester, String name) {
  var pending = _truncations;
  if (pending == null) {
    pending = _truncations = {};
    addTearDown(() {
      final found = _truncations!;
      _truncations = null;
      if (found.isEmpty) return;
      final message =
          '文字が切れています(${found.length}箇所)。画像の名前・文・切れ方・文字の大きさ・位置(左,上 幅×高さ)\n'
          '${found.values.map((v) => '  - $v').join('\n')}';
      binding.results['文字の切れ(${binding.results.length})'] =
          Failure('文字の切れ', message);
      fail(message);
    });
  }
  for (final t in findTruncatedText(tester)) {
    pending.putIfAbsent(t.summary, () => '$name $t');
  }
}

Map<String, String>? _truncations;

/// find.text と同じだが、行を折らせない印(U+2060)を無視して比べる。
/// 日本語の短い語には印が入っている(lib/l10n/l10n.dart の keepTogether)ので、find.text では見つからない
Finder findText(String text) => find.byWidgetPredicate((w) {
      // find.text と同じく Text と入力欄だけを見る(Text の中にできる RichText は数えない)
      final data = w is Text
          ? (w.data ?? w.textSpan?.toPlainText())
          : w is EditableText
              ? w.controller.text
              : null;
      return data != null && data.replaceAll('\u2060', '') == text;
    }, description: 'text "$text"');

Future<void> tapText(WidgetTester tester, String text) async {
  // 小さい画面では画面外にあることがあるので、見える位置まで送ってから押す
  await tester.ensureVisible(findText(text).last);
  await wait(tester, 400);
  await tester.tap(findText(text).last);
  await wait(tester);
}

/// tapText の Finder 版(記号や読み上げ名で探すもの)。見える位置まで送ってから押す
Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await wait(tester, 400);
  await tester.tap(finder);
  await wait(tester);
}

/// 縦のスクロールをすべていちばん上へ戻す。ドラッグで戻すと、キーボードが閉じる途中や
/// 最大の文字の長い画面で戻り切らず、上が切れた画像になる(10/19 の今日の画面)
Future<void> scrollToTop(WidgetTester tester) async {
  for (final s in tester.stateList<ScrollableState>(find.byType(Scrollable))) {
    if (s.position.axis == Axis.vertical) {
      s.position.jumpTo(s.position.minScrollExtent);
    }
  }
  await wait(tester);
}

/// 画面の下のほうにあるものを見える位置まで送って撮る(最大の文字では1画面に入らない)
Future<void> shotAt(IntegrationTestWidgetsFlutterBinding binding,
    WidgetTester tester, Finder finder, String name) async {
  await tester.ensureVisible(finder);
  await wait(tester);
  await shot(binding, tester, name);
}

Finder byText(String text) => find.byWidgetPredicate(
    (w) => w is Text && (w.data ?? '').contains(text));

// ---- 撮影の条件(2026-10-18 本人の決定。3アプリ共通の2段) ----
// 毎回: 昼夜・既定と最大の文字・iOS 27 / 出す前だけ: iOS 26・SE・透明度を下げる・ロック画面
// 昼夜と文字はここで決める(--dart-define=THEME=dark・--dart-define=TEXT=max)。
// OS と端末は起動するシミュレーターで決める(tools/shots.sh)。
// 透明度を下げるは Flutter に対応する値が無い。ロック画面のウィジェットは持たない

/// 昼(light。既定)か夜(dark)
const shotTheme = String.fromEnvironment('THEME', defaultValue: 'light');

/// 文字の大きさ。default(既定。1.0)か max(iOS のアクセシビリティの最大 AX5 の本文 53pt ÷ 17pt ≒ 3.1)
const shotText = String.fromEnvironment('TEXT', defaultValue: 'default');

/// AX5 の倍率
const maxTextScale = 3.1;

/// 撮影の条件を端末の値として入れる(app.main() の前に呼ぶ)
void applyShotConditions(IntegrationTestWidgetsFlutterBinding binding) {
  binding.platformDispatcher.platformBrightnessTestValue =
      shotTheme == 'dark' ? Brightness.dark : Brightness.light;
  binding.platformDispatcher.textScaleFactorTestValue =
      shotText == 'max' ? maxTextScale : 1.0;
}

/// 画像の名前の後ろに付ける条件(昼・既定の文字は空。ストアの名前を今のままにする)
String get shotSuffix =>
    '${shotTheme == 'dark' ? '_dark' : ''}${shotText == 'max' ? '_ax5' : ''}';
