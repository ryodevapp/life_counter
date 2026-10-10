import '../models/meeting_log.dart';

/// つながった日の集計（同じ日に何回つながっても1日と数える）
class ContactStats {
  ContactStats._();

  static int _days(Iterable<MeetingLog> logs) =>
      logs.map((l) => DateTime(l.date.year, l.date.month, l.date.day)).toSet().length;

  /// 今年、会えた日
  static int metThisYear(List<MeetingLog> logs, int personId, {DateTime? now}) {
    final y = (now ?? DateTime.now()).year;
    return _days(logs.where((l) =>
        l.personId == personId && l.kind == ContactKind.met && l.date.year == y));
  }

  /// 今月、つながった日（会えた・電話・ビデオ・メッセージ）
  static int connectedThisMonth(List<MeetingLog> logs, int personId, {DateTime? now}) {
    final n = now ?? DateTime.now();
    return _days(logs.where((l) =>
        l.personId == personId && l.date.year == n.year && l.date.month == n.month));
  }

  /// 今月、家族のだれかとつながった日
  static int familyConnectedThisMonth(List<MeetingLog> logs, {DateTime? now}) {
    final n = now ?? DateTime.now();
    return _days(logs.where((l) => l.date.year == n.year && l.date.month == n.month));
  }

  /// 今年、家族のだれかと会えた日
  static int familyMetThisYear(List<MeetingLog> logs, {DateTime? now}) {
    final y = (now ?? DateTime.now()).year;
    return _days(logs.where((l) => l.kind == ContactKind.met && l.date.year == y));
  }
}
