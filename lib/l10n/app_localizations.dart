import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ja.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ja'),
  ];

  /// No description provided for @cancel.
  ///
  /// In ja, this message translates to:
  /// **'キャンセル'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In ja, this message translates to:
  /// **'保存'**
  String get save;

  /// No description provided for @add.
  ///
  /// In ja, this message translates to:
  /// **'追加'**
  String get add;

  /// No description provided for @edit.
  ///
  /// In ja, this message translates to:
  /// **'編集'**
  String get edit;

  /// No description provided for @delete.
  ///
  /// In ja, this message translates to:
  /// **'削除'**
  String get delete;

  /// No description provided for @done.
  ///
  /// In ja, this message translates to:
  /// **'完了'**
  String get done;

  /// No description provided for @next.
  ///
  /// In ja, this message translates to:
  /// **'次へ'**
  String get next;

  /// No description provided for @back.
  ///
  /// In ja, this message translates to:
  /// **'戻る'**
  String get back;

  /// No description provided for @getStarted.
  ///
  /// In ja, this message translates to:
  /// **'はじめる'**
  String get getStarted;

  /// No description provided for @none.
  ///
  /// In ja, this message translates to:
  /// **'なし'**
  String get none;

  /// No description provided for @notSet.
  ///
  /// In ja, this message translates to:
  /// **'未設定'**
  String get notSet;

  /// No description provided for @off.
  ///
  /// In ja, this message translates to:
  /// **'オフ'**
  String get off;

  /// No description provided for @deleteConfirmMessage.
  ///
  /// In ja, this message translates to:
  /// **'この操作は取り消せません。'**
  String get deleteConfirmMessage;

  /// No description provided for @deletePersonTitle.
  ///
  /// In ja, this message translates to:
  /// **'{name}を削除しますか？'**
  String deletePersonTitle(String name);

  /// No description provided for @deleteBucketItemTitle.
  ///
  /// In ja, this message translates to:
  /// **'「{title}」を削除しますか？'**
  String deleteBucketItemTitle(String title);

  /// No description provided for @birthDateNeeded.
  ///
  /// In ja, this message translates to:
  /// **'生年月日を入れると表示されます'**
  String get birthDateNeeded;

  /// No description provided for @loadError.
  ///
  /// In ja, this message translates to:
  /// **'読み込めませんでした。アプリを開き直してください。'**
  String get loadError;

  /// No description provided for @readMore.
  ///
  /// In ja, this message translates to:
  /// **'続きを読む'**
  String get readMore;

  /// No description provided for @showLess.
  ///
  /// In ja, this message translates to:
  /// **'閉じる'**
  String get showLess;

  /// No description provided for @birthDate.
  ///
  /// In ja, this message translates to:
  /// **'生年月日'**
  String get birthDate;

  /// No description provided for @gender.
  ///
  /// In ja, this message translates to:
  /// **'性別'**
  String get gender;

  /// No description provided for @genderOptional.
  ///
  /// In ja, this message translates to:
  /// **'性別（任意）'**
  String get genderOptional;

  /// No description provided for @genderMale.
  ///
  /// In ja, this message translates to:
  /// **'男性'**
  String get genderMale;

  /// No description provided for @genderFemale.
  ///
  /// In ja, this message translates to:
  /// **'女性'**
  String get genderFemale;

  /// No description provided for @genderUnspecified.
  ///
  /// In ja, this message translates to:
  /// **'答えない'**
  String get genderUnspecified;

  /// No description provided for @tabToday.
  ///
  /// In ja, this message translates to:
  /// **'今日'**
  String get tabToday;

  /// No description provided for @tabJournal.
  ///
  /// In ja, this message translates to:
  /// **'記録'**
  String get tabJournal;

  /// No description provided for @tabLife.
  ///
  /// In ja, this message translates to:
  /// **'人生'**
  String get tabLife;

  /// No description provided for @tabSettings.
  ///
  /// In ja, this message translates to:
  /// **'設定'**
  String get tabSettings;

  /// No description provided for @hideKeyboard.
  ///
  /// In ja, this message translates to:
  /// **'キーボードを閉じる'**
  String get hideKeyboard;

  /// No description provided for @todayLifeDaysPrefix.
  ///
  /// In ja, this message translates to:
  /// **'人生 '**
  String get todayLifeDaysPrefix;

  /// No description provided for @todayLifeDaysSuffix.
  ///
  /// In ja, this message translates to:
  /// **' 日目'**
  String get todayLifeDaysSuffix;

  /// 朝の通知の題。今日が人生の何日目か
  ///
  /// In ja, this message translates to:
  /// **'人生 {days}日目'**
  String notificationTitle(int days);

  /// No description provided for @moodQuestion.
  ///
  /// In ja, this message translates to:
  /// **'今日はどんな一日だった？'**
  String get moodQuestion;

  /// No description provided for @moodHappy.
  ///
  /// In ja, this message translates to:
  /// **'うれしい'**
  String get moodHappy;

  /// No description provided for @moodCalm.
  ///
  /// In ja, this message translates to:
  /// **'おだやか'**
  String get moodCalm;

  /// No description provided for @moodNeutral.
  ///
  /// In ja, this message translates to:
  /// **'ふつう'**
  String get moodNeutral;

  /// No description provided for @moodTired.
  ///
  /// In ja, this message translates to:
  /// **'つかれた'**
  String get moodTired;

  /// No description provided for @moodSad.
  ///
  /// In ja, this message translates to:
  /// **'かなしい'**
  String get moodSad;

  /// No description provided for @todaysQuestion.
  ///
  /// In ja, this message translates to:
  /// **'今日の問い'**
  String get todaysQuestion;

  /// No description provided for @answerHint.
  ///
  /// In ja, this message translates to:
  /// **'ひとことでも大丈夫です。\nキーボードのマイクで、話して入力することもできます'**
  String get answerHint;

  /// No description provided for @lastYearAnswerLabel.
  ///
  /// In ja, this message translates to:
  /// **'1年前の今日、あなたはこう答えました'**
  String get lastYearAnswerLabel;

  /// No description provided for @addToBucketList.
  ///
  /// In ja, this message translates to:
  /// **'バケットリストに追加'**
  String get addToBucketList;

  /// No description provided for @addedToBucketList.
  ///
  /// In ja, this message translates to:
  /// **'バケットリストに追加しました'**
  String get addedToBucketList;

  /// No description provided for @alreadyInBucketList.
  ///
  /// In ja, this message translates to:
  /// **'もうバケットリストにあります'**
  String get alreadyInBucketList;

  /// No description provided for @viewList.
  ///
  /// In ja, this message translates to:
  /// **'リスト'**
  String get viewList;

  /// No description provided for @viewCalendar.
  ///
  /// In ja, this message translates to:
  /// **'カレンダー'**
  String get viewCalendar;

  /// No description provided for @noEntriesYet.
  ///
  /// In ja, this message translates to:
  /// **'記録はまだありません'**
  String get noEntriesYet;

  /// No description provided for @noEntry.
  ///
  /// In ja, this message translates to:
  /// **'記録なし'**
  String get noEntry;

  /// No description provided for @fieldGratitude.
  ///
  /// In ja, this message translates to:
  /// **'感謝していること'**
  String get fieldGratitude;

  /// No description provided for @fieldTodayPlan.
  ///
  /// In ja, this message translates to:
  /// **'今日やること'**
  String get fieldTodayPlan;

  /// No description provided for @fieldGoodThing.
  ///
  /// In ja, this message translates to:
  /// **'嬉しかったこと'**
  String get fieldGoodThing;

  /// No description provided for @fieldTomorrowMessage.
  ///
  /// In ja, this message translates to:
  /// **'明日の自分へ'**
  String get fieldTomorrowMessage;

  /// No description provided for @fieldReason.
  ///
  /// In ja, this message translates to:
  /// **'その理由'**
  String get fieldReason;

  /// No description provided for @fieldTomorrowJoy.
  ///
  /// In ja, this message translates to:
  /// **'明日の楽しみ'**
  String get fieldTomorrowJoy;

  /// No description provided for @fieldWeeklyHighlight.
  ///
  /// In ja, this message translates to:
  /// **'今週のハイライト'**
  String get fieldWeeklyHighlight;

  /// No description provided for @fieldWeeklyChange.
  ///
  /// In ja, this message translates to:
  /// **'来週変えること'**
  String get fieldWeeklyChange;

  /// No description provided for @oneYearAgoToday.
  ///
  /// In ja, this message translates to:
  /// **'1年前の今日'**
  String get oneYearAgoToday;

  /// 月の見出しで、気分の顔の横に出す日数(英語は数だけ)
  ///
  /// In ja, this message translates to:
  /// **'{count}日'**
  String monthMoodCount(int count);

  /// 読み上げ用。気分と日数
  ///
  /// In ja, this message translates to:
  /// **'{mood}{count}日'**
  String monthMoodItem(String mood, int count);

  /// No description provided for @monthMoodsSemantics.
  ///
  /// In ja, this message translates to:
  /// **'この月の気分 {moods}'**
  String monthMoodsSemantics(String moods);

  /// No description provided for @moodListSeparator.
  ///
  /// In ja, this message translates to:
  /// **'、'**
  String get moodListSeparator;

  /// No description provided for @segmentYou.
  ///
  /// In ja, this message translates to:
  /// **'あなた'**
  String get segmentYou;

  /// No description provided for @segmentPeople.
  ///
  /// In ja, this message translates to:
  /// **'大切な人'**
  String get segmentPeople;

  /// No description provided for @segmentBucketList.
  ///
  /// In ja, this message translates to:
  /// **'バケットリスト'**
  String get segmentBucketList;

  /// No description provided for @peopleWhoMatter.
  ///
  /// In ja, this message translates to:
  /// **'大切な人'**
  String get peopleWhoMatter;

  /// No description provided for @pastAverageSelf.
  ///
  /// In ja, this message translates to:
  /// **'平均寿命を越えて、日々を重ねています'**
  String get pastAverageSelf;

  /// 大きな数字の下に出す単位と説明
  ///
  /// In ja, this message translates to:
  /// **'{count, plural, other{日（いまの年齢からの平均の目安）}}'**
  String daysEstimateUnit(int count);

  /// No description provided for @healthyDaysLabel.
  ///
  /// In ja, this message translates to:
  /// **'そのうち、元気に過ごせる目安'**
  String get healthyDaysLabel;

  /// No description provided for @aboutDays.
  ///
  /// In ja, this message translates to:
  /// **'約 {count} 日'**
  String aboutDays(int count);

  /// No description provided for @aheadOfYou.
  ///
  /// In ja, this message translates to:
  /// **'これから迎える'**
  String get aheadOfYou;

  /// No description provided for @weekends.
  ///
  /// In ja, this message translates to:
  /// **'週末'**
  String get weekends;

  /// No description provided for @aboutTimes.
  ///
  /// In ja, this message translates to:
  /// **'約{count}回'**
  String aboutTimes(int count);

  /// No description provided for @seasons.
  ///
  /// In ja, this message translates to:
  /// **'夏・桜・正月'**
  String get seasons;

  /// No description provided for @aboutTimesEach.
  ///
  /// In ja, this message translates to:
  /// **'それぞれ約{count}回'**
  String aboutTimesEach(int count);

  /// No description provided for @books.
  ///
  /// In ja, this message translates to:
  /// **'本（年50冊なら）'**
  String get books;

  /// No description provided for @aboutBooks.
  ///
  /// In ja, this message translates to:
  /// **'約{count}冊'**
  String aboutBooks(int count);

  /// No description provided for @movies.
  ///
  /// In ja, this message translates to:
  /// **'映画（年20本なら）'**
  String get movies;

  /// No description provided for @aboutMovies.
  ///
  /// In ja, this message translates to:
  /// **'約{count}本'**
  String aboutMovies(int count);

  /// No description provided for @peopleEmpty.
  ///
  /// In ja, this message translates to:
  /// **'親や家族、友だちを追加すると、一緒に過ごせる時間の目安が分かります。'**
  String get peopleEmpty;

  /// No description provided for @addPerson.
  ///
  /// In ja, this message translates to:
  /// **'大切な人を追加'**
  String get addPerson;

  /// No description provided for @editPerson.
  ///
  /// In ja, this message translates to:
  /// **'大切な人を編集'**
  String get editPerson;

  /// No description provided for @ageYears.
  ///
  /// In ja, this message translates to:
  /// **'{age}歳'**
  String ageYears(int age);

  /// No description provided for @statYearsAhead.
  ///
  /// In ja, this message translates to:
  /// **'これから'**
  String get statYearsAhead;

  /// No description provided for @statHealthyYears.
  ///
  /// In ja, this message translates to:
  /// **'元気に過ごせる目安'**
  String get statHealthyYears;

  /// No description provided for @statYearsTogether.
  ///
  /// In ja, this message translates to:
  /// **'一緒にいられる年数'**
  String get statYearsTogether;

  /// No description provided for @statMeetCount.
  ///
  /// In ja, this message translates to:
  /// **'これから会える回数'**
  String get statMeetCount;

  /// No description provided for @approxTight.
  ///
  /// In ja, this message translates to:
  /// **'約'**
  String get approxTight;

  /// No description provided for @approxSpaced.
  ///
  /// In ja, this message translates to:
  /// **'約 '**
  String get approxSpaced;

  /// No description provided for @unitYearsTight.
  ///
  /// In ja, this message translates to:
  /// **'{count, plural, other{年}}'**
  String unitYearsTight(int count);

  /// No description provided for @unitYearsSpaced.
  ///
  /// In ja, this message translates to:
  /// **'{count, plural, other{ 年}}'**
  String unitYearsSpaced(int count);

  /// No description provided for @unitTimesTight.
  ///
  /// In ja, this message translates to:
  /// **'{count, plural, other{回}}'**
  String unitTimesTight(int count);

  /// No description provided for @unitTimesSpaced.
  ///
  /// In ja, this message translates to:
  /// **'{count, plural, other{ 回}}'**
  String unitTimesSpaced(int count);

  /// No description provided for @unitDaysSpaced.
  ///
  /// In ja, this message translates to:
  /// **'{count, plural, other{ 日}}'**
  String unitDaysSpaced(int count);

  /// No description provided for @togetherNote.
  ///
  /// In ja, this message translates to:
  /// **'ふたりの、いまの年齢からの平均のうち短いほう'**
  String get togetherNote;

  /// No description provided for @meetNote.
  ///
  /// In ja, this message translates to:
  /// **'{frequency}会うとして'**
  String meetNote(String frequency);

  /// No description provided for @sinceLastMet.
  ///
  /// In ja, this message translates to:
  /// **'最後に会ってから'**
  String get sinceLastMet;

  /// No description provided for @pastAveragePerson.
  ///
  /// In ja, this message translates to:
  /// **'平均寿命を越えて、日々を重ねています'**
  String get pastAveragePerson;

  /// No description provided for @nickname.
  ///
  /// In ja, this message translates to:
  /// **'ニックネーム'**
  String get nickname;

  /// No description provided for @nicknameHint.
  ///
  /// In ja, this message translates to:
  /// **'例: お母さん'**
  String get nicknameHint;

  /// No description provided for @nicknameNeeded.
  ///
  /// In ja, this message translates to:
  /// **'ニックネームを入れると保存できます'**
  String get nicknameNeeded;

  /// No description provided for @meetingFrequency.
  ///
  /// In ja, this message translates to:
  /// **'会う頻度'**
  String get meetingFrequency;

  /// No description provided for @lastMetOptional.
  ///
  /// In ja, this message translates to:
  /// **'最後に会った日（任意）'**
  String get lastMetOptional;

  /// No description provided for @freqAlmostDaily.
  ///
  /// In ja, this message translates to:
  /// **'ほとんど毎日'**
  String get freqAlmostDaily;

  /// No description provided for @freqWeekly.
  ///
  /// In ja, this message translates to:
  /// **'週に1〜2回'**
  String get freqWeekly;

  /// No description provided for @freqMonthly.
  ///
  /// In ja, this message translates to:
  /// **'月に1〜2回'**
  String get freqMonthly;

  /// No description provided for @freqFewMonths.
  ///
  /// In ja, this message translates to:
  /// **'数ヶ月に1回'**
  String get freqFewMonths;

  /// No description provided for @freqYearly.
  ///
  /// In ja, this message translates to:
  /// **'年に1〜2回'**
  String get freqYearly;

  /// No description provided for @freqYearlyOrLess.
  ///
  /// In ja, this message translates to:
  /// **'年に1回以下'**
  String get freqYearlyOrLess;

  /// No description provided for @freqRarely.
  ///
  /// In ja, this message translates to:
  /// **'ほとんど会えない'**
  String get freqRarely;

  /// No description provided for @bucketIntro.
  ///
  /// In ja, this message translates to:
  /// **'人生のうちに、いつかかなえたいことのリスト。\nひとりでも、家族や友だちとでも。'**
  String get bucketIntro;

  /// No description provided for @bucketAlreadyOnList.
  ///
  /// In ja, this message translates to:
  /// **'もうリストにあります'**
  String get bucketAlreadyOnList;

  /// No description provided for @forExample.
  ///
  /// In ja, this message translates to:
  /// **'たとえば'**
  String get forExample;

  /// No description provided for @bucketExample1.
  ///
  /// In ja, this message translates to:
  /// **'オーロラを見る'**
  String get bucketExample1;

  /// No description provided for @bucketExample2.
  ///
  /// In ja, this message translates to:
  /// **'家族で温泉に行く'**
  String get bucketExample2;

  /// No description provided for @bucketExample3.
  ///
  /// In ja, this message translates to:
  /// **'親と旅行に行く'**
  String get bucketExample3;

  /// No description provided for @bucketExample4.
  ///
  /// In ja, this message translates to:
  /// **'富士山に登る'**
  String get bucketExample4;

  /// No description provided for @bucketFromAnswers.
  ///
  /// In ja, this message translates to:
  /// **'今日の問いの答えからも追加できます。'**
  String get bucketFromAnswers;

  /// No description provided for @bucketSomeday.
  ///
  /// In ja, this message translates to:
  /// **'いつか'**
  String get bucketSomeday;

  /// No description provided for @bucketAchieved.
  ///
  /// In ja, this message translates to:
  /// **'かなえたこと'**
  String get bucketAchieved;

  /// No description provided for @bucketDone.
  ///
  /// In ja, this message translates to:
  /// **'かなえた'**
  String get bucketDone;

  /// No description provided for @bucketNotDone.
  ///
  /// In ja, this message translates to:
  /// **'まだかなえていない'**
  String get bucketNotDone;

  /// No description provided for @bucketDoneOn.
  ///
  /// In ja, this message translates to:
  /// **'{date}にかなえた'**
  String bucketDoneOn(String date);

  /// No description provided for @bucketWithPerson.
  ///
  /// In ja, this message translates to:
  /// **'{name}と'**
  String bucketWithPerson(String name);

  /// No description provided for @subtitleSeparator.
  ///
  /// In ja, this message translates to:
  /// **'・'**
  String get subtitleSeparator;

  /// No description provided for @withWhomOptional.
  ///
  /// In ja, this message translates to:
  /// **'誰と（任意）'**
  String get withWhomOptional;

  /// No description provided for @morningNotification.
  ///
  /// In ja, this message translates to:
  /// **'朝の通知'**
  String get morningNotification;

  /// No description provided for @time.
  ///
  /// In ja, this message translates to:
  /// **'時刻'**
  String get time;

  /// No description provided for @notificationTimeRange.
  ///
  /// In ja, this message translates to:
  /// **'通知は 5:00〜11:00 の間で選べます'**
  String get notificationTimeRange;

  /// No description provided for @exportJournal.
  ///
  /// In ja, this message translates to:
  /// **'記録を書き出す'**
  String get exportJournal;

  /// No description provided for @sendFeedback.
  ///
  /// In ja, this message translates to:
  /// **'フィードバックを送る'**
  String get sendFeedback;

  /// No description provided for @privacyPolicy.
  ///
  /// In ja, this message translates to:
  /// **'プライバシーポリシー'**
  String get privacyPolicy;

  /// No description provided for @termsOfUse.
  ///
  /// In ja, this message translates to:
  /// **'利用規約'**
  String get termsOfUse;

  /// No description provided for @version.
  ///
  /// In ja, this message translates to:
  /// **'バージョン {version}'**
  String version(String version);

  /// No description provided for @feedbackSubject.
  ///
  /// In ja, this message translates to:
  /// **'LifeCounter フィードバック'**
  String get feedbackSubject;

  /// No description provided for @exportTitle.
  ///
  /// In ja, this message translates to:
  /// **'LifeCounter の記録'**
  String get exportTitle;

  /// No description provided for @exportQuestion.
  ///
  /// In ja, this message translates to:
  /// **'問い'**
  String get exportQuestion;

  /// No description provided for @exportMood.
  ///
  /// In ja, this message translates to:
  /// **'気分'**
  String get exportMood;

  /// No description provided for @exportAnswer.
  ///
  /// In ja, this message translates to:
  /// **'答え'**
  String get exportAnswer;

  /// No description provided for @exportTodayGoal.
  ///
  /// In ja, this message translates to:
  /// **'今日を素晴らしい一日にするために'**
  String get exportTodayGoal;

  /// No description provided for @exportWhy.
  ///
  /// In ja, this message translates to:
  /// **'なぜ'**
  String get exportWhy;

  /// No description provided for @exportBucketList.
  ///
  /// In ja, this message translates to:
  /// **'バケットリスト'**
  String get exportBucketList;

  /// No description provided for @exportDoneMark.
  ///
  /// In ja, this message translates to:
  /// **'[かなえた] '**
  String get exportDoneMark;

  /// No description provided for @exportWithPerson.
  ///
  /// In ja, this message translates to:
  /// **'({name}と)'**
  String exportWithPerson(String name);

  /// No description provided for @dateNotAvailable.
  ///
  /// In ja, this message translates to:
  /// **'この日付は選べません'**
  String get dateNotAvailable;

  /// No description provided for @dateUpToToday.
  ///
  /// In ja, this message translates to:
  /// **'今日までの日付を選べます'**
  String get dateUpToToday;

  /// No description provided for @dateFrom1920.
  ///
  /// In ja, this message translates to:
  /// **'1920年以降の日付を選べます'**
  String get dateFrom1920;

  /// No description provided for @welcomeTitle.
  ///
  /// In ja, this message translates to:
  /// **'今日は、人生の何日目？'**
  String get welcomeTitle;

  /// No description provided for @welcomeBody.
  ///
  /// In ja, this message translates to:
  /// **'1日1つの問いに答える日記です。\n答えるうちに、家族と過ごす時間や、\nこれから大切にしたいことが見えてきます。'**
  String get welcomeBody;

  /// No description provided for @birthTitle.
  ///
  /// In ja, this message translates to:
  /// **'生年月日を教えてください'**
  String get birthTitle;

  /// No description provided for @birthBody.
  ///
  /// In ja, this message translates to:
  /// **'今日が人生の何日目かを数えます。\n記録はこの iPhone の中だけに残ります。'**
  String get birthBody;

  /// No description provided for @genderNote.
  ///
  /// In ja, this message translates to:
  /// **'平均からの目安に使います'**
  String get genderNote;

  /// No description provided for @onboardingLifeDaysBefore.
  ///
  /// In ja, this message translates to:
  /// **'今日は、あなたの人生'**
  String get onboardingLifeDaysBefore;

  /// No description provided for @onboardingLifeDaysAfter.
  ///
  /// In ja, this message translates to:
  /// **'日目です'**
  String get onboardingLifeDaysAfter;

  /// No description provided for @onboardingLifeDaysNote.
  ///
  /// In ja, this message translates to:
  /// **'この数字は、毎日ひとつずつ増えていきます。'**
  String get onboardingLifeDaysNote;

  /// No description provided for @onboardingDaysAheadTitle.
  ///
  /// In ja, this message translates to:
  /// **'これからの日々'**
  String get onboardingDaysAheadTitle;

  /// No description provided for @onboardingDaysAheadQuestion.
  ///
  /// In ja, this message translates to:
  /// **'この日々を、\nどう過ごしていきますか。'**
  String get onboardingDaysAheadQuestion;

  /// No description provided for @onboardingQuestionTitle.
  ///
  /// In ja, this message translates to:
  /// **'毎日ひとつ、問いが届きます'**
  String get onboardingQuestionTitle;

  /// No description provided for @onboardingQuestionBody.
  ///
  /// In ja, this message translates to:
  /// **'気分は顔をひと押し。\n答えはひとことでも大丈夫です。'**
  String get onboardingQuestionBody;

  /// No description provided for @onboardingNotifyBody.
  ///
  /// In ja, this message translates to:
  /// **'毎朝{time}に、その日の問いをお知らせします。\n時刻は設定で変えられます。'**
  String onboardingNotifyBody(String time);

  /// No description provided for @notifyAllow.
  ///
  /// In ja, this message translates to:
  /// **'通知を受け取る'**
  String get notifyAllow;

  /// No description provided for @notifyLater.
  ///
  /// In ja, this message translates to:
  /// **'今はしない'**
  String get notifyLater;

  /// No description provided for @statDaysShared.
  ///
  /// In ja, this message translates to:
  /// **'一緒に過ごしてきた日々'**
  String get statDaysShared;

  /// No description provided for @unitDaysTight.
  ///
  /// In ja, this message translates to:
  /// **'{count, plural, other{日}}'**
  String unitDaysTight(int count);

  /// No description provided for @estimateNote.
  ///
  /// In ja, this message translates to:
  /// **'数字はみんなの平均から出した目安です。一人ひとりの人生は、数字では決まりません。'**
  String get estimateNote;

  /// No description provided for @editMood.
  ///
  /// In ja, this message translates to:
  /// **'気分'**
  String get editMood;

  /// No description provided for @deleteDay.
  ///
  /// In ja, this message translates to:
  /// **'この日の記録を削除'**
  String get deleteDay;

  /// No description provided for @deleteDayTitle.
  ///
  /// In ja, this message translates to:
  /// **'{date}の記録を削除しますか？'**
  String deleteDayTitle(String date);

  /// No description provided for @daysAheadRow.
  ///
  /// In ja, this message translates to:
  /// **'これからの日々'**
  String get daysAheadRow;

  /// No description provided for @answerSaved.
  ///
  /// In ja, this message translates to:
  /// **'保存しました'**
  String get answerSaved;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ja'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ja':
      return AppLocalizationsJa();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
