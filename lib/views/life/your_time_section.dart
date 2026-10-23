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
import '../../l10n/phrase_break.dart';

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
        child: PhraseText(
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
    final hl = LifeCalculator.healthyLifespan(gender);
    final remainingYears = LifeCalculator.remainingYears(birthDate, gender);
    // 平均寿命を越えても数字は出し、ひとこと添えるだけにする
    final pastAL = LifeCalculator.isPastAverage(birthDate, gender);
    final pastHL = age >= hl;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // これからの日々(誕生から平均までの棒は置かない。終わりを意識させすぎないため)
        AppCard(
          child: Column(
            children: [
              // 何の日数かを先に言う(数字だけだと分からないため)
              PhraseText(l.daysAheadRow, style: AppTextStyles.captionLabel),
              const SizedBox(height: AppSpacing.s),
              // 飾りの大きな数字は途中で折り返さない。大きい文字で入らないときだけ縮める
              FittedBox(
                fit: BoxFit.scaleDown,
                child: PhraseText(
                  formatter.format(remainingDays),
                  maxLines: 1,
                  style: AppTextStyles.display.copyWith(
                    fontSize: 44,
                    color: AppColors.accent,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              PhraseText(l.daysEstimateUnit(remainingDays),
                  textAlign: TextAlign.center, style: AppTextStyles.footnote),
              if (pastAL) ...[
                const SizedBox(height: AppSpacing.s),
                PhraseText(l.pastAverageSelf,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.footnote),
              ],
              if (!pastHL) ...[
                const SizedBox(height: AppSpacing.l),
                // 長い1文にすると「日」だけが次の行に落ちるので、言葉と数を2行に分ける
                PhraseText(l.healthyDaysLabel,
                    textAlign: TextAlign.center, style: AppTextStyles.footnote),
                const SizedBox(height: AppSpacing.xs),
                PhraseText(l.aboutDays(healthyRemaining),
                    style: AppTextStyles.headline),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Padding(
          padding: const EdgeInsets.only(
              left: AppSpacing.xs, bottom: AppSpacing.s),
          child: PhraseText(l.aheadOfYou, style: AppTextStyles.captionLabel),
        ),
        // 同じ数(夏・桜・正月)を3回並べないよう、1行にまとめた一覧にする
        AppCard(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
          child: Column(
            children: [
              _row(context, CupertinoIcons.sun_max, l.weekends,
                  l.aboutTimes(remainingYears * 52)),
              _divider,
              _row(context, CupertinoIcons.tree, l.seasons,
                  l.aboutTimesEach(remainingYears)),
              _divider,
              _row(context, CupertinoIcons.book, l.books,
                  l.aboutBooks(remainingYears * 50)),
              _divider,
              _row(context, CupertinoIcons.film, l.movies,
                  l.aboutMovies(remainingYears * 20)),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.l),
        // 平均から出した目安だと、静かに添える
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
          child: PhraseText(l.estimateNote, style: AppTextStyles.footnote),
        ),
      ],
    );
  }

  static Widget get _divider =>
      Divider(height: 1, indent: 22 + AppSpacing.m, color: AppColors.divider);

  static Widget _row(
      BuildContext context, IconData icon, String label, String value) {
    final labelText = PhraseText(label, style: AppTextStyles.body);
    final valueText = PhraseText(value,
        style: AppTextStyles.body.copyWith(color: AppColors.textMuted));
    // 大きい文字では言葉と数が横に入らないので、言葉の下に数を積む
    final stacked = AppTextStyles.isAccessibilitySize(context);
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 52),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: stacked ? AppSpacing.s : 0),
        child: Row(
          children: [
            Icon(icon, size: 22, color: AppColors.accent),
            const SizedBox(width: AppSpacing.m),
            if (stacked)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [labelText, valueText],
                ),
              )
            else ...[
              Expanded(child: labelText),
              valueText,
            ],
          ],
        ),
      ),
    );
  }
}
