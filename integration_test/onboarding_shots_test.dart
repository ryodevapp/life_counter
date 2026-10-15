import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:life_counter/main.dart' as app;
import 'helpers.dart';

/// はじめての人が見る画面を撮る(アプリを入れ直した状態で実行する)
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('onboarding screens', (tester) async {
    app.main();
    await wait(tester, 3500);
    await shot(binding, tester, 'o_01_welcome');
    await tapText(tester, 'はじめる');
    await shot(binding, tester, 'o_02_birth');
  });
}
