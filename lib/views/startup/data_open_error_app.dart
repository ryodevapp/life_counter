import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import '../../l10n/l10n.dart';
import '../shared/app_button.dart';
import '../shared/app_colors.dart';
import '../shared/app_spacing.dart';
import '../shared/app_text_styles.dart';

/// 記録(データベース)を開けなかったときの画面。落とさずに、もう一度試せるようにする
class DataOpenErrorApp extends StatelessWidget {
  const DataOpenErrorApp({super.key, required this.onRetry});

  /// もう一度開いてみる。終わるまでボタンは押せない
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final dark = MediaQuery.platformBrightnessOf(context) == Brightness.dark;
    AppColors.dark = dark;
    return MaterialApp(
      debugShowCheckedModeBanner: false,
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
      ),
      home: DataOpenErrorPage(onRetry: onRetry),
    );
  }
}

class DataOpenErrorPage extends StatefulWidget {
  const DataOpenErrorPage({super.key, required this.onRetry});

  final Future<void> Function() onRetry;

  @override
  State<DataOpenErrorPage> createState() => _DataOpenErrorPageState();
}

class _DataOpenErrorPageState extends State<DataOpenErrorPage> {
  bool _busy = false;

  Future<void> _retry() async {
    setState(() => _busy = true);
    try {
      await widget.onRetry();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      // 最大の文字では1画面に入らないので、ふだんは中央に置き、入らないときだけ送れるようにする
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.screen),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - AppSpacing.screen * 2),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(l.dataOpenErrorTitle,
                      style: AppTextStyles.title, textAlign: TextAlign.center),
                  const SizedBox(height: AppSpacing.l),
                  Text(l.dataOpenErrorMessage,
                      style: AppTextStyles.body, textAlign: TextAlign.center),
                  const SizedBox(height: AppSpacing.xxl),
                  AppButton.primary(
                    onPressed: _busy ? null : _retry,
                    label: l.retry,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
