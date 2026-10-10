import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:life_counter/main.dart' as app;
import 'helpers.dart';

/// 初回起動の画面(通知の許可を求める直前まで)
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('onboarding screens', (tester) async {
    app.main();
    await wait(tester, 3000);
    await shot(binding, tester, '01_welcome');
    await tapText(tester, 'はじめる');
    await shot(binding, tester, '02_birth');
    await tapText(tester, '次へ');
    for (var i = 0; i < 3; i++) {
      await wait(tester, 2500);
      await shot(binding, tester, '03_step${i + 1}');
      if (i < 2) await tapText(tester, '次へ');
    }
  });
}
