import 'package:flutter/widgets.dart';

/// アプリで使う言語。端末の言語が日本語なら 'ja'、それ以外は 'en'
/// (画面の言葉・問い・通知・ウィジェットで同じ決まりにする)
String appLanguageCode([Locale? locale]) =>
    (locale ?? WidgetsBinding.instance.platformDispatcher.locale).languageCode == 'ja'
        ? 'ja'
        : 'en';
