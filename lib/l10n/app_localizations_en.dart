// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get add => 'Add';

  @override
  String get edit => 'Edit';

  @override
  String get delete => 'Delete';

  @override
  String get done => 'Done';

  @override
  String get next => 'Next';

  @override
  String get back => 'Back';

  @override
  String get getStarted => 'Get Started';

  @override
  String get none => 'None';

  @override
  String get notSet => 'Not set';

  @override
  String get off => 'Off';

  @override
  String get deleteConfirmMessage => 'This can’t be undone.';

  @override
  String deletePersonTitle(String name) {
    return 'Delete $name?';
  }

  @override
  String deleteBucketItemTitle(String title) {
    return 'Delete “$title”?';
  }

  @override
  String get birthDateNeeded => 'Add your date of birth to see this.';

  @override
  String get loadError => 'Couldn’t load this. Reopening the app may help.';

  @override
  String get readMore => 'Read more';

  @override
  String get showLess => 'Show less';

  @override
  String get birthDate => 'Date of birth';

  @override
  String get gender => 'Gender';

  @override
  String get genderOptional => 'Gender (optional)';

  @override
  String get genderMale => 'Male';

  @override
  String get genderFemale => 'Female';

  @override
  String get genderUnspecified => 'Rather not say';

  @override
  String get tabToday => 'Today';

  @override
  String get tabJournal => 'Journal';

  @override
  String get tabLife => 'Life';

  @override
  String get tabSettings => 'Settings';

  @override
  String get hideKeyboard => 'Hide keyboard';

  @override
  String get todayLifeDaysPrefix => 'Day ';

  @override
  String get todayLifeDaysSuffix => ' of your life';

  @override
  String notificationTitle(int days) {
    final intl.NumberFormat daysNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String daysString = daysNumberFormat.format(days);

    return 'Day $daysString of your life';
  }

  @override
  String get moodQuestion => 'How was your day?';

  @override
  String get moodHappy => 'Happy';

  @override
  String get moodCalm => 'Calm';

  @override
  String get moodNeutral => 'Okay';

  @override
  String get moodTired => 'Tired';

  @override
  String get moodSad => 'Sad';

  @override
  String get todaysQuestion => 'Today’s question';

  @override
  String get answerHint =>
      'Even a few words is enough.\nYou can also tap the mic on the keyboard and just talk.';

  @override
  String get lastYearAnswerLabel => 'One year ago today, you wrote';

  @override
  String get addToBucketList => 'Add to bucket list';

  @override
  String get addedToBucketList => 'Added to your bucket list';

  @override
  String get alreadyInBucketList => 'Already on your bucket list';

  @override
  String get viewList => 'List';

  @override
  String get viewCalendar => 'Calendar';

  @override
  String get noEntriesYet => 'No entries yet';

  @override
  String get noEntry => 'No entry';

  @override
  String get fieldGratitude => 'Grateful for';

  @override
  String get fieldTodayPlan => 'Today’s plan';

  @override
  String get fieldGoodThing => 'A good moment';

  @override
  String get fieldTomorrowMessage => 'Note to tomorrow’s self';

  @override
  String get fieldReason => 'Why';

  @override
  String get fieldTomorrowJoy => 'Looking forward to tomorrow';

  @override
  String get fieldWeeklyHighlight => 'This week’s highlight';

  @override
  String get fieldWeeklyChange => 'Something to change next week';

  @override
  String get oneYearAgoToday => 'One year ago today';

  @override
  String monthMoodCount(int count) {
    return '$count';
  }

  @override
  String monthMoodItem(String mood, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$mood, $count days',
      one: '$mood, 1 day',
    );
    return '$_temp0';
  }

  @override
  String monthMoodsSemantics(String moods) {
    return 'Moods this month: $moods';
  }

  @override
  String get moodListSeparator => '; ';

  @override
  String get segmentYou => 'You';

  @override
  String get segmentPeople => 'People';

  @override
  String get segmentBucketList => 'Bucket list';

  @override
  String get peopleWhoMatter => 'People who matter';

  @override
  String get pastAverageSelf =>
      'Past the average, and still adding to your days';

  @override
  String daysEstimateUnit(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'days, estimated from the average',
      one: 'day, estimated from the average',
    );
    return '$_temp0';
  }

  @override
  String get healthyDaysLabel => 'Of these, days in good health';

  @override
  String aboutDays(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'About $countString days',
      one: 'About $countString day',
    );
    return '$_temp0';
  }

  @override
  String get aheadOfYou => 'Ahead of you';

  @override
  String get weekends => 'Weekends';

  @override
  String aboutTimes(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'About $countString';
  }

  @override
  String get seasons => 'Summers, springs & New Years';

  @override
  String aboutTimesEach(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'About $countString each';
  }

  @override
  String get books => 'Books (at 50 a year)';

  @override
  String aboutBooks(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'About $countString';
  }

  @override
  String get movies => 'Movies (at 20 a year)';

  @override
  String aboutMovies(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'About $countString';
  }

  @override
  String get peopleEmpty =>
      'Add a parent, family member, or friend to see an estimate of the time you have together.';

  @override
  String get addPerson => 'Add Someone';

  @override
  String get editPerson => 'Edit Person';

  @override
  String ageYears(int age) {
    return 'Age $age';
  }

  @override
  String get statYearsAhead => 'Years ahead';

  @override
  String get statHealthyYears => 'Healthy years ahead';

  @override
  String get statYearsTogether => 'Years together';

  @override
  String get statMeetCount => 'Times you can meet';

  @override
  String get approxTight => 'About ';

  @override
  String get approxSpaced => 'About ';

  @override
  String unitYearsTight(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: ' years',
      one: ' year',
    );
    return '$_temp0';
  }

  @override
  String unitYearsSpaced(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: ' years',
      one: ' year',
    );
    return '$_temp0';
  }

  @override
  String unitTimesTight(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: ' times',
      one: ' time',
    );
    return '$_temp0';
  }

  @override
  String unitTimesSpaced(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: ' times',
      one: ' time',
    );
    return '$_temp0';
  }

  @override
  String unitDaysSpaced(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: ' days',
      one: ' day',
    );
    return '$_temp0';
  }

  @override
  String get togetherNote => 'Based on the shorter of your two averages';

  @override
  String meetNote(String frequency) {
    return 'If you meet $frequency';
  }

  @override
  String get sinceLastMet => 'Since you last met';

  @override
  String get pastAveragePerson =>
      'Past the average age, with more days still to share';

  @override
  String get nickname => 'Nickname';

  @override
  String get nicknameHint => 'e.g. Mom';

  @override
  String get nicknameNeeded => 'Add a nickname to save.';

  @override
  String get meetingFrequency => 'How often you meet';

  @override
  String get lastMetOptional => 'Last time you met (optional)';

  @override
  String get freqAlmostDaily => 'almost every day';

  @override
  String get freqWeekly => 'once or twice a week';

  @override
  String get freqMonthly => 'once or twice a month';

  @override
  String get freqFewMonths => 'every few months';

  @override
  String get freqYearly => 'once or twice a year';

  @override
  String get freqYearlyOrLess => 'once a year or less';

  @override
  String get freqRarely => 'rarely';

  @override
  String get bucketIntro =>
      'Things you hope to do someday in your life.\nOn your own, or with family and friends.';

  @override
  String get bucketAlreadyOnList => 'It’s already on your list';

  @override
  String get forExample => 'For example';

  @override
  String get bucketExample1 => 'See the northern lights';

  @override
  String get bucketExample2 => 'Visit a hot spring with family';

  @override
  String get bucketExample3 => 'Take a trip with my parents';

  @override
  String get bucketExample4 => 'Climb Mount Fuji';

  @override
  String get bucketFromAnswers =>
      'You can also add things from your answers to today’s question.';

  @override
  String get bucketSomeday => 'Someday';

  @override
  String get bucketAchieved => 'Achieved';

  @override
  String get bucketDone => 'Done';

  @override
  String get bucketNotDone => 'Not done yet';

  @override
  String bucketDoneOn(String date) {
    return 'Achieved $date';
  }

  @override
  String bucketWithPerson(String name) {
    return 'with $name';
  }

  @override
  String get subtitleSeparator => ' · ';

  @override
  String get withWhomOptional => 'With (optional)';

  @override
  String get morningNotification => 'Morning notification';

  @override
  String get time => 'Time';

  @override
  String get notificationTimeRange =>
      'Notifications can be set between 5:00 and 11:00.';

  @override
  String get exportJournal => 'Export Journal';

  @override
  String get sendFeedback => 'Send Feedback';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get termsOfUse => 'Terms of Use';

  @override
  String version(String version) {
    return 'Version $version';
  }

  @override
  String get feedbackSubject => 'LifeCounter Feedback';

  @override
  String get exportTitle => 'LifeCounter Journal';

  @override
  String get exportQuestion => 'Question';

  @override
  String get exportMood => 'Mood';

  @override
  String get exportAnswer => 'Answer';

  @override
  String get exportTodayGoal => 'To make today a great day';

  @override
  String get exportWhy => 'Why';

  @override
  String get exportBucketList => 'Bucket list';

  @override
  String get exportDoneMark => '[Done] ';

  @override
  String exportWithPerson(String name) {
    return ' (with $name)';
  }

  @override
  String get dateNotAvailable => 'This date isn’t available.';

  @override
  String get dateUpToToday => 'You can pick a date up to today.';

  @override
  String get dateFrom1920 => 'You can pick a date from 1920 onward.';

  @override
  String get welcomeTitleStart => 'Because life\nis ';

  @override
  String get welcomeTitleAccent => 'finite';

  @override
  String get welcomeTitleEnd => '';

  @override
  String get welcomeBody =>
      'Do you know which day\nof your life today is?\n\nKeeping the days ahead in mind\ncan help you treasure each one a little more.';

  @override
  String get aboutYou => 'About You';

  @override
  String get aboutYouBody =>
      'Used to count the days of your life and estimate the days ahead.';

  @override
  String get onboardingLifeDaysBefore => 'Today is day';

  @override
  String get onboardingLifeDaysAfter => 'of your life';

  @override
  String get onboardingDaysAhead => 'The days ahead of you';

  @override
  String get onboardingHowToSpend => 'How would you like\nto spend them?';

  @override
  String get onceStart => 'But\ntoday comes\n';

  @override
  String get onceAccent => 'only once';

  @override
  String get onceEnd => '\nin a lifetime';

  @override
  String get togetherStart => 'Here’s to days\nwithout regret,\n';

  @override
  String get togetherAccent => 'built together';

  @override
  String get togetherEnd => '';

  @override
  String get onboardingGoalQuestion => 'What would make\ntoday a great day?';

  @override
  String get onboardingGoalHint => 'Something small is fine';
}
