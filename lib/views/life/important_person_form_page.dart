import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../l10n/l10n.dart';
import '../../models/important_person.dart';
import '../../utils/date_validator.dart';
import '../../utils/freq_label.dart';
import '../shared/app_colors.dart';
import '../shared/app_spacing.dart';
import '../shared/app_text_styles.dart';
import '../shared/app_picker.dart';
import '../shared/app_toast.dart';
import '../shared/app_button.dart';
import '../shared/app_input.dart';
import '../../l10n/phrase_break.dart';

class ImportantPersonFormPage extends StatefulWidget {
  const ImportantPersonFormPage({super.key, this.person});

  final ImportantPerson? person;

  static Future<ImportantPerson?> show(BuildContext context,
      {ImportantPerson? person}) {
    return showDialog<ImportantPerson>(
      context: context,
      barrierColor: AppColors.text.withValues(alpha: 0.4),
      builder: (_) => ImportantPersonFormPage(person: person),
    );
  }

  @override
  State<ImportantPersonFormPage> createState() =>
      _ImportantPersonFormPageState();
}

class _ImportantPersonFormPageState extends State<ImportantPersonFormPage> {
  final _nickController = TextEditingController();
  int _year = 1965;
  int _month = 4;
  int _day = 1;
  Gender _gender = Gender.unspecified;
  int _freq = 4;
  DateTime? _lastMet;

  @override
  void initState() {
    super.initState();
    if (widget.person != null) {
      final p = widget.person!;
      _nickController.text = p.nickname;
      _year = p.birthDate.year;
      _month = p.birthDate.month;
      _day = p.birthDate.day;
      _gender = p.gender;
      _freq = snapToNearestFreq(p.meetingFrequency);
      _lastMet = p.lastMetDate;
    }
  }

  @override
  void dispose() {
    _nickController.dispose();
    super.dispose();
  }

  void _submit() {
    final nick = _nickController.text.trim();
    if (nick.isEmpty) {
      AppToast.error(context, context.l10n.nicknameNeeded);
      return;
    }
    final error = DateValidator.validateBirthDate(_year, _month, _day,
        l10n: context.l10n);
    if (error != null) {
      AppToast.error(context, error);
      return;
    }
    final birthDate = DateTime(_year, _month, _day);
    final person = widget.person ?? ImportantPerson();
    person
      ..nickname = nick
      ..birthDate = birthDate
      ..gender = _gender
      ..meetingFrequency = _freq
      ..lastMetDate = _lastMet;
    Navigator.of(context).pop(person);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.person != null;
    final l = context.l10n;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.screen),
        child: GestureDetector(
          onTap: () {}, // prevent dismiss on content tap
          child: Container(
            constraints: const BoxConstraints(maxWidth: 360),
            padding: const EdgeInsets.all(AppSpacing.xl),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(AppRadius.sheet),
            ),
            child: Material(
              color: Colors.transparent,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PhraseText(
                    isEdit ? l.editPerson : l.addPerson,
                    style: AppTextStyles.title,
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // ニックネーム
                  _label(l.nickname, required: true),
                  const SizedBox(height: AppSpacing.s),
                  AppInput(
                    controller: _nickController,
                    placeholder: l.nicknameHint,
                    maxLength: 20,
                  ),
                  const SizedBox(height: AppSpacing.l),

                  // 性別
                  _label(l.gender),
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
                        Expanded(child: _genderBtn(g.$1, g.$2)),
                      ],
                    ],
                  ),
                  const SizedBox(height: AppSpacing.l),

                  // 生年月日
                  _label(l.birthDate, required: true),
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
                            child: PhraseText(
                              formatDate(DateTime(_year, _month, _day),
                                  l.localeName),
                              style: AppTextStyles.callout,
                            ),
                          ),
                          Icon(CupertinoIcons.calendar,
                              color: AppColors.textMuted, size: 18),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.l),

                  // 会う頻度
                  _label(l.meetingFrequency, required: true),
                  const SizedBox(height: AppSpacing.s),
                  AppPicker<int>(
                    value: _freq,
                    displayText:
                        capitalizeFirst(localizedFreqLabel(l, _freq)),
                    title: l.meetingFrequency,
                    options: meetingFrequencies
                        .map((f) => AppPickerOption(
                            value: f.annual,
                            label: capitalizeFirst(
                                localizedFreqLabel(l, f.annual))))
                        .toList(),
                    onChanged: (v) => setState(() => _freq = v),
                  ),
                  const SizedBox(height: AppSpacing.l),

                  // 最後に会った日
                  _label(l.lastMetOptional),
                  const SizedBox(height: AppSpacing.s),
                  GestureDetector(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _lastMet ?? DateTime.now(),
                        firstDate: DateTime(1920),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) setState(() => _lastMet = picked);
                    },
                    child: Container(
                      width: double.infinity,
                      constraints: const BoxConstraints(minHeight: 48),
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.l, vertical: AppSpacing.m),
                      decoration: BoxDecoration(
                        color: AppColors.bgWarm,
                        borderRadius: BorderRadius.circular(AppRadius.field),
                      ),
                      child: PhraseText(
                        _lastMet != null
                            ? formatDate(_lastMet!, l.localeName)
                            : l.none,
                        // 未選択のときは入力欄の例の文と同じ色
                        style: AppTextStyles.callout.copyWith(
                          color: _lastMet != null
                              ? AppColors.text
                              : AppColors.textDisabled,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  Row(
                    children: [
                      Expanded(
                        child: AppButton.secondary(
                          onPressed: () => Navigator.of(context).pop(),
                          label: l.cancel,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.s),
                      Expanded(
                        child: AppButton.primary(
                          onPressed: _submit,
                          label: isEdit ? l.save : l.add,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(String text, {bool required = false}) {
    return Text.rich(
      TextSpan(children: [
        TextSpan(text: text, style: AppTextStyles.captionLabel),
        if (required)
          TextSpan(
            text: ' *',
            style:
                AppTextStyles.captionLabel.copyWith(color: AppColors.accent),
          ),
      ]),
    );
  }

  Widget _genderBtn(Gender gender, String label) {
    final sel = _gender == gender;
    return Semantics(
      button: true,
      selected: sel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(() => _gender = gender),
        child: Container(
          constraints: const BoxConstraints(minHeight: AppSpacing.minTap),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
          decoration: BoxDecoration(
            color: sel ? AppColors.accentSurface2 : AppColors.bgWarm,
            border: Border.all(
                color: sel ? AppColors.borderAccent : AppColors.border),
            borderRadius: BorderRadius.circular(AppRadius.full),
          ),
          child: Center(
            child: PhraseText(label,
                style: AppTextStyles.footnote.copyWith(
                  color: sel ? AppColors.accent : AppColors.textSecondary,
                )),
          ),
        ),
      ),
    );
  }

}
