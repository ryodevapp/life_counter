import 'package:flutter_test/flutter_test.dart';
import 'package:life_counter/models/meeting_log.dart';
import 'package:life_counter/services/contact_stats.dart';

MeetingLog log(int person, DateTime d, ContactKind k) => MeetingLog()
  ..personId = person
  ..date = d
  ..kind = k;

void main() {
  final now = DateTime(2026, 10, 20);
  final logs = [
    log(1, DateTime(2026, 10, 3), ContactKind.call),
    log(1, DateTime(2026, 10, 3, 20), ContactKind.message), // 同じ日は1日
    log(1, DateTime(2026, 10, 10), ContactKind.met),
    log(1, DateTime(2026, 8, 14), ContactKind.met),
    log(2, DateTime(2026, 10, 12), ContactKind.video),
  ];

  test('今月つながった日は、同じ日を1日と数える', () {
    expect(ContactStats.connectedThisMonth(logs, 1, now: now), 2);
  });
  test('今年会えた日は「会えた」だけ', () {
    expect(ContactStats.metThisYear(logs, 1, now: now), 2);
  });
  test('家族全体', () {
    expect(ContactStats.familyConnectedThisMonth(logs, now: now), 3);
    expect(ContactStats.familyMetThisYear(logs, now: now), 2);
  });
  test('既存の記録(つながり方なし)は「会えた」', () {
    expect(MeetingLog().kind, ContactKind.met);
  });
}
