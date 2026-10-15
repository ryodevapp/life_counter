import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
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
    final settings = ref.watch(userSettingsProvider);
    final birthDate = settings.birthDate;
    final formatter = NumberFormat('#,###', 'ja_JP');

    if (birthDate == null) {
      return AppCard(
        child: Text(
          'オンボーディング完了後に表示されます',
          textAlign: TextAlign.center,
          style: AppTextStyles.callout.copyWith(color: AppColors.textMuted),
        ),
      );
    }

    final gender = settings.gender;
    final lifeDays = LifeCalculator.lifeDays(birthDate);
    final remainingDays = LifeCalculator.remainingDays(birthDate, gender);
    final healthyRemaining =
        LifeCalculator.healthyRemainingDays(birthDate, gender);
    final age = LifeCalculator.currentAge(birthDate);
    final al = LifeCalculator.averageLifespan(gender);
    final hl = LifeCalculator.healthyLifespan(gender);
    final remainingYears = LifeCalculator.remainingYears(birthDate, gender);
    final pastAL = age >= al;
    final pastHL = age >= hl;

    // プログレスバーの割合
    final lifePct = lifeDays / (lifeDays + remainingDays);

    if (pastAL) {
      return AppCard(
        child: Text(
          '平均を超えて生きている、\nすばらしい人生です',
          textAlign: TextAlign.center,
          style: AppTextStyles.headline,
        ),
      );
    }

    return Column(
      children: [
        // 残り日数メインカード
        AppCard(
          child: Column(
            children: [
              Text(
                formatter.format(remainingDays),
                style: AppTextStyles.display.copyWith(
                  color: AppColors.accent,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '日(平均までの目安)',
                style: AppTextStyles.footnote,
              ),
              if (!pastHL) ...[
                const SizedBox(height: AppSpacing.l),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: 'そのうち、健康でいられるのは約 ',
                        style: AppTextStyles.callout.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      TextSpan(
                        text: formatter.format(healthyRemaining),
                        style: AppTextStyles.callout.copyWith(
                          color: AppColors.accent,
                        ),
                      ),
                      TextSpan(
                        text: ' 日',
                        style: AppTextStyles.callout.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.l),

              // 誕生から平均までの棒
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.full),
                child: SizedBox(
                  height: 8,
                  child: LinearProgressIndicator(
                    value: lifePct.clamp(0.0, 1.0),
                    backgroundColor: AppColors.bgSub,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.accent,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.s),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('誕生', style: _barLabel),
                  Text('平均', style: _barLabel),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.cardGap),

        // 残りの○○グリッド
        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: AppSpacing.cardGap,
          mainAxisSpacing: AppSpacing.cardGap,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _remainingCard('\u2600\uFE0F', '残りの週末', remainingYears * 52, '回'),
            _remainingCard('\u{1F33B}', '残りの夏', remainingYears, '回'),
            _remainingCard('\u{1F338}', '残りの桜', remainingYears, '回'),
            _remainingCard('\u{1F38D}', '残りの正月', remainingYears, '回'),
            _remainingCard('\u{1F4DA}', '読める本', remainingYears * 50, '冊',
                sub: '年50冊'),
            _remainingCard('\u{1F3AC}', '観れる映画', remainingYears * 20, '本',
                sub: '年20本'),
          ],
        ),
      ],
    );
  }

  static final _barLabel = AppTextStyles.captionLabel;

  static Widget _remainingCard(
      String emoji, String label, int value, String unit,
      {String? sub}) {
    final formatter = NumberFormat('#,###', 'ja_JP');
    return AppCard(
      // 2列の正方形のマスに数字・単位・補足を収めるため、内側は card(20)より狭い l(16)
      padding: const EdgeInsets.all(AppSpacing.l),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(emoji, style: AppTextStyles.headline),
          const SizedBox(height: AppSpacing.xs),
          Text(label, style: AppTextStyles.captionLabel),
          const SizedBox(height: AppSpacing.xs),
          Text(formatter.format(value), style: AppTextStyles.display),
          Text(unit, style: AppTextStyles.captionLabel),
          if (sub != null) Text(sub, style: AppTextStyles.captionLabel),
        ],
      ),
    );
  }
}
