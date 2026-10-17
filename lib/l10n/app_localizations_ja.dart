// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get cancel => 'キャンセル';

  @override
  String get save => '保存';

  @override
  String get add => '追加';

  @override
  String get edit => '編集';

  @override
  String get delete => '削除';

  @override
  String get done => '完了';

  @override
  String get next => '次へ';

  @override
  String get back => '戻る';

  @override
  String get getStarted => 'はじめる';

  @override
  String get none => 'なし';

  @override
  String get notSet => '未設定';

  @override
  String get off => 'オフ';

  @override
  String get deleteConfirmMessage => 'この操作は取り消せません。';

  @override
  String deletePersonTitle(String name) {
    return '$nameを削除しますか？';
  }

  @override
  String deleteBucketItemTitle(String title) {
    return '「$title」を削除しますか？';
  }

  @override
  String get birthDateNeeded => '生年月日を入れると表示されます';

  @override
  String get loadError => '読み込めませんでした。アプリを開き直してください。';

  @override
  String get readMore => '続きを読む';

  @override
  String get showLess => '閉じる';

  @override
  String get birthDate => '生年月日';

  @override
  String get gender => '性別';

  @override
  String get genderOptional => '性別（任意）';

  @override
  String get genderMale => '男性';

  @override
  String get genderFemale => '女性';

  @override
  String get genderUnspecified => '答えない';

  @override
  String get tabToday => '今日';

  @override
  String get tabJournal => '記録';

  @override
  String get tabLife => '人生';

  @override
  String get tabSettings => '設定';

  @override
  String get hideKeyboard => 'キーボードを閉じる';

  @override
  String get todayLifeDaysPrefix => '人生 ';

  @override
  String get todayLifeDaysSuffix => ' 日目';

  @override
  String notificationTitle(int days) {
    final intl.NumberFormat daysNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String daysString = daysNumberFormat.format(days);

    return '人生 $daysString日目';
  }

  @override
  String get moodQuestion => '今日はどんな一日だった？';

  @override
  String get moodHappy => 'うれしい';

  @override
  String get moodCalm => 'おだやか';

  @override
  String get moodNeutral => 'ふつう';

  @override
  String get moodTired => 'つかれた';

  @override
  String get moodSad => 'かなしい';

  @override
  String get todaysQuestion => '今日の問い';

  @override
  String get answerHint => 'ひとことでも大丈夫です。\nキーボードのマイクで、話して入力することもできます';

  @override
  String get lastYearAnswerLabel => '1年前の今日、あなたはこう答えました';

  @override
  String get addToBucketList => 'バケットリストに追加';

  @override
  String get addedToBucketList => 'バケットリストに追加しました';

  @override
  String get alreadyInBucketList => 'もうバケットリストにあります';

  @override
  String get viewList => 'リスト';

  @override
  String get viewCalendar => 'カレンダー';

  @override
  String get noEntriesYet => '記録はまだありません';

  @override
  String get noEntry => '記録なし';

  @override
  String get fieldGratitude => '感謝していること';

  @override
  String get fieldTodayPlan => '今日やること';

  @override
  String get fieldGoodThing => '嬉しかったこと';

  @override
  String get fieldTomorrowMessage => '明日の自分へ';

  @override
  String get fieldReason => 'その理由';

  @override
  String get fieldTomorrowJoy => '明日の楽しみ';

  @override
  String get fieldWeeklyHighlight => '今週のハイライト';

  @override
  String get fieldWeeklyChange => '来週変えること';

  @override
  String get oneYearAgoToday => '1年前の今日';

  @override
  String monthMoodCount(int count) {
    return '$count日';
  }

  @override
  String monthMoodItem(String mood, int count) {
    return '$mood$count日';
  }

  @override
  String monthMoodsSemantics(String moods) {
    return 'この月の気分 $moods';
  }

  @override
  String get moodListSeparator => '、';

  @override
  String get segmentYou => 'あなた';

  @override
  String get segmentPeople => '大切な人';

  @override
  String get segmentBucketList => 'バケットリスト';

  @override
  String get peopleWhoMatter => '大切な人';

  @override
  String get pastAverageSelf => '平均寿命を越えて、日々を重ねています';

  @override
  String daysEstimateUnit(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '日（いまの年齢からの平均の目安）',
    );
    return '$_temp0';
  }

  @override
  String get healthyDaysLabel => 'そのうち、元気に過ごせる目安';

  @override
  String aboutDays(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '約 $countString 日';
  }

  @override
  String get aheadOfYou => 'これから迎える';

  @override
  String get weekends => '週末';

  @override
  String aboutTimes(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '約$countString回';
  }

  @override
  String get seasons => '夏・桜・正月';

  @override
  String aboutTimesEach(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'それぞれ約$countString回';
  }

  @override
  String get books => '本（年50冊なら）';

  @override
  String aboutBooks(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '約$countString冊';
  }

  @override
  String get movies => '映画（年20本なら）';

  @override
  String aboutMovies(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '約$countString本';
  }

  @override
  String get peopleEmpty => '親や家族、友だちを追加すると、一緒に過ごせる時間の目安が分かります。';

  @override
  String get addPerson => '大切な人を追加';

  @override
  String get editPerson => '大切な人を編集';

  @override
  String ageYears(int age) {
    return '$age歳';
  }

  @override
  String get statYearsAhead => 'これから';

  @override
  String get statHealthyYears => '元気に過ごせる目安';

  @override
  String get statYearsTogether => '一緒にいられる年数';

  @override
  String get statMeetCount => 'これから会える回数';

  @override
  String get approxTight => '約';

  @override
  String get approxSpaced => '約 ';

  @override
  String unitYearsTight(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '年',
    );
    return '$_temp0';
  }

  @override
  String unitYearsSpaced(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: ' 年',
    );
    return '$_temp0';
  }

  @override
  String unitTimesTight(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '回',
    );
    return '$_temp0';
  }

  @override
  String unitTimesSpaced(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: ' 回',
    );
    return '$_temp0';
  }

  @override
  String unitDaysSpaced(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: ' 日',
    );
    return '$_temp0';
  }

  @override
  String get togetherNote => 'ふたりの、いまの年齢からの平均のうち短いほう';

  @override
  String meetNote(String frequency) {
    return '$frequency会うとして';
  }

  @override
  String get sinceLastMet => '最後に会ってから';

  @override
  String get pastAveragePerson => '平均寿命を越えて、日々を重ねています';

  @override
  String get nickname => 'ニックネーム';

  @override
  String get nicknameHint => '例: お母さん';

  @override
  String get nicknameNeeded => 'ニックネームを入れると保存できます';

  @override
  String get meetingFrequency => '会う頻度';

  @override
  String get lastMetOptional => '最後に会った日（任意）';

  @override
  String get freqAlmostDaily => 'ほとんど毎日';

  @override
  String get freqWeekly => '週に1〜2回';

  @override
  String get freqMonthly => '月に1〜2回';

  @override
  String get freqFewMonths => '数ヶ月に1回';

  @override
  String get freqYearly => '年に1〜2回';

  @override
  String get freqYearlyOrLess => '年に1回以下';

  @override
  String get freqRarely => 'ほとんど会えない';

  @override
  String get bucketIntro => '人生のうちに、いつかかなえたいことのリスト。\nひとりでも、家族や友だちとでも。';

  @override
  String get bucketAlreadyOnList => 'もうリストにあります';

  @override
  String get forExample => 'たとえば';

  @override
  String get bucketExample1 => 'オーロラを見る';

  @override
  String get bucketExample2 => '家族で温泉に行く';

  @override
  String get bucketExample3 => '親と旅行に行く';

  @override
  String get bucketExample4 => '富士山に登る';

  @override
  String get bucketFromAnswers => '今日の問いの答えからも追加できます。';

  @override
  String get bucketSomeday => 'いつか';

  @override
  String get bucketAchieved => 'かなえたこと';

  @override
  String get bucketDone => 'かなえた';

  @override
  String get bucketNotDone => 'まだかなえていない';

  @override
  String bucketDoneOn(String date) {
    return '$dateにかなえた';
  }

  @override
  String bucketWithPerson(String name) {
    return '$nameと';
  }

  @override
  String get subtitleSeparator => '・';

  @override
  String get withWhomOptional => '誰と（任意）';

  @override
  String get morningNotification => '朝の通知';

  @override
  String get time => '時刻';

  @override
  String get notificationTimeRange => '通知は 5:00〜11:00 の間で選べます';

  @override
  String get exportJournal => '記録を書き出す';

  @override
  String get sendFeedback => 'フィードバックを送る';

  @override
  String get privacyPolicy => 'プライバシーポリシー';

  @override
  String get termsOfUse => '利用規約';

  @override
  String version(String version) {
    return 'バージョン $version';
  }

  @override
  String get feedbackSubject => 'LifeCounter フィードバック';

  @override
  String get exportTitle => 'LifeCounter の記録';

  @override
  String get exportQuestion => '問い';

  @override
  String get exportMood => '気分';

  @override
  String get exportAnswer => '答え';

  @override
  String get exportTodayGoal => '今日を素晴らしい一日にするために';

  @override
  String get exportWhy => 'なぜ';

  @override
  String get exportBucketList => 'バケットリスト';

  @override
  String get exportDoneMark => '[かなえた] ';

  @override
  String exportWithPerson(String name) {
    return '($nameと)';
  }

  @override
  String get dateNotAvailable => 'この日付は選べません';

  @override
  String get dateUpToToday => '今日までの日付を選べます';

  @override
  String get dateFrom1920 => '1920年以降の日付を選べます';

  @override
  String get welcomeTitle => '今日は、人生の何日目？';

  @override
  String get welcomeBody =>
      '1日1つの問いに答える日記です。\n答えるうちに、家族と過ごす時間や、\nこれから大切にしたいことが見えてきます。';

  @override
  String get birthTitle => '生年月日を教えてください';

  @override
  String get birthBody => '今日が人生の何日目かを数えます。\n記録はこの iPhone の中だけに残ります。';

  @override
  String get genderNote => '平均からの目安に使います';

  @override
  String get onboardingLifeDaysBefore => '今日は、あなたの人生';

  @override
  String get onboardingLifeDaysAfter => '日目です';

  @override
  String get onboardingLifeDaysNote => 'この数字は、毎日ひとつずつ増えていきます。';

  @override
  String get onboardingDaysAheadTitle => 'これからの日々';

  @override
  String get onboardingDaysAheadQuestion => 'この日々を、\nどう過ごしていきますか。';

  @override
  String get onboardingQuestionTitle => '毎日ひとつ、問いが届きます';

  @override
  String get onboardingQuestionBody => '気分は顔をひと押し。\n答えはひとことでも大丈夫です。';

  @override
  String onboardingNotifyBody(String time) {
    return '毎朝$timeに、その日の問いをお知らせします。\n時刻は設定で変えられます。';
  }

  @override
  String get notifyAllow => '通知を受け取る';

  @override
  String get notifyLater => '今はしない';

  @override
  String get statDaysShared => '一緒に過ごしてきた日々';

  @override
  String unitDaysTight(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '日',
    );
    return '$_temp0';
  }

  @override
  String get estimateNote => '数字はみんなの平均から出した目安です。一人ひとりの人生は、数字では決まりません。';

  @override
  String get editMood => '気分';

  @override
  String get deleteDay => 'この日の記録を削除';

  @override
  String deleteDayTitle(String date) {
    return '$dateの記録を削除しますか？';
  }

  @override
  String get daysAheadRow => 'これからの日々';

  @override
  String get answerSaved => '保存しました';

  @override
  String get dataOpenErrorTitle => '記録を開けませんでした';

  @override
  String get dataOpenErrorMessage =>
      '一時的な問題かもしれません。もう一度試してください。直らないときは、端末の空き容量を確かめてから、アプリを開き直してください。';

  @override
  String get retry => 'もう一度試す';
}
