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

/// 行を折らせない印(WORD JOINER。幅0で見えない)
const wordJoiner = '⁠';

/// 日本語の短いまとまりの中で行を折らせない(大きい文字で「4/月」「見/る」と割れないように)。
/// 字の間に [wordJoiner] を入れる。まとまりとまとまりの間は今までどおり折れる。
/// 画面に出す文字だけに使う。保存・書き出しの前には [stripWordJoiners] で外す
String keepTogether(String s) => s.characters.join(wordJoiner);

/// [keepTogether] や arb の文言に入れた印を外す(利用者の記録に残さない)
String stripWordJoiners(String s) => s.replaceAll(wordJoiner, '');

String _jaWeekday(DateTime d) =>
    keepTogether('（${DateFormat.E('ja_JP').format(d)}）');

/// 2026年10月16日（金） / Fri, Oct 16, 2026
String formatFullDate(DateTime d, String localeName) => _isJa(localeName)
    ? '${keepTogether('${d.year}年')}${keepTogether('${d.month}月')}'
        '${keepTogether('${d.day}日')}${_jaWeekday(d)}'
    : DateFormat('EEE, MMM d, y', 'en_US').format(d);

/// 10月16日（金） / Fri, Oct 16
String formatMonthDayWeekday(DateTime d, String localeName) => _isJa(localeName)
    ? '${keepTogether('${d.month}月')}${keepTogether('${d.day}日')}'
        '${_jaWeekday(d)}'
    : DateFormat('EEE, MMM d', 'en_US').format(d);

/// 2026年10月16日 / Oct 16, 2026
String formatDate(DateTime d, String localeName) => _isJa(localeName)
    ? '${keepTogether('${d.year}年')}${keepTogether('${d.month}月')}'
        '${keepTogether('${d.day}日')}'
    : DateFormat.yMMMd('en_US').format(d);

/// 2026年10月 / October 2026
String formatYearMonth(DateTime d, String localeName) => _isJa(localeName)
    ? '${keepTogether('${d.year}年')}${keepTogether('${d.month}月')}'
    : DateFormat.yMMMM('en_US').format(d);
