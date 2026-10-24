import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app.dart';
import 'l10n/phrase_break.dart';
import 'services/notification_service.dart';
import 'services/birth_day_key_migration.dart';
import 'services/day_key_migration.dart';
import 'services/question_bank.dart';
import 'models/bucket_item.dart';
import 'models/daily_record.dart';
import 'models/important_person.dart';
import 'providers/isar_provider.dart';
import 'providers/question_bank_provider.dart';
import 'providers/user_settings_provider.dart';
import 'services/life_calculator.dart';
import 'utils/app_language.dart';
import 'views/startup/data_open_error_app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // アプリに入れた書体のライセンス(OFL)を「ライセンス」の画面に出す
  LicenseRegistry.addLicense(() async* {
    final text = await rootBundle.loadString('assets/fonts/OFL.txt');
    yield LicenseEntryWithLineBreaks(['Cormorant Garamond'], text);
  });
  // 日本語と英語の日付の書き方を読み込む
  await initializeDateFormatting();
  await NotificationService.initialize();
  // 日本語を文節の途中で折らないための辞書(BudouX の ja。約17KB)
  await PhraseBreak.load();

  // 平均の目安は、住んでいる国(端末の地域)の値で計算する
  LifeCalculator.regionCode =
      WidgetsBinding.instance.platformDispatcher.locale.countryCode;
  final prefs = await SharedPreferences.getInstance();
  final questionBank = await QuestionBank.load(languageCode: appLanguageCode());
  await _start(prefs, questionBank);
}

Future<Isar> _openIsar() async {
  // 前回の試しで開けていれば、それを使う
  final opened = Isar.getInstance();
  if (opened != null) return opened;
  final dir = await getApplicationDocumentsDirectory();
  return Isar.open(
    [DailyRecordSchema, ImportantPersonSchema, BucketItemSchema],
    directory: dir.path,
  );
}

/// 記録を開いてアプリを始める。開けなければ、落とさずに「もう一度試す」の画面を出す
Future<void> _start(SharedPreferences prefs, QuestionBank questionBank) async {
  final Isar isar;
  try {
    isar = await _openIsar();
  } catch (e, st) {
    debugPrint('Isar open error: $e\n$st');
    runApp(DataOpenErrorApp(onRetry: () => _start(prefs, questionBank)));
    return;
  }

  // 古い記録に dayKey を入れる(1回だけ)。失敗しても始め、次の起動でやり直す
  try {
    await migrateDayKeys(isar, prefs);
  } catch (e, st) {
    debugPrint('dayKey migration error: $e\n$st');
  }
  // 誕生日・大切な人の日付を「yyyy-MM-dd」にする(1回だけ、LC-30)。失敗しても始め、次の起動でやり直す
  try {
    await migrateBirthDayKeys(isar, prefs);
  } catch (e, st) {
    debugPrint('birthDayKey migration error: $e\n$st');
  }

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        isarProvider.overrideWithValue(isar),
        questionBankProvider.overrideWithValue(questionBank),
      ],
      child: const LifeCounterApp(),
    ),
  );
}
