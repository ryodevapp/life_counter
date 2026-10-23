import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_counter/l10n/phrase_break.dart';
import 'package:life_counter/l10n/l10n.dart';
import 'package:life_counter/views/shared/action_buttons.dart';
import 'package:life_counter/views/shared/app_toast.dart';

import '../support/phrase_model.dart';
import '../support/text_truncation.dart';

/// 削除の確認の小窓とトーストも PhraseText で折る(1.1.4、decisions 2026-10-23 夕方)。
/// CupertinoAlertDialog は中身の高さを内在の大きさで測るので、LayoutBuilder を使うと落ちる。幅を渡して組めるか
void main() {
  setUpAll(() => PhraseBreak.model = loadPhraseModel());
  tearDownAll(() => PhraseBreak.model = null);
  for (final scale in [1.0, 1.35, 3.1]) {
    testWidgets('削除の確認の小窓 ×$scale で落ちず・切れない', (tester) async {
      tester.view.physicalSize = const Size(402, 874);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = scale;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpWidget(MaterialApp(
        locale: const Locale('ja'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) => Column(children: [
              TextButton(
                onPressed: () => showDeleteConfirmation(context,
                    title: '「高校の友だちと富士山に登る」を削除しますか？'),
                child: const Text('dialog'),
              ),
              TextButton(
                onPressed: () =>
                    AppToast.success(context, 'もうバケットリストにあります'),
                child: const Text('toast'),
              ),
            ]),
          ),
        ),
      ));
      await tester.tap(find.text('toast'));
      await tester.pump(const Duration(milliseconds: 500));
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('dialog'), warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 500));
      expect(tester.takeException(), isNull);
      expect(_shown('高校の友だちと'), findsWidgets);
      expectNoTruncatedText(tester, where: '×$scale');
    });
  }
}

/// 文節の印(U+2060)と語の折り目(U+200B)を外して、文を含む Text を探す
Finder _shown(String text) => find.byWidgetPredicate((w) =>
    w is Text &&
    (w.data ?? w.textSpan?.toPlainText() ?? '')
        .replaceAll(RegExp('[\u2060\u200B]'), '')
        .contains(text));
