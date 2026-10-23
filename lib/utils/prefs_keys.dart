/// SharedPreferences のキー定数（一元管理）
class PrefsKeys {
  PrefsKeys._();

  /// v1.1.4 までの誕生日(時刻の一点のミリ秒)。互換のために書き続ける
  static const birthDate = 'birth_date';
  /// 誕生日の「yyyy-MM-dd」(LC-30)。読むときはこちらを先に使う
  static const birthDayKey = 'birth_day_key';
  static const gender = 'gender';
  static const onboardingCompleted = 'onboarding_completed';
  static const notificationEnabled = 'notification_enabled';
  static const notificationHour = 'notification_hour';
  static const notificationMinute = 'notification_minute';
  static const nightModeHour = 'night_mode_hour';
  static const nightModeMinute = 'night_mode_minute';
  static const recentQuestionIds = 'recent_question_ids';
  /// 記録の dayKey を埋める移行を済ませたか(v1.1.1)
  static const dayKeyMigrated = 'day_key_migrated_v1';
  /// 誕生日・大切な人の日付を dayKey に移す移行を済ませたか(LC-30)
  static const birthDayKeyMigrated = 'birth_day_key_migrated_v1';
}
