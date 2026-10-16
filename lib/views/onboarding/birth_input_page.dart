import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../l10n/l10n.dart';
import '../../models/important_person.dart';
import '../shared/app_colors.dart';
import '../shared/app_spacing.dart';
import '../shared/app_text_styles.dart';
import '../shared/app_button.dart';

/// 生年月日と性別(任意)。人生の日数と、平均からの目安に使う
class BirthInputPage extends StatefulWidget {
  const BirthInputPage({super.key, required this.onNext});

  final void Function(DateTime birthDate, Gender gender) onNext;

  @override
  State<BirthInputPage> createState() => _BirthInputPageState();
}

class _BirthInputPageState extends State<BirthInputPage> {
  // いちばん多く使う人(30〜40代)に近いところから回し始める
  DateTime _birthDate = DateTime(1990, 1, 1);
  Gender _gender = Gender.unspecified;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final today = DateTime.now();
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(top: AppSpacing.xxxl),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l.birthTitle, style: AppTextStyles.title),
                      const SizedBox(height: AppSpacing.s),
                      Text(
                        l.birthBody,
                        style: AppTextStyles.callout
                            .copyWith(color: AppColors.textMuted),
                      ),
                      const SizedBox(height: AppSpacing.xl),

                      // 生年月日(iOS の回転式)
                      Text(l.birthDate, style: AppTextStyles.captionLabel),
                      const SizedBox(height: AppSpacing.s),
                      Container(
                        height: 200,
                        decoration: BoxDecoration(
                          color: AppColors.bgWarm,
                          borderRadius: BorderRadius.circular(AppRadius.field),
                        ),
                        child: CupertinoDatePicker(
                          mode: CupertinoDatePickerMode.date,
                          initialDateTime: _birthDate,
                          minimumDate: DateTime(1920),
                          maximumDate: DateTime(today.year, today.month, today.day),
                          onDateTimeChanged: (d) => _birthDate = d,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),

                      // 性別(任意)
                      Text(l.genderOptional, style: AppTextStyles.captionLabel),
                      const SizedBox(height: AppSpacing.s),
                      Row(
                        children: [
                          for (final g in [
                            (Gender.male, l.genderMale),
                            (Gender.female, l.genderFemale),
                            (Gender.unspecified, l.genderUnspecified),
                          ]) ...[
                            if (g.$1 != Gender.male)
                              const SizedBox(width: AppSpacing.s),
                            Expanded(child: _genderButton(g.$1, g.$2)),
                          ],
                        ],
                      ),
                      const SizedBox(height: AppSpacing.s),
                      Text(l.genderNote, style: AppTextStyles.footnote),
                      const SizedBox(height: AppSpacing.xl),
                    ],
                  ),
                ),
              ),
              AppButton.primary(
                onPressed: () => widget.onNext(
                    DateTime(_birthDate.year, _birthDate.month, _birthDate.day),
                    _gender),
                label: l.next,
              ),
              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _genderButton(Gender gender, String label) {
    final isSelected = _gender == gender;
    return Semantics(
      button: true,
      selected: isSelected,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(() => _gender = gender),
        child: Container(
          constraints: const BoxConstraints(minHeight: AppSpacing.minTap),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.accentSurface2 : AppColors.bgWarm,
            border: Border.all(
              color: isSelected ? AppColors.borderAccent : AppColors.border,
            ),
            borderRadius: BorderRadius.circular(AppRadius.full),
          ),
          // 英語の「Rather not say」のような長い語も、折り返さずに1行で真ん中に
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                maxLines: 1,
                textAlign: TextAlign.center,
                style: AppTextStyles.footnote.copyWith(
                  color:
                      isSelected ? AppColors.accent : AppColors.textSecondary,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
