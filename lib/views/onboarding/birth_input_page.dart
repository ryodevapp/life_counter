import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../models/important_person.dart';
import '../../utils/date_validator.dart';
import '../shared/app_colors.dart';
import '../shared/app_spacing.dart';
import '../shared/app_toast.dart';
import '../shared/app_text_styles.dart';
import '../shared/app_button.dart';
import '../shared/pill_label.dart';

/// 生年月日・性別入力画面（プロトタイプの birth 再現）
class BirthInputPage extends StatefulWidget {
  const BirthInputPage({super.key, required this.onNext});

  final void Function(DateTime birthDate, Gender gender) onNext;

  @override
  State<BirthInputPage> createState() => _BirthInputPageState();
}

class _BirthInputPageState extends State<BirthInputPage> {
  int _year = 1995;
  int _month = 1;
  int _day = 1;
  Gender _gender = Gender.unspecified;

  void _handleNext() {
    final error = DateValidator.validateBirthDate(_year, _month, _day);
    if (error != null) {
      AppToast.error(context, error);
      return;
    }
    final date = DateTime(_year, _month, _day);
    widget.onNext(date, _gender);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screen, vertical: AppSpacing.l),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              const PillLabel(text: 'STEP 1'),
              const SizedBox(height: AppSpacing.l),
              Text(
                'あなたについて',
                style: AppTextStyles.title,
              ),
              const SizedBox(height: AppSpacing.s),
              Text(
                '人生の日数と、これからの目安の計算に使います',
                style:
                    AppTextStyles.callout.copyWith(color: AppColors.textMuted),
              ),
              const SizedBox(height: AppSpacing.xxl),

              // 性別（任意）
              Text('性別（任意）', style: AppTextStyles.captionLabel),
              const SizedBox(height: AppSpacing.s),
              Row(
                children: [
                  for (final g in [
                    (Gender.male, '男性'),
                    (Gender.female, '女性'),
                    (Gender.unspecified, '答えない'),
                  ]) ...[
                    if (g.$1 != Gender.male)
                      const SizedBox(width: AppSpacing.s),
                    Expanded(child: _genderButton(g.$1, g.$2)),
                  ],
                ],
              ),
              const SizedBox(height: AppSpacing.xl),

              // 生年月日
              Text('生年月日', style: AppTextStyles.captionLabel),
              const SizedBox(height: AppSpacing.s),
              GestureDetector(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime(_year, _month, _day),
                    firstDate: DateTime(1920),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) {
                    setState(() {
                      _year = picked.year;
                      _month = picked.month;
                      _day = picked.day;
                    });
                  }
                },
                // 見た目は AppInput と同じ(bgWarm・角 field・枠なし・高さ 48 以上)
                child: Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(minHeight: 48),
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.l, vertical: AppSpacing.m),
                  decoration: BoxDecoration(
                    color: AppColors.bgWarm,
                    borderRadius: BorderRadius.circular(AppRadius.field),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '$_year年$_month月$_day日',
                          style: AppTextStyles.callout,
                        ),
                      ),
                      Icon(CupertinoIcons.calendar,
                          color: AppColors.textMuted, size: 18),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xxxl),

              AppButton.primary(onPressed: _handleNext, label: '次へ'),
            ],
          ),
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
          child: Center(
            child: Text(
              label,
              style: AppTextStyles.footnote.copyWith(
                color:
                    isSelected ? AppColors.accent : AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }

}
