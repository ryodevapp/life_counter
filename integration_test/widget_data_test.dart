import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_widget/home_widget.dart';
import 'package:integration_test/integration_test.dart';
import 'package:isar/isar.dart';
import 'package:life_counter/main.dart' as app;
import 'package:life_counter/models/important_person.dart';
import 'package:life_counter/models/meeting_log.dart';
import 'package:life_counter/services/photo_store.dart';
import 'package:life_counter/services/widget_sync.dart';
import 'package:life_counter/repositories/meeting_log_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'helpers.dart';

/// ウィジェットに渡るデータを調べる(Pro 購入済み・写真つき)
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('widget data with photos', (tester) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('birth_date', DateTime(1986, 5, 1).millisecondsSinceEpoch);
    await prefs.setBool('onboarding_completed', true);
    await prefs.setBool('notification_enabled', false);
    await prefs.setBool('pro_purchased', true);

    app.main();
    await wait(tester, 3000);

    final dir = PhotoStore.dirPath;
    // ignore: avoid_print
    print('DIAG photo dir = $dir');
    final recorder = PictureRecorder();
    Canvas(recorder).drawRect(const Rect.fromLTWH(0, 0, 64, 64), Paint()..color = const Color(0xFFB8784E));
    final img = await recorder.endRecording().toImage(64, 64);
    final png = (await img.toByteData(format: ImageByteFormat.png))!.buffer.asUint8List();
    await File('$dir/ptest.png').writeAsBytes(png);

    final isar = Isar.getInstance()!;
    final p = ImportantPerson()
      ..nickname = 'お母さん'
      ..birthDate = DateTime(1960, 1, 1)
      ..relation = Relation.parent
      ..meetingFrequency = 2
      ..photoFile = 'ptest.png'
      ..nextMeetDate = DateTime.now().add(const Duration(days: 5));
    await isar.writeTxn(() => isar.importantPersons.put(p));
    await isar.writeTxn(() => isar.meetingLogs.put(MeetingLog()
      ..personId = p.id
      ..date = DateTime.now().subtract(const Duration(days: 3))
      ..note = 'テスト'
      ..photoFile = 'ptest.png'));
    await wait(tester, 3000);

    for (final k in ['isPro', 'hasFamily', 'nextMeetName', 'nextMeetPhoto', 'nextMeetEpoch', 'memories']) {
      final v = await HomeWidget.getWidgetData<Object>(k);
      // ignore: avoid_print
      print('DIAG widget[$k] = ${k == 'memories' && v != null ? (jsonDecode('$v') as List).length : v}');
    }
    // ignore: avoid_print
    print('DIAG file exists = ${PhotoStore.file('ptest.png') != null}');
    final members = await HomeWidget.getWidgetData<String>('members');
    // ignore: avoid_print
    print('DIAG members = $members');

    // ウィジェットで「電話した」が押された状態を作り、取り込めるか
    final t = DateTime.now().millisecondsSinceEpoch / 1000;
    await HomeWidget.saveWidgetData<String>('pendingLogs', '[{"id":${p.id},"k":"call","t":$t}]');
    final before = await isar.meetingLogs.count();
    final n = await WidgetSync.importPending(MeetingLogRepository(isar));
    final after = await isar.meetingLogs.count();
    final last = (await isar.meetingLogs.where().findAll()).last;
    // ignore: avoid_print
    print('DIAG imported=$n before=$before after=$after kind=${last.kind}');
    expect(n, 1);
    expect(after, before + 1);
    expect(last.kind, ContactKind.call);
    expect(await HomeWidget.getWidgetData<String>('pendingLogs'), '[]');
    // 購入済み・写真つきのふりかえり
    await tester.tap(find.text('記録').last);
    await wait(tester, 1500);
    await tester.tap(byText('ふりかえりを見る').first);
    await shot(binding, tester, '24_review_pro');
  });
}
