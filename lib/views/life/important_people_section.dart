import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../l10n/l10n.dart';
import '../../models/important_person.dart';
import '../../providers/important_person_provider.dart';
import '../../providers/isar_provider.dart';
import '../../models/user_settings.dart';
import '../../providers/user_settings_provider.dart';
import '../../services/life_calculator.dart';
import '../../utils/freq_label.dart';
import '../shared/app_colors.dart';
import '../shared/app_spacing.dart';
import '../shared/app_text_styles.dart';
import '../shared/app_card.dart';
import '../shared/app_button.dart';
import 'important_person_form_page.dart';
import 'important_person_detail_page.dart';

/// 大切な人セクション（プロトタイプの people セグメント再現）
class ImportantPeopleSection extends ConsumerStatefulWidget {
  const ImportantPeopleSection({super.key});

  @override
  ConsumerState<ImportantPeopleSection> createState() =>
      _ImportantPeopleSectionState();
}

class _ImportantPeopleSectionState
    extends ConsumerState<ImportantPeopleSection> {
  ImportantPerson? _selectedPerson;

  Future<void> _addPerson() async {
    final result = await ImportantPersonFormPage.show(context);
    if (result != null) {
      await ref.read(importantPersonRepositoryProvider).add(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    // 詳細画面
    if (_selectedPerson != null) {
      return ImportantPersonDetailPage(
        person: _selectedPerson!,
        onBack: () => setState(() => _selectedPerson = null),
        onEdit: () async {
          final result = await ImportantPersonFormPage.show(
            context,
            person: _selectedPerson,
          );
          if (result != null) {
            final repo = ref.read(importantPersonRepositoryProvider);
            await repo.update(result);
            setState(() => _selectedPerson = result);
          }
        },
        onDelete: () async {
          final repo = ref.read(importantPersonRepositoryProvider);
          await repo.delete(_selectedPerson!.id);
          setState(() => _selectedPerson = null);
        },
      );
    }

    final personsAsync = ref.watch(importantPersonsProvider);
    final settings = ref.watch(userSettingsProvider);
    final myBirthDate = settings.birthDate;

    return personsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => AppCard(
        child: Text(context.l10n.loadError,
            textAlign: TextAlign.center,
            style:
                AppTextStyles.callout.copyWith(color: AppColors.textMuted)),
      ),
      data: (persons) {
        if (persons.isEmpty) return _emptyState();
        return _personList(persons, myBirthDate, settings);
      },
    );
  }

  // 空のときはカードにせず、説明1文と追加のボタンだけ(画面でいちばん重い物にしない)
  Widget _emptyState() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.peopleEmpty,
          style: AppTextStyles.callout.copyWith(color: AppColors.textMuted),
        ),
        const SizedBox(height: AppSpacing.l),
        _addButton(),
      ],
    );
  }

  Widget _addButton() => AppButton(
        onPressed: _addPerson,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(CupertinoIcons.add, size: 18, color: AppColors.accent),
            const SizedBox(width: AppSpacing.s),
            Text(context.l10n.addPerson),
          ],
        ),
      );

  Widget _personList(List<ImportantPerson> persons, DateTime? myBirthDate,
      UserSettings settings) {
    final fmt = numberFormatOf(context.l10n.localeName);
    final myAge = myBirthDate != null
        ? LifeCalculator.currentAge(myBirthDate)
        : 0;
    final myAL = LifeCalculator.averageLifespan(
        myBirthDate != null ? settings.gender : Gender.unspecified);

    return Column(
      children: [
        for (final p in persons) ...[
          _personCard(p, myAge, myAL, fmt),
          const SizedBox(height: AppSpacing.cardGap),
        ],
        _addButton(),
      ],
    );
  }

  Widget _personCard(
      ImportantPerson p, int myAge, double myAL, NumberFormat fmt) {
    final pAge = LifeCalculator.currentAge(p.birthDate);
    final pAL = LifeCalculator.averageLifespan(p.gender);
    final pHL = LifeCalculator.healthyLifespan(p.gender);
    final pPastAL = pAge >= pAL;
    final myR = (myAL - myAge).clamp(0, 999);
    final pR = (pAL - pAge).clamp(0, 999);
    final together = myR < pR ? myR.floor() : pR.floor();
    final meet = calcMeetCount(together, p.meetingFrequency);
    final pHR = (pHL - pAge).clamp(0, 999).floor();
    final l = context.l10n;
    final years = pR.floor();

    return AppCard(
      onTap: () => setState(() => _selectedPerson = p),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text.rich(TextSpan(children: [
                  TextSpan(text: p.nickname, style: AppTextStyles.headline),
                  TextSpan(
                      text: '  ${l.ageYears(pAge)}',
                      style: AppTextStyles.footnote),
                ])),
              ),
              const Icon(CupertinoIcons.chevron_right,
                  size: 15, color: AppColors.textDisabled),
            ],
          ),
          if (!pPastAL) ...[
            const SizedBox(height: AppSpacing.l),
            Row(
              children: [
                Expanded(
                    child: _miniStat(l, l.statYearsAhead, '$years',
                        l.unitYearsTight(years))),
                const SizedBox(width: AppSpacing.m),
                Expanded(
                    child: pHR > 0
                        ? _miniStat(l, l.statHealthyYears, '$pHR',
                            l.unitYearsTight(pHR),
                            valueColor: AppColors.accent)
                        : const SizedBox.shrink()),
              ],
            ),
            const SizedBox(height: AppSpacing.m),
            Row(
              children: [
                Expanded(
                    child: _miniStat(l, l.statYearsTogether, '$together',
                        l.unitYearsTight(together))),
                const SizedBox(width: AppSpacing.m),
                Expanded(
                    child: _miniStat(l, l.statMeetCount, fmt.format(meet),
                        l.unitTimesTight(meet),
                        valueColor: AppColors.accent)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  static Widget _miniStat(
      AppLocalizations l, String label, String value, String unit,
      {Color? valueColor}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(label, style: AppTextStyles.captionLabel),
        const SizedBox(height: AppSpacing.xs),
        Text.rich(TextSpan(children: [
          TextSpan(text: l.approxTight, style: AppTextStyles.captionLabel),
          TextSpan(
            text: value,
            style: AppTextStyles.display
                .copyWith(color: valueColor ?? AppColors.text),
          ),
          TextSpan(text: unit, style: AppTextStyles.captionLabel),
        ])),
      ],
    );
  }
}
