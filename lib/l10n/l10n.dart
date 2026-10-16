import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'app_localizations.dart';

export 'app_localizations.dart';

/// 端末の言語が日本語なら日本語、それ以外はすべて英語
Locale resolveAppLocale(Locale? device) =>
    device?.languageCode == 'ja' ? const Locale('ja') : const Locale('en');

/// BuildContext がない所(通知・書き出しなど)で使う文言。ja / en 以外は英語
AppLocalizations appLocalizationsFor(String languageCode) =>
    lookupAppLocalizations(resolveAppLocale(Locale(languageCode)));

extension AppL10nContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

bool _isJa(String localeName) => localeName.startsWith('ja');

/// intl の日付・数の書式に渡す地域名
String intlLocaleOf(String localeName) => _isJa(localeName) ? 'ja_JP' : 'en_US';

/// 3桁ごとの区切り(12,617)
NumberFormat numberFormatOf(String localeName) =>
    NumberFormat.decimalPattern(intlLocaleOf(localeName));

/// 2026年10月16日（金） / Fri, Oct 16, 2026
String formatFullDate(DateTime d, String localeName) => _isJa(localeName)
    ? '${d.year}年${d.month}月${d.day}日（${DateFormat.E('ja_JP').format(d)}）'
    : DateFormat('EEE, MMM d, y', 'en_US').format(d);

/// 10月16日（金） / Fri, Oct 16
String formatMonthDayWeekday(DateTime d, String localeName) => _isJa(localeName)
    ? '${d.month}月${d.day}日（${DateFormat.E('ja_JP').format(d)}）'
    : DateFormat('EEE, MMM d', 'en_US').format(d);

/// 2026年10月16日 / Oct 16, 2026
String formatDate(DateTime d, String localeName) => _isJa(localeName)
    ? '${d.year}年${d.month}月${d.day}日'
    : DateFormat.yMMMd('en_US').format(d);

/// 2026年10月 / October 2026
String formatYearMonth(DateTime d, String localeName) => _isJa(localeName)
    ? '${d.year}年${d.month}月'
    : DateFormat.yMMMM('en_US').format(d);
