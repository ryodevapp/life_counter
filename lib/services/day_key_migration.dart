import 'package:isar/isar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/daily_record.dart';
import 'day_key_merge.dart';
import '../utils/prefs_keys.dart';

/// 古い記録の dayKey を埋める(v1.1.1、1回だけ)
///
/// 保存されている date を今の地域の時刻で読んで日を決める。同じ日の記録が2つ以上あれば
/// [mergeSameDayRecords] で1つにまとめる(文は消さない)。
/// 失敗したら印を付けないので、次の起動でやり直す
Future<void> migrateDayKeys(Isar isar, SharedPreferences prefs) async {
  if (prefs.getBool(PrefsKeys.dayKeyMigrated) ?? false) return;
  await isar.writeTxn(() async {
    final all = await isar.dailyRecords.where().findAll();
    final plan = planDayKeyMigration(all);
    // 一意の索引にぶつからないよう、先に消してから書く
    await isar.dailyRecords.deleteAll(plan.deleteIds);
    await isar.dailyRecords.putAll(plan.put);
  });
  await prefs.setBool(PrefsKeys.dayKeyMigrated, true);
}
