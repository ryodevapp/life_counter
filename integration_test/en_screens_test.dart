import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:life_counter/main.dart' as app;
import 'package:shared_preferences/shared_preferences.dart';
import 'helpers.dart';

/// 英語の端末(米国)として、主な画面を撮る
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('english screens', (tester) async {
    binding.platformDispatcher.localeTestValue = const Locale('en', 'US');
    binding.platformDispatcher.localesTestValue = const [Locale('en', 'US')];
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);
    await prefs.setInt('birth_date', DateTime(1992, 4, 1).millisecondsSinceEpoch);
    await prefs.setString('gender', 'male');

    app.main();
    await wait(tester, 3500);
    await tester.tap(find.text('Calm'));
    await wait(tester);
    await tester.enterText(find.byType(TextField).first,
        'My grandfather\'s star atlas. Every summer we turned its pages on the porch, then went out to find the constellations.');
    await wait(tester, 2600);
    FocusManager.instance.primaryFocus?.unfocus();
    await wait(tester);
    await shot(binding, tester, 'en_01_today');

    await tester.tap(find.byIcon(CupertinoIcons.book));
    await wait(tester);
    await shot(binding, tester, 'en_02_journal');

    await tester.tap(find.byIcon(CupertinoIcons.heart));
    await wait(tester);
    await shot(binding, tester, 'en_03_life_you');
    await tapText(tester, 'Bucket list');
    await shot(binding, tester, 'en_04_bucket');

    await tester.tap(find.byIcon(CupertinoIcons.gear_alt));
    await wait(tester);
    await shot(binding, tester, 'en_05_settings');
  });
}
