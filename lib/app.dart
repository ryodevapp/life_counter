import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'l10n/l10n.dart';
import 'router/app_router.dart';
import 'views/shared/app_colors.dart';
import 'views/shared/app_text_styles.dart';

class LifeCounterApp extends ConsumerWidget {
  const LifeCounterApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    // 端末の明るい表示・暗い表示に合わせる。切り替わったら画面全体を作り直して、色を入れ替える
    final dark = MediaQuery.platformBrightnessOf(context) == Brightness.dark;
    AppColors.dark = dark;

    return MaterialApp.router(
      title: 'LifeCounter',
      debugShowCheckedModeBanner: false,
      // 端末が日本語なら日本語、それ以外は英語
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('ja'), Locale('en')],
      localeResolutionCallback: (locale, _) => resolveAppLocale(locale),
      theme: ThemeData(
        brightness: dark ? Brightness.dark : Brightness.light,
        scaffoldBackgroundColor: AppColors.bg,
        fontFamilyFallback: AppTextStyles.jpFallback,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.accent,
          brightness: dark ? Brightness.dark : Brightness.light,
          surface: AppColors.bg,
        ),
      ),
      builder: (context, child) =>
          KeyedSubtree(key: ValueKey(dark), child: child ?? const SizedBox()),
      routerConfig: router,
    );
  }
}
