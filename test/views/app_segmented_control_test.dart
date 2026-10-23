import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_counter/l10n/phrase_break.dart';
import 'package:life_counter/views/shared/app_segmented_control.dart';
import 'package:life_counter/views/shared/app_spacing.dart';

import '../support/phrase_model.dart';
import '../support/text_truncation.dart';

/// 切り替え(AppSegmentedControl)の名前が、どの文字の大きさでも切れないか(1.1.4、decisions 2026-10-23 夕方の②)。
/// 横に入らないときは縦に組み替える。テストの書体(FlutterTest)は1字が字の大きさと同じ幅の四角で、
/// 日本語の実際の幅に近い(撮影のテストで本物の幅も見る)
void main() {
  setUpAll(() => PhraseBreak.model = loadPhraseModel());
  tearDownAll(() => PhraseBreak.model = null);
  // iOS の本文 17pt の大きさの倍率: 標準・xxxLarge(標準の最大)・AX1〜AX5
  const scales = [1.0, 1.18, 1.35, 1.65, 1.94, 2.35, 2.76, 3.1];
  // iPhone SE・iPhone 17 Pro・iPad Pro 13
  const widths = {'SE': 375.0, '17 Pro': 402.0, 'iPad': 1032.0};
  const groups = {
    '人生': ['あなた', '大切な人', 'バケットリスト'],
    '記録': ['リスト', 'カレンダー'],
    'en': ['You', 'People', 'Bucket list'],
  };

  for (final g in groups.entries) {
    for (final w in widths.entries) {
      for (final s in scales) {
        testWidgets('${g.key} ${w.key} ×$s で名前が切れない', (tester) async {
          tester.view.physicalSize = Size(w.value, 1400);
          tester.view.devicePixelRatio = 1;
          tester.platformDispatcher.textScaleFactorTestValue = s;
          addTearDown(tester.view.reset);
          addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
          await tester.pumpWidget(MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
                child: AppSegmentedControl<int>(
                  items: [
                    for (var i = 0; i < g.value.length; i++)
                      SegmentItem(value: i, label: g.value[i]),
                  ],
                  selectedValue: 0,
                  onChanged: (_) {},
                ),
              ),
            ),
          ));
          await tester.pump();
          expectNoTruncatedText(tester, where: '${g.key} ${w.key} ×$s');
          expect(tester.takeException(), isNull);
          for (final label in g.value) {
            expect(_shown(label), findsOneWidget);
          }
        });
      }
    }
  }
}

/// 文節の印(U+2060)と語の折り目(U+200B)を外して、文を含む Text を探す
Finder _shown(String text) => find.byWidgetPredicate((w) =>
    w is Text &&
    (w.data ?? w.textSpan?.toPlainText() ?? '')
        .replaceAll(RegExp('[\u2060\u200B]'), '')
        .contains(text));
