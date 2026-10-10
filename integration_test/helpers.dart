import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

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
}

Future<void> tapText(WidgetTester tester, String text) async {
  await tester.tap(find.text(text).last);
  await wait(tester);
}

Finder byText(String text) => find.byWidgetPredicate(
    (w) => w is Text && (w.data ?? '').contains(text));
