import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:life_counter/main.dart' as app;
import 'package:shared_preferences/shared_preferences.dart';
import 'helpers.dart';

/// はじめての人が見る4画面を撮る。--dart-define=LANG=en で英語
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  const lang = String.fromEnvironment('LANG', defaultValue: 'ja');
  final en = lang == 'en';

  testWidgets('onboarding screens', (tester) async {
    binding.platformDispatcher.localeTestValue =
        en ? const Locale('en', 'US') : const Locale('ja', 'JP');
    binding.platformDispatcher.localesTestValue =
        en ? const [Locale('en', 'US')] : const [Locale('ja', 'JP')];
    // はじめての人と同じ状態から始める
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    app.main();
    await wait(tester, 3500);
    await shot(binding, tester, 'o_${lang}_1_welcome');
    await tapText(tester, en ? 'Get Started' : 'はじめる');
    await shot(binding, tester, 'o_${lang}_2_birth');
    await tapText(tester, en ? 'Next' : '次へ');
    await wait(tester, 2500);
    await shot(binding, tester, 'o_${lang}_3_life_days');
    await tapText(tester, en ? 'Next' : '次へ');
    await shot(binding, tester, 'o_${lang}_4_question');
    await tapText(tester, en ? 'Not Now' : '今はしない');
    await wait(tester, 2500);
    await shot(binding, tester, 'o_${lang}_5_today');
  });
}
