import 'dart:io';
import 'dart:ui';
import 'package:flutter/widgets.dart' show EditableText;
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:isar/isar.dart';
import 'package:life_counter/main.dart' as app;
import 'package:life_counter/models/important_person.dart';
import 'package:life_counter/models/meeting_log.dart';
import 'package:life_counter/services/photo_store.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'helpers.dart';

/// ストア用の画面写真。実際に数か月使った状態を作って撮る(写真は抽象的なグラデーション)
Future<void> _gradient(String path, Color a, Color b) async {
  final rec = PictureRecorder();
  final c = Canvas(rec);
  const r = Rect.fromLTWH(0, 0, 600, 600);
  c.drawRect(r, Paint()..shader = Gradient.linear(r.topLeft, r.bottomRight, [a, b]));
  c.drawCircle(const Offset(420, 180), 90, Paint()..color = const Color(0x55FFFFFF));
  final img = await rec.endRecording().toImage(600, 600);
  final bytes = await img.toByteData(format: ImageByteFormat.png);
  await File(path).writeAsBytes(bytes!.buffer.asUint8List());
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('store screens', (tester) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('birth_date', DateTime(1987, 6, 1).millisecondsSinceEpoch);
    await prefs.setString('gender', 'male');
    await prefs.setBool('onboarding_completed', true);
    await prefs.setBool('notification_enabled', false);
    await prefs.setBool('pro_purchased', true);
    await prefs.setBool('legacy_diary_banner_dismissed', true);
    await prefs.setBool('family_tip_dismissed', true);

    app.main();
    await wait(tester, 3000);
    final dir = PhotoStore.dirPath!;
    await _gradient('$dir/s1.png', const Color(0xFFE8B98F), const Color(0xFF7A8FA6));
    await _gradient('$dir/s2.png', const Color(0xFFF2D3A2), const Color(0xFFB8784E));
    await _gradient('$dir/s3.png', const Color(0xFFA9C6B8), const Color(0xFF5E7F96));
    await _gradient('$dir/s4.png', const Color(0xFFF0C6C0), const Color(0xFF9A7BA6));

    final now = DateTime.now();
    final isar = Isar.getInstance()!;
    final mom = ImportantPerson()
      ..nickname = 'お母さん'
      ..birthDate = DateTime(1959, 11, 3)
      ..gender = Gender.female
      ..relation = Relation.parent
      ..meetingFrequency = 2
      ..photoFile = 's2.png'
      ..nextMeetDate = now.add(const Duration(days: 12));
    final dad = ImportantPerson()
      ..nickname = 'お父さん'
      ..birthDate = DateTime(1956, 4, 20)
      ..gender = Gender.male
      ..relation = Relation.parent
      ..meetingFrequency = 2;
    final kid = ImportantPerson()
      ..nickname = 'ゆい'
      ..birthDate = DateTime(now.year - 6, 2, 10)
      ..relation = Relation.child
      ..liveTogetherUntilAge = 18
      ..afterLeavingFrequency = 4;
    await isar.writeTxn(() async {
      await isar.importantPersons.putAll([mom, dad, kid]);
    });
    MeetingLog log(ImportantPerson p, int daysAgo, ContactKind k, [String? note, String? photo]) =>
        MeetingLog()
          ..personId = p.id
          ..date = DateTime(now.year, now.month, now.day).subtract(Duration(days: daysAgo))
          ..kind = k
          ..note = note
          ..photoFile = photo;
    await isar.writeTxn(() async {
      await isar.meetingLogs.putAll([
        log(mom, 1, ContactKind.call),
        log(dad, 4, ContactKind.message, '庭の柿の写真が届いた'),
        log(mom, 8, ContactKind.video, 'ゆいがピアノを聴かせた'),
        log(kid, 20, ContactKind.met, '運動会。リレーで1位', 's3.png'),
        log(mom, 60, ContactKind.met, 'お盆に帰省。母と温泉、よく笑ってた', 's1.png'),
        log(dad, 60, ContactKind.met, '父と釣り。小さいアジが3匹', 's4.png'),
        log(mom, 150, ContactKind.met, '母の日に、みんなで食事'),
      ]);
    });
    await wait(tester, 2500);
    await shot(binding, tester, 's01_family');
    await tester.tap(find.text('記録').last);
    await wait(tester, 1500);
    await shot(binding, tester, 's02_records');
    await tester.tap(byText('ふりかえりを見る').first);
    await shot(binding, tester, 's03_review');
    await tester.pageBack();
    await wait(tester);
    await tester.tap(find.text('家族').last);
    await wait(tester, 1200);
    await tester.tap(find.text('お母さん').first);
    await shot(binding, tester, 's04_detail');
    expect(find.byType(EditableText), findsNothing);
  });
}
