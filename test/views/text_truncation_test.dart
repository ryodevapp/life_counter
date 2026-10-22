import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_counter/app.dart';
import 'package:life_counter/l10n/l10n.dart';
import 'package:life_counter/models/question.dart';
import 'package:life_counter/providers/user_settings_provider.dart';
import 'package:life_counter/views/shared/expandable_text.dart';
import 'package:life_counter/views/startup/data_open_error_app.dart';
import 'package:life_counter/views/today/today_question_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/text_truncation.dart';

/// 文字が「…」や行数の上限で切れていないか(標準の文字と最大の文字 AX5 の両方)。
/// テストの書体(FlutterTest)は実機の書体と幅が違うので、ここは目安。
/// 本物の幅で見るのは撮影のテスト(integration_test の shot が撮るたびに見る)
void main() {
  /// iOS の AX5(本文 53pt ÷ 17pt)。integration_test/helpers.dart の maxTextScale と同じ
  const ax5 = 3.1;
  const scales = {'標準の文字': 1.0, '最大の文字': ax5};

  /// iPhone 17 Pro(402×874pt)
  void phone(WidgetTester tester, double scale) {
    tester.view.physicalSize = const Size(1206, 2622);
    tester.view.devicePixelRatio = 3.0;
    tester.platformDispatcher.textScaleFactorTestValue = scale;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  }

  Widget host(String lang, Widget child) => MaterialApp(
    locale: Locale(lang),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: SingleChildScrollView(child: child)),
  );

  group('検査そのもの', () {
    testWidgets('「…」で切れた1行を見つけ、文と行数を出す', (tester) async {
      await tester.pumpWidget(
        host(
          'ja',
          const SizedBox(
            width: 100,
            child: Text(
              'とても長い文がここに入って一行には収まらない',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      );
      final found = findTruncatedText(tester);
      expect(found, hasLength(1));
      expect(found.single.text, 'とても長い文がここに入って一行には収まらない');
      expect(found.single.reason, contains('行数の上限 1 行'));
    });

    testWidgets('折り返さない文の横のはみ出しを見つける', (tester) async {
      await tester.pumpWidget(
        host(
          'ja',
          const SizedBox(
            width: 100,
            child: Text(
              '折り返さない長い文が幅からはみ出す',
              softWrap: false,
              overflow: TextOverflow.fade,
            ),
          ),
        ),
      );
      expect(findTruncatedText(tester).single.reason, contains('横のはみ出し'));
    });

    testWidgets('収まる文・縮めて1行にする文・「続きを読む」の畳んだ文は数えない', (tester) async {
      await tester.pumpWidget(
        host(
          'ja',
          SizedBox(
            width: 100,
            child: Column(
              children: [
                const Text('短い', maxLines: 1, overflow: TextOverflow.ellipsis),
                const FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text('縮めて一行に収める長い題の文', maxLines: 1),
                ),
                ExpandableText(
                  '畳んで続きを読むで広げる長い文。' * 10,
                  style: const TextStyle(fontSize: 14),
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ),
      );
      expect(findTruncatedText(tester), isEmpty);
    });
  });

  for (final lang in ['ja', 'en']) {
    scales.forEach((label, scale) {
      group('$lang・$label', () {
        testWidgets('はじめての案内(ようこそ・生年月日)', (tester) async {
          phone(tester, scale);
          tester.platformDispatcher.localeTestValue = Locale(lang);
          tester.platformDispatcher.localesTestValue = [Locale(lang)];
          addTearDown(tester.platformDispatcher.clearLocaleTestValue);
          addTearDown(tester.platformDispatcher.clearLocalesTestValue);
          SharedPreferences.setMockInitialValues({});
          final prefs = await SharedPreferences.getInstance();
          await tester.pumpWidget(
            ProviderScope(
              overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
              child: const LifeCounterApp(),
            ),
          );
          await tester.pump(const Duration(seconds: 1));
          expectNoTruncatedText(tester, where: 'ようこそ');

          final l = appLocalizationsFor(lang);
          await tester.ensureVisible(find.text(l.getStarted));
          await tester.tap(find.text(l.getStarted));
          await tester.pump(const Duration(seconds: 1));
          expectNoTruncatedText(tester, where: '生年月日');
        });

        for (final answer in ['', '京都']) {
          testWidgets('今日の気分と今日の問いのカード(答え「$answer」)', (tester) async {
            phone(tester, scale);
            await tester.pumpWidget(
              host(
                lang,
                Column(
                  children: [
                    MoodCard(selectedId: null, onSelect: (_) {}),
                    TodayQuestionCard(
                      question: const Question(
                        id: 'q2',
                        category: 'bucket',
                        text: '一度は行ってみたい場所は？',
                        dayOfYear: 2,
                      ),
                      answerController: TextEditingController(text: answer),
                      lastYearAnswer: '海を見に行った',
                      onAnswerChanged: (_) {},
                      onAddToBucket: () {},
                    ),
                  ],
                ),
              ),
            );
            await tester.pump(const Duration(seconds: 1));
            expectNoTruncatedText(tester, where: '今日');
          });
        }

        testWidgets('記録を開けないときの画面', (tester) async {
          phone(tester, scale);
          await tester.pumpWidget(
            MaterialApp(
              locale: Locale(lang),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: DataOpenErrorPage(onRetry: () async {}),
            ),
          );
          await tester.pump();
          expectNoTruncatedText(tester, where: '記録を開けない');
        });
      });
    });
  }
}
