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
import '../../l10n/phrase_break.dart';

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
        child: PhraseText(context.l10n.loadError,
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
        PhraseText(
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
            Icon(CupertinoIcons.add, size: 18, color: AppColors.accent),
            const SizedBox(width: AppSpacing.s),
            // 大きい文字では折り返す(操作の文字は切らない)
            Flexible(
                child: PhraseText(context.l10n.addPerson,
                    textAlign: TextAlign.center)),
          ],
        ),
      );

  Widget _personList(List<ImportantPerson> persons, DateTime? myBirthDate,
      UserSettings settings) {
    final fmt = numberFormatOf(context.l10n.localeName);
    // 自分の「これから」(その年齢の平均余命)。生年月日がまだなら上限なし
    final myAhead = myBirthDate != null
        ? LifeCalculator.expectedYearsAhead(myBirthDate, settings.gender)
        : double.infinity;

    return Column(
      children: [
        for (final p in persons) ...[
          _personCard(p, myAhead, myBirthDate, fmt),
          const SizedBox(height: AppSpacing.cardGap),
        ],
        _addButton(),
      ],
    );
  }

  Widget _personCard(ImportantPerson p, double myAhead, DateTime? myBirthDate,
      NumberFormat fmt) {
    final pAge = LifeCalculator.currentAge(p.birthDate);
    final pAhead = LifeCalculator.expectedYearsAhead(p.birthDate, p.gender);
    final pPastAL = LifeCalculator.isPastAverage(p.birthDate, p.gender);
    final together = (myAhead < pAhead ? myAhead : pAhead).floor();
    final meet = calcMeetCount(together, p.meetingFrequency);
    final l = context.l10n;

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
              Icon(CupertinoIcons.chevron_right,
                  size: 15, color: AppColors.textDisabled),
            ],
          ),
          // 平均寿命を越えた人にも数字は出し、ひとこと添えるだけにする
          if (pPastAL) ...[
            const SizedBox(height: AppSpacing.s),
            PhraseText(l.pastAveragePerson, style: AppTextStyles.footnote),
          ],
          // 主役は「これから会える回数」。重なりやすい「これから」と「一緒に過ごしてきた日々」は詳しい画面だけに
          const SizedBox(height: AppSpacing.l),
          PhraseText(l.statMeetCount, style: AppTextStyles.captionLabel),
          const SizedBox(height: AppSpacing.xs),
          Text.rich(TextSpan(children: [
            TextSpan(text: l.approxTight, style: AppTextStyles.captionLabel),
            TextSpan(
              text: fmt.format(meet),
              style: AppTextStyles.display
                  .copyWith(fontSize: 40, color: AppColors.accent),
            ),
            TextSpan(text: l.unitTimesTight(meet), style: AppTextStyles.captionLabel),
          ])),
          const SizedBox(height: AppSpacing.s),
          PhraseText(
            '${l.statYearsTogether}  ${l.approxTight}$together${l.unitYearsTight(together)}',
            style: AppTextStyles.footnote,
          ),
        ],
      ),
    );
  }
}

/// 一緒に過ごしてきた日数(ふたりのうち、あとに生まれた人の誕生日から今日まで)
int? sharedDays(DateTime? myBirth, DateTime theirBirth) {
  if (myBirth == null) return null;
  final start = myBirth.isAfter(theirBirth) ? myBirth : theirBirth;
  return DateTime.now().difference(start).inDays + 1;
}
