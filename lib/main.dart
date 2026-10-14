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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ja_JP');
  await NotificationService.initialize();

  final prefs = await SharedPreferences.getInstance();
  final questionBank = await QuestionBank.load();
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
