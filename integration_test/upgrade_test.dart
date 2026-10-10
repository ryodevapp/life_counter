import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:life_counter/main.dart' as app;
import 'package:shared_preferences/shared_preferences.dart';
import 'helpers.dart';

/// v1.0.2 のデータがある端末に、v2.0 を上書きしたときの確認
/// (先に v1.0.2 で日記と大切な人を作っておく。アプリは消さずに実行する)
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('upgrade from v1.0.2', (tester) async {
    app.main();
    await wait(tester, 3500);
    final prefs = await SharedPreferences.getInstance();
    // ignore: avoid_print
    print('UPG legacy_user=${prefs.getBool('legacy_user')} onboarding=${prefs.getBool('onboarding_completed')}');
    expect(prefs.getBool('legacy_user'), isTrue);

    // 大切な人が家族タブに出る
    expect(byText('旧版の母'), findsWidgets);
    await shot(binding, tester, '40_upgrade_family');

    // 日記が記録タブに出る。案内の一行も出る
    await tester.tap(find.text('記録').last);
    await wait(tester, 1500);
    expect(byText('旧版の日記:家族が元気でいること'), findsOneWidget);
    expect(byText('以前の日記は、この一覧に残っています'), findsOneWidget);
    await shot(binding, tester, '41_upgrade_records');
  });
}
