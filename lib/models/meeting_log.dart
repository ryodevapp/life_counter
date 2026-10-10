import 'package:isar/isar.dart';

part 'meeting_log.g.dart';

/// 家族と会えた日の記録
@collection
class MeetingLog {
  Id id = Isar.autoIncrement;

  @Index()
  late int personId;

  @Index()
  late DateTime date;

  String? note;

  DateTime createdAt = DateTime.now();
}
