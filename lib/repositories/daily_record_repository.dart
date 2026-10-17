import 'package:isar/isar.dart';
import '../models/daily_record.dart';
import '../services/day_key_merge.dart';
import '../utils/date_only.dart';
import '../utils/day_key.dart';

/// 日記の記録の読み書き。日付はすべて dayKey(「yyyy-MM-dd」)で探す
/// (保存された DateTime は時刻の一点なので、端末のタイムゾーンが変わると日がずれる)
class DailyRecordRepository {
  DailyRecordRepository(this._isar);
  final Isar _isar;

  Future<DailyRecord?> getByDate(DateTime date) => _findByKey(dayKeyOf(date));

  Future<DailyRecord?> _findByKey(String key) =>
      _isar.dailyRecords.where().dayKeyEqualTo(key).findFirst();

  Future<List<DailyRecord>> getByMonth(int year, int month) {
    final (first, last) = monthDayKeyRange(year, month);
    return _isar.dailyRecords
        .where()
        .dayKeyBetween(first, last)
        .sortByDayKey()
        .findAll();
  }

  Future<List<DailyRecord>> getAll() {
    return _isar.dailyRecords.where().sortByDayKeyDesc().findAll();
  }

  Stream<List<DailyRecord>> watchByMonth(int year, int month) {
    final (first, last) = monthDayKeyRange(year, month);
    return _isar.dailyRecords
        .where()
        .dayKeyBetween(first, last)
        .sortByDayKey()
        .watch(fireImmediately: true);
  }

  /// その日の記録。無ければ作る(作るのは1回の書き込みの中で、読み直してから)
  Future<DailyRecord> getOrCreate(DateTime date) async {
    final record = await getByDate(date);
    if (record != null) return record;
    return _isar.writeTxn(() => _getOrCreateInTxn(date));
  }

  /// 書き込みの中で呼ぶ。読んでから作るまでの間にほかの書き込みが入らない
  /// (dayKey は一意の索引にできないので、1日1件はここで守る。万一2件あれば1つにまとめる)
  Future<DailyRecord> _getOrCreateInTxn(DateTime date) async {
    final key = dayKeyOf(date);
    final existing =
        await _isar.dailyRecords.where().dayKeyEqualTo(key).findAll();
    if (existing.length == 1) return existing.single;
    if (existing.length > 1) {
      final merged = mergeSameDayRecords(existing)..dayKey = key;
      await _isar.dailyRecords.deleteAll(
          [for (final r in existing) if (r.id != merged.id) r.id]);
      await _isar.dailyRecords.put(merged);
      return merged;
    }
    final record = newDailyRecordFor(date);
    await _isar.dailyRecords.put(record);
    return record;
  }

  /// その日の記録を読み、[change] で直して書く。読む・直す・書くを1回の書き込みの中で行う
  Future<DailyRecord> _update(
      DateTime date, void Function(DailyRecord record) change) {
    return _isar.writeTxn(() async {
      final record = await _getOrCreateInTxn(date);
      change(record);
      record.updatedAt = DateTime.now();
      await _isar.dailyRecords.put(record);
      return record;
    });
  }

  Future<void> save(DailyRecord record) async {
    record.updatedAt = DateTime.now();
    if (record.dayKey.isEmpty) record.dayKey = legacyDayKey(record.date);
    await _isar.writeTxn(() => _isar.dailyRecords.put(record));
  }

  /// 今日の問いのスタンプを残す。null で取り消し
  ///
  /// [onlyIf] を渡すと、書き込みの中で今の記録(無ければ null)を見て、false なら何もしない。
  /// 書いたら true を返す
  Future<bool> setStamp(DateTime date, String? stampId,
      {required String questionId,
      DateTime? at,
      bool Function(DailyRecord? current)? onlyIf}) {
    return _isar.writeTxn(() async {
      if (onlyIf != null) {
        final current = await _findByKey(dayKeyOf(date));
        if (!onlyIf(current)) return false;
      }
      final record = await _getOrCreateInTxn(date);
      record
        ..stamp = stampId
        ..stampAt = at ?? DateTime.now()
        ..morningQuestionId = questionId
        ..updatedAt = DateTime.now();
      await _isar.dailyRecords.put(record);
      return true;
    });
  }

  /// 今日の問いへの答えを残す。空なら null で保存する
  Future<void> setAnswer(DateTime date, String? answer,
      {required String questionId}) async {
    final trimmed = answer?.trim();
    await _update(date, (record) {
      record
        ..answer = (trimmed == null || trimmed.isEmpty) ? null : answer
        ..morningQuestionId = questionId;
    });
  }

  /// 1年前の同じ日の記録(2月29日は前年の2月28日)
  Future<DailyRecord?> getOneYearAgo(DateTime date) =>
      getByDate(oneYearAgo(dateOnly(date)));

  Future<void> delete(int id) async {
    await _isar.writeTxn(() => _isar.dailyRecords.delete(id));
  }
}
