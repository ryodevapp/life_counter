import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:life_counter/main.dart' as app;
import 'helpers.dart';

/// v1.0.2 のデータがある端末に、v1.1 を上書きしたときの確認
/// (先に v1.0.2 で、日記の「感謝していること」に「旧版の日記」、大切な人に「旧版の母」を作っておく。
///  アプリは消さずに、このテストを実行する)
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('upgrade from v1.0.2', (tester) async {
    app.main();
    await wait(tester, 3500);

    // 今日の画面が、問い1つの形で開く
    expect(byText('今日の問い'), findsWidgets);
    await shot(binding, tester, '40_upgrade_today');

    // 古い日記が記録タブに残っている
    await tapText(tester, '記録');
    expect(byText('旧版の日記'), findsWidgets);
    await shot(binding, tester, '41_upgrade_records');

    // 大切な人が人生タブに残っている
    await tapText(tester, '人生');
    await tapText(tester, '大切な人');
    expect(byText('旧版の母'), findsWidgets);
    await shot(binding, tester, '42_upgrade_people');

    // 朝の通知が、id 100〜159 の60件で入り直っている(v1.0 系の id 0 は無い)
    final pending = await FlutterLocalNotificationsPlugin().pendingNotificationRequests();
    final ids = pending.map((p) => p.id).toSet();
    expect(ids.contains(0), isFalse);
    expect(ids.where((id) => id >= 100 && id < 160).length, 60);
  });
}
