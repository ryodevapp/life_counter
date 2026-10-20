import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:life_counter/main.dart' as app;
import 'package:life_counter/models/important_person.dart';
import 'package:life_counter/providers/isar_provider.dart';
import 'package:life_counter/views/startup/data_open_error_app.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'helpers.dart';

/// ふだんは出ない文言の画面を撮る(LC-27): 記録を開けないときの画面と、平均の目安を越えた人の一言
/// --dart-define=LANG=en で英語。THEME・TEXT は helpers.dart のとおり
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  const lang = String.fromEnvironment('LANG', defaultValue: 'ja');
  final en = lang == 'en';

  setUp(() {
    final locale = en ? const Locale('en', 'US') : const Locale('ja', 'JP');
    binding.platformDispatcher.localeTestValue = locale;
    binding.platformDispatcher.localesTestValue = [locale];
    applyShotConditions(binding);
  });

  // app.main より先に撮る(記録を開く前の画面なので、データベースは要らない)
  testWidgets('data open error', (tester) async {
    await tester.pumpWidget(DataOpenErrorApp(onRetry: () async {}));
    await shot(binding, tester, 'wording_${lang}_data_open_error$shotSuffix');
  });

  testWidgets('past average', (tester) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);
    await prefs.setInt('birth_date', DateTime(1935, 1, 1).millisecondsSinceEpoch);
    await prefs.setString('gender', 'male');

    app.main();
    await wait(tester, 3500);

    final container = ProviderScope.containerOf(
        tester.element(find.byType(MaterialApp).first));
    await container.read(importantPersonRepositoryProvider).add(
        ImportantPerson()
          ..nickname = en ? 'Mom' : '母'
          ..birthDate = DateTime(1930, 2, 1)
          ..gender = Gender.female
          ..meetingFrequency = 4
          ..lastMetDate = DateTime(2026, 8, 14));
    await wait(tester);

    await tester.tap(find.byIcon(CupertinoIcons.heart));
    await wait(tester);
    await tapText(tester, en ? 'People' : '大切な人');
    await shot(binding, tester, 'wording_${lang}_past_average_person$shotSuffix');
    await tapText(tester, en ? 'You' : 'あなた');
    await shot(binding, tester, 'wording_${lang}_past_average_self$shotSuffix');
  });
}
