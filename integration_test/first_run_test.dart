import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:life_counter/main.dart' as app;
import 'package:shared_preferences/shared_preferences.dart';
import 'helpers.dart';

/// オンボーディング直後: 家族の登録画面が自動で開き、登録後にウィジェットの置き方が出る
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('first run guide', (tester) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('birth_date', DateTime(1986, 5, 1).millisecondsSinceEpoch);
    await prefs.setBool('onboarding_completed', true);
    await prefs.setBool('notification_enabled', false);
    await prefs.setBool('first_run_guide', true);

    app.main();
    await wait(tester, 3500);
    expect(find.text('家族を追加'), findsOneWidget);
    await shot(binding, tester, '30_first_form');
    await tester.enterText(find.byType(EditableText).first, 'お母さん');
    await wait(tester);
    await tapText(tester, '追加');
    await wait(tester, 2000);
    expect(find.text('ホーム画面に、家族を'), findsOneWidget);
    await shot(binding, tester, '31_widget_guide');
    await tapText(tester, 'わかった');
    await shot(binding, tester, '32_first_family');
  });
}
