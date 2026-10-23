import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/important_person.dart';
import '../utils/day_key.dart';
import '../utils/prefs_keys.dart';

/// v1.1.4 までの誕生日(ミリ秒)を時刻の一点に戻す。int でない・範囲外なら null
DateTime? legacyBirthInstant(Object? raw) {
  if (raw is! int) return null;
  try {
    return DateTime.fromMillisecondsSinceEpoch(raw);
  } catch (_) {
    return null;
  }
}

/// 保存されている自分の誕生日(その地域の 0:00)。
/// [PrefsKeys.birthDayKey] → 古いミリ秒を [legacyDayKey] で読む、の順。どちらも読めなければ null
DateTime? readBirthDate(SharedPreferences prefs, {Duration? localOffset}) {
  final key = prefs.get(PrefsKeys.birthDayKey);
  return dayFromKeyOrLegacy(
    key is String ? key : null,
    legacyBirthInstant(prefs.get(PrefsKeys.birthDate)),
    localOffset: localOffset,
  );
}

/// 自分の誕生日を dayKey にする。読めない古い値は触らずに残す。
/// 書いたら true
Future<bool> migrateBirthDayKeyPrefs(SharedPreferences prefs,
    {Duration? localOffset}) async {
  final existing = prefs.get(PrefsKeys.birthDayKey);
  if (existing is String && parseDayKey(existing) != null) return false;
  final legacy = legacyBirthInstant(prefs.get(PrefsKeys.birthDate));
  if (legacy == null) return false;
  await prefs.setString(
      PrefsKeys.birthDayKey, legacyDayKey(legacy, localOffset: localOffset));
  return true;
}

/// 大切な人の誕生日・最後に会った日の dayKey を、まだ無いものだけ古い値から埋める。
/// 変えたら true。古い値(birthDate・lastMetDate)はそのまま残す
bool fillPersonDayKeys(ImportantPerson p, {Duration? localOffset}) {
  var changed = false;
  final hasBirth = p.birthDayKey != null && parseDayKey(p.birthDayKey!) != null;
  if (!hasBirth) {
    p.birthDayKey = legacyDayKey(p.birthDate, localOffset: localOffset);
    changed = true;
  }
  final met = p.lastMetDate;
  final hasMet =
      p.lastMetDayKey != null && parseDayKey(p.lastMetDayKey!) != null;
  if (met != null && !hasMet) {
    p.lastMetDayKey = legacyDayKey(met, localOffset: localOffset);
    changed = true;
  }
  return changed;
}

/// 誕生日・大切な人の日付を dayKey に移す(LC-30、1回だけ)
///
/// 済んだら [PrefsKeys.birthDayKeyMigrated] を付け、2回目からは何もしない。
/// 途中で失敗したら印を付けないので、次の起動でやり直す(古い値は消さないので、やり直しても同じ結果)
Future<void> migrateBirthDayKeys(Isar isar, SharedPreferences prefs) =>
    migrateBirthDayKeysOnce(prefs, () async {
      await isar.writeTxn(() async {
        final all = await isar.importantPersons.where().findAll();
        final changed = all.where((p) => fillPersonDayKeys(p)).toList();
        if (changed.isNotEmpty) await isar.importantPersons.putAll(changed);
      });
    });

/// [migrateBirthDayKeys] の段取り(印を見る → 自分の誕生日 → 大切な人 → 印を付ける)。
/// 走ったら true、印があって何もしなかったら false
@visibleForTesting
Future<bool> migrateBirthDayKeysOnce(
    SharedPreferences prefs, Future<void> Function() migratePersons) async {
  if (prefs.getBool(PrefsKeys.birthDayKeyMigrated) ?? false) return false;
  await migrateBirthDayKeyPrefs(prefs);
  await migratePersons();
  await prefs.setBool(PrefsKeys.birthDayKeyMigrated, true);
  return true;
}
