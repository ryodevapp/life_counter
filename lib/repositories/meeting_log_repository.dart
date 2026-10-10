import 'package:isar/isar.dart';
import '../models/meeting_log.dart';

class MeetingLogRepository {
  MeetingLogRepository(this._isar);
  final Isar _isar;

  Stream<List<MeetingLog>> watchAll() {
    return _isar.meetingLogs
        .where()
        .sortByDateDesc()
        .watch(fireImmediately: true);
  }

  Future<int> count() => _isar.meetingLogs.count();

  Future<void> add(MeetingLog log) async {
    await _isar.writeTxn(() => _isar.meetingLogs.put(log));
  }

  Future<void> delete(int id) async {
    await _isar.writeTxn(() => _isar.meetingLogs.delete(id));
  }

  /// 家族を外したときは、その人の記録も外す
  Future<void> deleteByPerson(int personId) async {
    await _isar.writeTxn(
        () => _isar.meetingLogs.filter().personIdEqualTo(personId).deleteAll());
  }
}
