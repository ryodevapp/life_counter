import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/l10n.dart';
import '../../providers/user_settings_provider.dart';
import '../../services/life_calculator.dart';
import '../shared/app_colors.dart';
import '../shared/app_spacing.dart';
import '../shared/app_text_styles.dart';
import '../shared/app_card.dart';

/// あなたの時間セクション（プロトタイプの LifeTab time セグメント再現）
class YourTimeSection extends ConsumerWidget {
  const YourTimeSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final settings = ref.watch(userSettingsProvider);
    final birthDate = settings.birthDate;
    final formatter = numberFormatOf(l.localeName);

    if (birthDate == null) {
      return AppCard(
        child: Text(
          l.birthDateNeeded,
          textAlign: TextAlign.center,
          style: AppTextStyles.callout.copyWith(color: AppColors.textMuted),
        ),
      );
    }

    final gender = settings.gender;
    final remainingDays = LifeCalculator.remainingDays(birthDate, gender);
    final healthyRemaining =
        LifeCalculator.healthyRemainingDays(birthDate, gender);
    final age = LifeCalculator.currentAge(birthDate);
    final al = LifeCalculator.averageLifespan(gender);
    final hl = LifeCalculator.healthyLifespan(gender);
    final remainingYears = LifeCalculator.remainingYears(birthDate, gender);
    final pastAL = age >= al;
    final pastHL = age >= hl;


    if (pastAL) {
      return AppCard(
        child: Text(
          l.pastAverageSelf,
          textAlign: TextAlign.center,
          style: AppTextStyles.headline,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // これからの日々(誕生から平均までの棒は置かない。終わりを意識させすぎないため)
        AppCard(
          child: Column(
            children: [
              Text(
                formatter.format(remainingDays),
                style: AppTextStyles.display.copyWith(
                  fontSize: 44,
                  color: AppColors.accent,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(l.daysEstimateUnit(remainingDays),
                  textAlign: TextAlign.center, style: AppTextStyles.footnote),
              if (!pastHL) ...[
                const SizedBox(height: AppSpacing.l),
                // 長い1文にすると「日」だけが次の行に落ちるので、言葉と数を2行に分ける
                Text(l.healthyDaysLabel,
                    textAlign: TextAlign.center, style: AppTextStyles.footnote),
                const SizedBox(height: AppSpacing.xs),
                Text(l.aboutDays(healthyRemaining),
                    style: AppTextStyles.headline),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Padding(
          padding: const EdgeInsets.only(
              left: AppSpacing.xs, bottom: AppSpacing.s),
          child: Text(l.aheadOfYou, style: AppTextStyles.captionLabel),
        ),
        // 同じ数(夏・桜・正月)を3回並べないよう、1行にまとめた一覧にする
        AppCard(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
          child: Column(
            children: [
              _row(CupertinoIcons.sun_max, l.weekends,
                  l.aboutTimes(remainingYears * 52)),
              _divider,
              _row(CupertinoIcons.tree, l.seasons,
                  l.aboutTimesEach(remainingYears)),
              _divider,
              _row(CupertinoIcons.book, l.books,
                  l.aboutBooks(remainingYears * 50)),
              _divider,
              _row(CupertinoIcons.film, l.movies,
                  l.aboutMovies(remainingYears * 20)),
            ],
          ),
        ),
      ],
    );
  }

  static const _divider =
      Divider(height: 1, indent: 22 + AppSpacing.m, color: AppColors.divider);

  static Widget _row(IconData icon, String label, String value) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 52),
      child: Row(
        children: [
          Icon(icon, size: 22, color: AppColors.accent),
          const SizedBox(width: AppSpacing.m),
          Expanded(child: Text(label, style: AppTextStyles.body)),
          Text(value,
              style: AppTextStyles.body.copyWith(color: AppColors.textMuted)),
        ],
      ),
    );
  }
}
