import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/important_person.dart';
import '../../providers/user_settings_provider.dart';
import '../../services/life_calculator.dart';
import '../../utils/freq_label.dart';
import '../shared/action_buttons.dart';
import '../shared/app_colors.dart';
import '../shared/app_spacing.dart';
import '../shared/app_text_styles.dart';
import '../shared/app_card.dart';

/// 大切な人の詳細画面（プロトタイプの showPD 再現）
class ImportantPersonDetailPage extends ConsumerWidget {
  const ImportantPersonDetailPage({
    super.key,
    required this.person,
    required this.onBack,
    required this.onEdit,
    required this.onDelete,
  });

  final ImportantPerson person;
  final VoidCallback onBack;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(userSettingsProvider);
    final myBirthDate = settings.birthDate;
    if (myBirthDate == null) return const SizedBox.shrink();

    final myAge = LifeCalculator.currentAge(myBirthDate);
    final myAL = LifeCalculator.averageLifespan(settings.gender);

    final pAge = LifeCalculator.currentAge(person.birthDate);
    final pAL = LifeCalculator.averageLifespan(person.gender);
    final pHL = LifeCalculator.healthyLifespan(person.gender);
    final pPastAL = pAge >= pAL;

    final myRemaining = (myAL - myAge).clamp(0, 999).floor();
    final pRemaining = (pAL - pAge).clamp(0, 999).floor();
    final together = (myRemaining < pRemaining ? myRemaining : pRemaining)
        .clamp(0, 999);
    final meetCount = calcMeetCount(together, person.meetingFrequency);
    final pHealthRemaining = (pHL - pAge).clamp(0, 999).floor();

    final lastMetDays = person.lastMetDate != null
        ? DateTime.now().difference(person.lastMetDate!).inDays
        : null;

    final fmt = NumberFormat('#,###', 'ja_JP');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 戻るボタン
        TextButton(
          onPressed: onBack,
          style: _textButtonStyle.copyWith(
              padding: const WidgetStatePropertyAll(EdgeInsets.zero)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(CupertinoIcons.chevron_left,
                  size: 18, color: AppColors.accent),
              Text('大切な人',
                  style: AppTextStyles.body.copyWith(color: AppColors.accent)),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.s),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(person.nickname, style: AppTextStyles.title),
                  const SizedBox(height: AppSpacing.xs),
                  Text('$pAge歳', style: AppTextStyles.footnote),
                ],
              ),
            ),
            TextButton(
              onPressed: onEdit,
              style: _textButtonStyle,
              child: Text('編集',
                  style: AppTextStyles.body.copyWith(color: AppColors.accent)),
            ),
            TextButton(
              onPressed: () async {
                final confirmed = await showDeleteConfirmation(
                  context,
                  title: '${person.nickname}を削除しますか？',
                );
                if (confirmed) onDelete();
              },
              style: _textButtonStyle,
              child: Text('削除',
                  style: AppTextStyles.body.copyWith(color: AppColors.danger)),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),

        if (pPastAL)
          AppCard(
            child: Center(
              child: Text(
                '平均の年齢を超えて、日々を重ねています',
                textAlign: TextAlign.center,
                style: AppTextStyles.callout
                    .copyWith(color: AppColors.textSecondary),
              ),
            ),
          )
        else ...[
          _statCard('これから', '$pRemaining', '年'),
          if (pHealthRemaining > 0) ...[
            const SizedBox(height: AppSpacing.cardGap),
            _statCard('元気に過ごせる目安', '$pHealthRemaining', '年'),
          ],
          const SizedBox(height: AppSpacing.cardGap),
          _statCard('一緒にいられる年数', '$together', '年',
              sub: 'ふたりの平均のうち、短いほうで計算'),
          const SizedBox(height: AppSpacing.cardGap),
          _statCard('これから会える回数', fmt.format(meetCount), '回',
              sub: '${freqToLabel(person.meetingFrequency)}会うとして',
              valueColor: AppColors.accent),
          if (lastMetDays != null) ...[
            const SizedBox(height: AppSpacing.cardGap),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('最後に会ってから', style: AppTextStyles.captionLabel),
                  const SizedBox(height: AppSpacing.s),
                  Text.rich(
                    TextSpan(children: [
                      TextSpan(
                        text: '$lastMetDays',
                        style: AppTextStyles.display.copyWith(
                          color: AppColors.text,
                        ),
                      ),
                      TextSpan(text: ' 日', style: AppTextStyles.footnote),
                    ]),
                  ),
                ],
              ),
            ),
          ],
        ],
      ],
    );
  }

  static final _textButtonStyle = TextButton.styleFrom(
    minimumSize: const Size(AppSpacing.minTap, AppSpacing.minTap),
    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s),
  );

  static Widget _statCard(String label, String value, String unit,
      {String? sub, Color? valueColor}) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.captionLabel),
          const SizedBox(height: AppSpacing.s),
          Text.rich(
            TextSpan(children: [
              TextSpan(text: '約 ', style: AppTextStyles.footnote),
              TextSpan(
                text: value,
                style: AppTextStyles.display
                    .copyWith(color: valueColor ?? AppColors.text),
              ),
              TextSpan(text: ' $unit', style: AppTextStyles.footnote),
            ]),
            textAlign: TextAlign.left,
          ),
          if (sub != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(sub, style: AppTextStyles.footnote),
          ],
        ],
      ),
    );
  }

}
