import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:life_counter/l10n/l10n.dart';
import 'package:life_counter/models/bucket_item.dart';
import 'package:life_counter/models/daily_record.dart';
import 'package:life_counter/models/question.dart';
import 'package:life_counter/models/stamp.dart';
import 'package:life_counter/services/morning_schedule.dart';
import 'package:life_counter/services/question_bank.dart';
import 'package:life_counter/services/record_export.dart';
import 'package:life_counter/utils/date_validator.dart';
import 'package:life_counter/views/today/today_question_card.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ja_JP');
    await initializeDateFormatting('en_US');
  });

  final ja = appLocalizationsFor('ja');
  final en = appLocalizationsFor('en');

  test('Japanese device → Japanese, any other language → English', () {
    expect(resolveAppLocale(const Locale('ja', 'JP')), const Locale('ja'));
    expect(resolveAppLocale(const Locale('en', 'US')), const Locale('en'));
    expect(resolveAppLocale(const Locale('fr')), const Locale('en'));
    expect(resolveAppLocale(null), const Locale('en'));
    expect(appLocalizationsFor('de').localeName, 'en');
  });

  test('mood labels resolve per language and ids stay the same', () {
    expect(stamps.map((s) => moodLabelOf(ja, s.id)),
        ['うれしい', 'おだやか', 'ふつう', 'つかれた', 'かなしい']);
    expect(stamps.map((s) => moodLabelOf(en, s.id)),
        ['Happy', 'Calm', 'Okay', 'Tired', 'Sad']);
    expect(stamps.map((s) => s.id), ['happy', 'calm', 'neutral', 'tired', 'sad']);
    expect(ja.moodQuestion, moodQuestion);
    expect(en.moodQuestion, 'How was your day?');
  });

  test('dates: Japanese keeps the current formats, English reads naturally', () {
    final fri = DateTime(2026, 10, 16);
    final thu = DateTime(2026, 10, 15);
    expect(formatFullDate(fri, 'ja'), '2026年10月16日（金）');
    expect(formatFullDate(fri, 'en'), 'Fri, Oct 16, 2026');
    expect(formatMonthDayWeekday(thu, 'ja'), '10月15日（木）');
    expect(formatMonthDayWeekday(thu, 'en'), 'Thu, Oct 15');
    expect(formatYearMonth(fri, 'ja'), '2026年10月');
    expect(formatYearMonth(fri, 'en'), 'October 2026');
    expect(formatDate(thu, 'ja'), '2026年10月15日');
    expect(en.bucketDoneOn(formatDate(thu, 'en')), 'Achieved Oct 15, 2026');
  });

  test('numbers and plurals', () {
    expect(ja.notificationTitle(12617), '人生 12,617日目');
    expect(en.notificationTitle(12617), 'Day 12,617 of your life');
    expect(en.aboutDays(1), 'About 1 day');
    expect(en.aboutDays(9000), 'About 9,000 days');
    expect(ja.aboutDays(9000), '約 9,000 日');
    expect(en.monthMoodItem('Happy', 1), 'Happy, 1 day');
    expect(en.monthMoodItem('Calm', 3), 'Calm, 3 days');
    expect(ja.monthMoodItem('うれしい', 3), 'うれしい3日');
  });

  test('English copy never talks about death or days left', () {
    final words = ['death', 'die', 'dying', 'days left', 'remaining', 'life expectancy'];
    final texts = [
      en.welcomeBody,
      en.daysEstimateUnit(2),
      en.healthyDaysLabel,
      en.pastAverageSelf,
      en.pastAveragePerson,
      en.onboardingDaysAhead,
      en.notificationTitle(100),
      en.statYearsAhead,
    ];
    for (final t in texts) {
      for (final w in words) {
        expect(t.toLowerCase().contains(w), isFalse, reason: t);
      }
    }
  });

  test('notification titles in English', () {
    final bank = QuestionBank([
      for (var d = 1; d <= 365; d++)
        Question(id: 'q$d', category: 'self', text: 'Q$d', dayOfYear: d),
    ]);
    final items = buildMorningSchedule(
      now: DateTime(2026, 10, 15, 6),
      birthDate: DateTime(1992, 4, 1),
      hour: 7,
      minute: 0,
      bank: bank,
      days: 1,
      languageCode: 'en',
    );
    expect(items.single.title, startsWith('Day '));
    expect(items.single.title, endsWith(' of your life'));
  });

  test('export headings in English', () {
    final bank = QuestionBank([
      for (var d = 1; d <= 365; d++)
        Question(id: 'q$d', category: 'self', text: 'Q$d', dayOfYear: d),
    ]);
    final text = exportRecordsAsText(
      [
        DailyRecord()
          ..date = DateTime(2026, 10, 15)
          ..morningQuestionId = 'q288'
          ..stamp = 'happy'
          ..answer = 'Took a walk',
      ],
      [
        BucketItem()
          ..title = 'Hot spring trip'
          ..personId = 1,
        BucketItem()
          ..title = 'Mount Fuji'
          ..doneAt = DateTime(2026, 8, 1),
      ],
      bank,
      personNames: {1: 'Mom'},
      languageCode: 'en',
    );
    expect(text, startsWith('LifeCounter Journal\n'));
    expect(text, contains('Question: Q288'));
    expect(text, contains('Mood: Happy'));
    expect(text, contains('Answer: Took a walk'));
    expect(text, contains('Bucket list'));
    expect(text, contains('- Hot spring trip (with Mom)'));
    expect(text, contains('- [Done] Mount Fuji'));
  });

  test('birth date errors follow the language (Japanese by default)', () {
    expect(DateValidator.validateBirthDate(2026, 2, 30), 'この日付は選べません');
    expect(DateValidator.validateBirthDate(1900, 1, 1, l10n: en),
        'You can pick a date from 1920 onward.');
  });

  testWidgets('MoodCard shows English when the app is in English', (tester) async {
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: MoodCard(selectedId: null, onSelect: (_) {})),
    ));
    expect(find.text('How was your day?'), findsOneWidget);
    for (final label in ['Happy', 'Calm', 'Okay', 'Tired', 'Sad']) {
      expect(find.text(label), findsOneWidget);
    }
  });
}
