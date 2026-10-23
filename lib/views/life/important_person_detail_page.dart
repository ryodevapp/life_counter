import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/l10n.dart';
import '../../models/important_person.dart';
import 'important_people_section.dart' show sharedDays;
import '../../providers/user_settings_provider.dart';
import '../../services/life_calculator.dart';
import '../../utils/freq_label.dart';
import '../shared/action_buttons.dart';
import '../shared/app_colors.dart';
import '../shared/app_spacing.dart';
import '../shared/app_text_styles.dart';
import '../shared/app_card.dart';
import '../../l10n/phrase_break.dart';

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

    final pAge = LifeCalculator.currentAge(person.birthDay);
    final pPastAL = LifeCalculator.isPastAverage(person.birthDay, person.gender);
    // これからの年数は、その年齢の平均余命(生命表)から
    final myAhead =
        LifeCalculator.expectedYearsAhead(myBirthDate, settings.gender);
    final pAhead =
        LifeCalculator.expectedYearsAhead(person.birthDay, person.gender);
    final pRemaining = pAhead.floor();
    final together = (myAhead < pAhead ? myAhead : pAhead).floor();
    final meetCount = calcMeetCount(together, person.meetingFrequency);
    final shared = sharedDays(myBirthDate, person.birthDay);

    final lastMetDays = person.lastMetDay != null
        ? DateTime.now().difference(person.lastMetDay!).inDays
        : null;

    final l = context.l10n;
    final fmt = numberFormatOf(l.localeName);

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
              Icon(CupertinoIcons.chevron_left,
                  size: 18, color: AppColors.accent),
              PhraseText(l.peopleWhoMatter,
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
                  PhraseText(person.nickname, style: AppTextStyles.title),
                  const SizedBox(height: AppSpacing.xs),
                  PhraseText(l.ageYears(pAge), style: AppTextStyles.footnote),
                ],
              ),
            ),
            TextButton(
              onPressed: onEdit,
              style: _textButtonStyle,
              child: PhraseText(l.edit,
                  style: AppTextStyles.body.copyWith(color: AppColors.accent)),
            ),
            TextButton(
              onPressed: () async {
                final confirmed = await showDeleteConfirmation(
                  context,
                  title: l.deletePersonTitle(person.nickname),
                );
                if (confirmed) onDelete();
              },
              style: _textButtonStyle,
              child: PhraseText(l.delete,
                  style: AppTextStyles.body.copyWith(color: AppColors.danger)),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),

        // 平均寿命を越えた人にも数字は出し、ひとこと添えるだけにする
        if (pPastAL) ...[
          PhraseText(l.pastAveragePerson,
              style: AppTextStyles.callout
                  .copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: AppSpacing.m),
        ],
        ...[
          _statCard(l, l.statYearsAhead, '$pRemaining',
              l.unitYearsSpaced(pRemaining)),
          if (shared != null) ...[
            const SizedBox(height: AppSpacing.cardGap),
            _statCard(l, l.statDaysShared, fmt.format(shared),
                l.unitDaysSpaced(shared),
                approx: false),
          ],
          const SizedBox(height: AppSpacing.cardGap),
          _statCard(l, l.statYearsTogether, '$together',
              l.unitYearsSpaced(together),
              sub: l.togetherNote),
          const SizedBox(height: AppSpacing.cardGap),
          _statCard(l, l.statMeetCount, fmt.format(meetCount),
              l.unitTimesSpaced(meetCount),
              sub: l.meetNote(
                  localizedFreqLabel(l, person.meetingFrequency)),
              valueColor: AppColors.accent),
          if (lastMetDays != null) ...[
            const SizedBox(height: AppSpacing.cardGap),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PhraseText(l.sinceLastMet, style: AppTextStyles.captionLabel),
                  const SizedBox(height: AppSpacing.s),
                  Text.rich(
                    TextSpan(children: [
                      TextSpan(
                        text: '$lastMetDays',
                        style: AppTextStyles.display.copyWith(
                          color: AppColors.text,
                        ),
                      ),
                      TextSpan(
                          text: l.unitDaysSpaced(lastMetDays),
                          style: AppTextStyles.footnote),
                    ]),
                  ),
                ],
              ),
            ),
          ],
        ],
        const SizedBox(height: AppSpacing.l),
        // 平均から出した目安だと、静かに添える
        PhraseText(l.estimateNote, style: AppTextStyles.footnote),
      ],
    );
  }

  static final _textButtonStyle = TextButton.styleFrom(
    minimumSize: const Size(AppSpacing.minTap, AppSpacing.minTap),
    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s),
  );

  /// [unit] は前の空白も含めて渡す(「 年」「 years」)
  static Widget _statCard(
      AppLocalizations l, String label, String value, String unit,
      {String? sub, Color? valueColor, bool approx = true}) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PhraseText(label, style: AppTextStyles.captionLabel),
          const SizedBox(height: AppSpacing.s),
          Text.rich(
            TextSpan(children: [
              if (approx)
                TextSpan(text: l.approxSpaced, style: AppTextStyles.footnote),
              TextSpan(
                text: value,
                style: AppTextStyles.display
                    .copyWith(color: valueColor ?? AppColors.text),
              ),
              TextSpan(text: unit, style: AppTextStyles.footnote),
            ]),
            textAlign: TextAlign.left,
          ),
          if (sub != null) ...[
            const SizedBox(height: AppSpacing.xs),
            PhraseText(sub, style: AppTextStyles.footnote),
          ],
        ],
      ),
    );
  }

}
