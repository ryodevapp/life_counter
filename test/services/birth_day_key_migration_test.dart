import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_counter/models/important_person.dart';
import 'package:life_counter/providers/user_settings_provider.dart';
import 'package:life_counter/services/birth_day_key_migration.dart';
import 'package:life_counter/services/morning_schedule.dart';
import 'package:life_counter/utils/day_key.dart';
import 'package:life_counter/utils/prefs_keys.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// LC-30 誕生日・大切な人の日付を時間帯に左右されない形で持つ
///
/// 時間帯は [legacyDayKey] の localOffset で切り替えて確かめる。
/// 端末の時間帯そのものを変えた確かめは `TZ=America/New_York flutter test` などで、
/// このファイル全体を東京・ロンドン・ニューヨーク・ホノルルで流す(どの時間帯でも通る書き方にしてある)
void main() {
  // 時間帯ごとの時差(10 月と 1 月の両方)
  const zones = <String, List<Duration>>{
    'Asia/Tokyo': [Duration(hours: 9)],
    'Europe/London': [Duration.zero, Duration(hours: 1)],
    'America/New_York': [Duration(hours: -5), Duration(hours: -4)],
    'Pacific/Honolulu': [Duration(hours: -10)],
  };

  // v1.1.4 までに東京で 1990-01-01 を選んだときに保存されるミリ秒(東京の 0:00 = UTC 前日 15:00)
  final tokyoBirthMillis = DateTime.utc(1989, 12, 31, 15).millisecondsSinceEpoch;
  // ニューヨークで 1990-01-01 を選んだとき(UTC 05:00)
  final nyBirthMillis = DateTime.utc(1990, 1, 1, 5).millisecondsSinceEpoch;
  // ホノルルで 1985-07-20 を選んだとき(UTC 10:00)
  final honoluluBirthMillis = DateTime.utc(1985, 7, 20, 10).millisecondsSinceEpoch;

  Future<SharedPreferences> prefsWith(Map<String, Object> values) async {
    SharedPreferences.setMockInitialValues(values);
    return SharedPreferences.getInstance();
  }

  group('古い誕生日(ミリ秒)を、どの時間帯で読んでも同じ日にする', () {
    for (final entry in zones.entries) {
      for (final offset in entry.value) {
        test('${entry.key} (${offset.inHours}h)', () async {
          final prefs = await prefsWith({PrefsKeys.birthDate: tokyoBirthMillis});
          expect(readBirthDate(prefs, localOffset: offset), DateTime(1990, 1, 1));

          final ny = DateTime.fromMillisecondsSinceEpoch(nyBirthMillis);
          expect(legacyDayKey(ny, localOffset: offset), '1990-01-01');
          // ホノルル(UTC-10)の 0:00 は UTC+14(キリバス)の翌日 0:00 と同じ時刻の一点で、
          // 古い値だけでは見分けられない。東京で読むと時差の近い +14 を採る(legacyDayKey の限界、LC-23 から同じ)
          if (offset < const Duration(hours: 9)) {
            final hnl = DateTime.fromMillisecondsSinceEpoch(honoluluBirthMillis);
            expect(legacyDayKey(hnl, localOffset: offset), '1985-07-20');
          }
        });
      }
    }

    test('dayKey があれば、それだけで決まる(端末の時間帯を使わない)', () async {
      final prefs = await prefsWith({
        PrefsKeys.birthDayKey: '1990-01-01',
        // 古い値がずれていても dayKey を使う
        PrefsKeys.birthDate: DateTime.utc(1980, 6, 6).millisecondsSinceEpoch,
      });
      for (final offsets in zones.values) {
        for (final o in offsets) {
          expect(readBirthDate(prefs, localOffset: o), DateTime(1990, 1, 1));
        }
      }
    });

    test('端末の今の時間帯で読んでも、人生◯日目が東京と同じ', () async {
      // `TZ=... flutter test` で時間帯を変えて流したときに効く
      final prefs = await prefsWith({PrefsKeys.birthDate: tokyoBirthMillis});
      final birth = readBirthDate(prefs)!;
      expect(dayKeyOf(birth), '1990-01-01');
      final expected = DateTime.utc(2026, 10, 23)
              .difference(DateTime.utc(1990, 1, 1))
              .inDays +
          1;
      expect(lifeDaysOn(birth, DateTime(2026, 10, 23)), expected);
    });
  });

  group('古い保存からの移し替え(自分の誕生日)', () {
    test('古いミリ秒から dayKey を書き、古い値は残す', () async {
      final prefs = await prefsWith({PrefsKeys.birthDate: tokyoBirthMillis});
      final wrote = await migrateBirthDayKeyPrefs(prefs,
          localOffset: const Duration(hours: -5));
      expect(wrote, isTrue);
      expect(prefs.getString(PrefsKeys.birthDayKey), '1990-01-01');
      expect(prefs.getInt(PrefsKeys.birthDate), tokyoBirthMillis);
    });

    test('dayKey が既にあれば書き直さない', () async {
      final prefs = await prefsWith({
        PrefsKeys.birthDate: tokyoBirthMillis,
        PrefsKeys.birthDayKey: '1990-01-01',
      });
      expect(await migrateBirthDayKeyPrefs(prefs), isFalse);
      expect(prefs.getString(PrefsKeys.birthDayKey), '1990-01-01');
    });

    test('誕生日がまだ無ければ何もしない', () async {
      final prefs = await prefsWith({});
      expect(await migrateBirthDayKeyPrefs(prefs), isFalse);
      expect(prefs.containsKey(PrefsKeys.birthDayKey), isFalse);
    });
  });

  group('読めない値', () {
    test('ミリ秒でない値は触らずに残し、誕生日は無いものとして出す(落ちない)', () async {
      final prefs = await prefsWith({
        PrefsKeys.birthDate: 'not-a-number',
        PrefsKeys.onboardingCompleted: true,
      });
      expect(await migrateBirthDayKeyPrefs(prefs), isFalse);
      expect(prefs.getString(PrefsKeys.birthDate), 'not-a-number');
      expect(prefs.containsKey(PrefsKeys.birthDayKey), isFalse);
      expect(readBirthDate(prefs), isNull);
      // 誕生日が読めなくても、ほかの設定(はじめの案内を済ませたか)は読める
      final c = ProviderContainer(overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ]);
      addTearDown(c.dispose);
      final s = c.read(userSettingsProvider);
      expect(s.birthDate, isNull);
      expect(s.onboardingCompleted, isTrue);
    });

    test('DateTime の範囲を超えるミリ秒も残す', () async {
      const huge = 9000000000000000; // 8.64e15 を超える
      final prefs = await prefsWith({PrefsKeys.birthDate: huge});
      expect(await migrateBirthDayKeyPrefs(prefs), isFalse);
      expect(prefs.getInt(PrefsKeys.birthDate), huge);
      expect(readBirthDate(prefs), isNull);
    });

    test('dayKey が壊れていれば、古い値から日を決めて今までどおり出す', () async {
      final prefs = await prefsWith({
        PrefsKeys.birthDayKey: '1990-02-30',
        PrefsKeys.birthDate: tokyoBirthMillis,
      });
      expect(readBirthDate(prefs, localOffset: const Duration(hours: -5)),
          DateTime(1990, 1, 1));
      // 移し替えで正しい dayKey に書き直す(古い値は残る)
      await migrateBirthDayKeyPrefs(prefs, localOffset: const Duration(hours: -5));
      expect(prefs.getString(PrefsKeys.birthDayKey), '1990-01-01');
      expect(prefs.getInt(PrefsKeys.birthDate), tokyoBirthMillis);
    });
  });

  group('1回だけ走る(済みの印)', () {
    test('1回目は走って印を付け、2回目は何もしない', () async {
      final prefs = await prefsWith({PrefsKeys.birthDate: tokyoBirthMillis});
      var personRuns = 0;
      Future<void> persons() async => personRuns++;

      expect(await migrateBirthDayKeysOnce(prefs, persons), isTrue);
      expect(prefs.getBool(PrefsKeys.birthDayKeyMigrated), isTrue);
      expect(prefs.getString(PrefsKeys.birthDayKey), isNotNull);

      // 2回目: dayKey を消しても書き直さない(走っていない)
      await prefs.remove(PrefsKeys.birthDayKey);
      expect(await migrateBirthDayKeysOnce(prefs, persons), isFalse);
      expect(prefs.containsKey(PrefsKeys.birthDayKey), isFalse);
      expect(personRuns, 1);
    });

    test('大切な人の移し替えで失敗したら印を付けず、次の起動でやり直す', () async {
      final prefs = await prefsWith({PrefsKeys.birthDate: tokyoBirthMillis});
      await expectLater(
          migrateBirthDayKeysOnce(prefs, () async => throw StateError('isar')),
          throwsStateError);
      expect(prefs.getBool(PrefsKeys.birthDayKeyMigrated), isNull);
      expect(await migrateBirthDayKeysOnce(prefs, () async {}), isTrue);
    });
  });

  group('大切な人', () {
    ImportantPerson legacyPerson({DateTime? lastMet}) => ImportantPerson()
      ..nickname = 'はは'
      ..birthDate = DateTime.fromMillisecondsSinceEpoch(tokyoBirthMillis)
      ..lastMetDate = lastMet;

    for (final entry in zones.entries) {
      final offset = entry.value.first;
      test('古い誕生日と最後に会った日を ${entry.key} でも同じ日に移す', () {
        // 東京で 2026-10-01 を選んだ最後に会った日(UTC 前日 15:00)
        final met = DateTime.utc(2026, 9, 30, 15);
        final p = legacyPerson(lastMet: met);
        expect(fillPersonDayKeys(p, localOffset: offset), isTrue);
        expect(p.birthDayKey, '1990-01-01');
        expect(p.lastMetDayKey, '2026-10-01');
        // 古い値は残す
        expect(p.birthDate.millisecondsSinceEpoch, tokyoBirthMillis);
        expect(p.lastMetDate, met);
        expect(p.birthDay, DateTime(1990, 1, 1));
        expect(p.lastMetDay, DateTime(2026, 10, 1));
        // 2回目は変えない
        expect(fillPersonDayKeys(p, localOffset: const Duration(hours: 14)),
            isFalse);
        expect(p.birthDayKey, '1990-01-01');
      });
    }

    test('最後に会った日が無ければ null のまま', () {
      final p = legacyPerson();
      fillPersonDayKeys(p);
      expect(p.lastMetDayKey, isNull);
      expect(p.lastMetDay, isNull);
    });

    test('新しく入れた日は dayKey と古い形の両方に書く', () {
      final p = ImportantPerson()
        ..nickname = 'ちち'
        ..setBirthDay(DateTime(1960, 3, 31, 13, 5))
        ..setLastMetDay(DateTime(2026, 8, 15));
      expect(p.birthDayKey, '1960-03-31');
      expect(p.birthDate, DateTime(1960, 3, 31));
      expect(p.lastMetDayKey, '2026-08-15');
      p.setLastMetDay(null);
      expect(p.lastMetDayKey, isNull);
      expect(p.lastMetDate, isNull);
    });

    test('dayKey が壊れていれば古い値から日を決める', () {
      final p = legacyPerson()..birthDayKey = 'broken';
      expect(dayFromKeyOrLegacy(p.birthDayKey, p.birthDate,
              localOffset: const Duration(hours: -10)),
          DateTime(1990, 1, 1));
    });
  });

  group('設定に誕生日を入れる', () {
    test('dayKey と古いミリ秒の両方に書き、読み直しても同じ日', () async {
      final prefs = await prefsWith({});
      final c = ProviderContainer(overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ]);
      addTearDown(c.dispose);
      await c
          .read(userSettingsProvider.notifier)
          .setBirthDateAndGender(DateTime(1992, 4, 1, 9, 30), Gender.female);
      expect(prefs.getString(PrefsKeys.birthDayKey), '1992-04-01');
      expect(prefs.getInt(PrefsKeys.birthDate),
          DateTime(1992, 4, 1).millisecondsSinceEpoch);
      expect(c.read(userSettingsProvider).birthDate, DateTime(1992, 4, 1));
      c.invalidate(userSettingsProvider);
      expect(c.read(userSettingsProvider).birthDate, DateTime(1992, 4, 1));
    });
  });
}
