import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app.dart';
import 'services/notification_service.dart';
import 'services/question_bank.dart';
import 'models/bucket_item.dart';
import 'models/daily_record.dart';
import 'models/important_person.dart';
import 'providers/isar_provider.dart';
import 'providers/question_bank_provider.dart';
import 'providers/user_settings_provider.dart';
import 'services/life_calculator.dart';
import 'utils/app_language.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // 日本語と英語の日付の書き方を読み込む
  await initializeDateFormatting();
  await NotificationService.initialize();

  // 平均の目安は、住んでいる国(端末の地域)の値で計算する
  LifeCalculator.regionCode =
      WidgetsBinding.instance.platformDispatcher.locale.countryCode;
  final prefs = await SharedPreferences.getInstance();
  final questionBank = await QuestionBank.load(languageCode: appLanguageCode());
  final dir = await getApplicationDocumentsDirectory();
  final isar = await Isar.open(
    [DailyRecordSchema, ImportantPersonSchema, BucketItemSchema],
    directory: dir.path,
  );

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
