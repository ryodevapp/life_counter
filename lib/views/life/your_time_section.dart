import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../providers/user_settings_provider.dart';
import '../../services/life_calculator.dart';
import '../shared/app_colors.dart';
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
        padding: const EdgeInsets.all(40),
        child: Center(
          child: Text(
            'オンボーディング完了後に表示されます',
            style: AppTextStyles.caption
                .copyWith(color: AppColors.textDisabled),
          ),
        ),
      );
    }

    final gender = settings.gender;
    final lifeDays = LifeCalculator.lifeDays(birthDate);
    final remainingDays = LifeCalculator.remainingDays(birthDate, gender);
    final healthyRemaining =
        LifeCalculator.healthyRemainingDays(birthDate, gender);
    final age = LifeCalculator.currentAge(birthDate);
    final hl = LifeCalculator.healthyLifespan(gender);
    final remainingYears = LifeCalculator.remainingYears(birthDate, gender);
    final pastHL = age >= hl;

    // プログレスバーの割合
    final lifePct = lifeDays / (lifeDays + remainingDays);

    return Column(
      children: [
        // 残り日数メインカード
        AppCard(
          child: Column(
            children: [
              Text(
                formatter.format(remainingDays),
                style: AppTextStyles.displayMedium.copyWith(
                  color: AppColors.accent,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '日　これからの時間の目安',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
              if (!pastHL) ...[
                const SizedBox(height: 16),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: 'そのうち、元気に動ける時間は約 ',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      TextSpan(
                        text: formatter.format(healthyRemaining),
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.accent,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      TextSpan(
                        text: ' 日',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),

              // 平均寿命プログレスバー
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
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
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('誕生', style: _barLabel),
                  Text('平均余命', style: _barLabel),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // 残りの○○グリッド
        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          // 小さい画面(iPhone SE)で「年50冊」の行がはみ出さないよう、少し縦長にする
          childAspectRatio: 0.9,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _remainingCard('\u2600\uFE0F', 'これからの週末', remainingYears * 52, '回'),
            _remainingCard('\u{1F33B}', 'これからの夏', remainingYears, '回'),
            _remainingCard('\u{1F338}', 'これからの桜', remainingYears, '回'),
            _remainingCard('\u{1F38D}', 'これからの正月', remainingYears, '回'),
            _remainingCard('\u{1F4DA}', '読める本', remainingYears * 50, '冊',
                sub: '年50冊'),
            _remainingCard('\u{1F3AC}', '観れる映画', remainingYears * 20, '本',
                sub: '年20本'),
          ],
        ),
      ],
    );
  }

  static final _barLabel = GoogleFonts.zenKakuGothicNew(
    fontSize: 12,
    color: AppColors.textMuted,
  );

  static Widget _remainingCard(
      String emoji, String label, int value, String unit,
      {String? sub}) {
    final formatter = NumberFormat('#,###', 'ja_JP');
    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 6),
          Text(
            label,
            style: GoogleFonts.zenKakuGothicNew(
              fontSize: 12,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            formatter.format(value),
            style: GoogleFonts.cormorantGaramond(
              fontSize: 26,
              fontWeight: FontWeight.w300,
            ),
          ),
          Text(
            unit,
            style: GoogleFonts.zenKakuGothicNew(
              fontSize: 12,
              color: AppColors.textMuted,
            ),
          ),
          if (sub != null) ...[
            const SizedBox(height: 2),
            Text(
              sub,
              style: GoogleFonts.zenKakuGothicNew(
                fontSize: 11,
                color: AppColors.textDisabled,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
