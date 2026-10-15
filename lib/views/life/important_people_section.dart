import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
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
        child: Text('データの読み込みに失敗しました',
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

  Widget _emptyState() {
    return AppCard(
      child: Column(
        children: [
          Text(
            '大切な人を登録すると、一緒にいられる時間の目安が見られます',
            textAlign: TextAlign.center,
            style: AppTextStyles.callout.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: AppSpacing.l),
          AppButton.primary(onPressed: _addPerson, label: '追加する'),
        ],
      ),
    );
  }

  Widget _personList(List<ImportantPerson> persons, DateTime? myBirthDate,
      UserSettings settings) {
    final fmt = NumberFormat('#,###', 'ja_JP');
    final myAge = myBirthDate != null
        ? LifeCalculator.currentAge(myBirthDate)
        : 0;
    final myAL = myBirthDate != null
        ? LifeCalculator.averageLifespan(settings.gender)
        : 84.07;

    return Column(
      children: [
        for (final p in persons) ...[
          _personCard(p, myAge, myAL, fmt),
          const SizedBox(height: AppSpacing.cardGap),
        ],
        // 追加ボタン
        AppButton.secondary(onPressed: _addPerson, label: '+ 大切な人を追加'),
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

    return AppCard(
      onTap: () => setState(() => _selectedPerson = p),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(p.nickname, style: AppTextStyles.headline),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.s, vertical: AppSpacing.xs),
                decoration: BoxDecoration(
                  color: AppColors.bgWarm,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Text('$pAge歳', style: AppTextStyles.captionLabel),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.l),
          if (pPastAL)
            Text(
              '${p.nickname}と過ごす毎日が、かけがえのない時間です',
              style: AppTextStyles.callout
                  .copyWith(color: AppColors.textSecondary),
            )
          else ...[
            Row(
              children: [
                Expanded(
                    child: _miniStat('これから', '${pR.floor()}', '年(目安)')),
                const SizedBox(width: AppSpacing.m),
                Expanded(
                    child: pHR > 0
                        ? _miniStat('元気でいられる時間', '$pHR', '年',
                            valueColor: AppColors.accent)
                        : const SizedBox.shrink()),
              ],
            ),
            const SizedBox(height: AppSpacing.m),
            Row(
              children: [
                Expanded(
                    child:
                        _miniStat('一緒にいられる年数', '$together', '年')),
                const SizedBox(width: AppSpacing.m),
                Expanded(
                    child: _miniStat('会える残り回数', fmt.format(meet), '回',
                        valueColor: AppColors.accent)),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.m),
          Text('詳しく見る \u2192', style: AppTextStyles.footnote),
        ],
      ),
    );
  }

  static Widget _miniStat(String label, String value, String unit,
      {Color? valueColor}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(label, style: AppTextStyles.captionLabel),
        const SizedBox(height: AppSpacing.xs),
        Text.rich(TextSpan(children: [
          TextSpan(text: '約', style: AppTextStyles.captionLabel),
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
