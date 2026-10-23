import 'package:flutter/material.dart';
import '../../l10n/l10n.dart';
import '../shared/app_button.dart';
import '../shared/app_colors.dart';
import '../shared/app_spacing.dart';
import '../shared/readable_width.dart';
import '../shared/app_text_styles.dart';
import '../../l10n/phrase_break.dart';

/// はじめに(何のアプリかを1つの問いかけと2行で伝える)
class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key, required this.onStart});

  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
          child: ReadableWidth(
            child: Column(
              children: [
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // ブランドの表示なので英字のまま。字間だけはロゴとして広げる
                          PhraseText(
                            'LIFE COUNTER',
                            style: AppTextStyles.captionLabel
                                .copyWith(letterSpacing: 3),
                          ),
                          const SizedBox(height: AppSpacing.xxl),
                          PhraseText(
                            l.welcomeTitle,
                            textAlign: TextAlign.center,
                            style: AppTextStyles.title,
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          PhraseText(
                            l.welcomeBody,
                            textAlign: TextAlign.center,
                            style: AppTextStyles.callout
                                .copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                AppButton.primary(onPressed: onStart, label: l.getStarted),
                const SizedBox(height: AppSpacing.xxl),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
