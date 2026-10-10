import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/important_person.dart';
import '../../services/life_calculator.dart';
import '../../utils/freq_label.dart';
import '../shared/app_colors.dart';
import '../shared/app_picker.dart';
import '../shared/app_toast.dart';
import '../shared/app_button.dart';
import '../shared/app_input.dart';

class ImportantPersonFormPage extends StatefulWidget {
  const ImportantPersonFormPage({super.key, this.person});

  final ImportantPerson? person;

  static Future<ImportantPerson?> show(BuildContext context,
      {ImportantPerson? person}) {
    return showDialog<ImportantPerson>(
      context: context,
      barrierColor: const Color(0x662C2520),
      builder: (_) => ImportantPersonFormPage(person: person),
    );
  }

  @override
  State<ImportantPersonFormPage> createState() =>
      _ImportantPersonFormPageState();
}

class _ImportantPersonFormPageState extends State<ImportantPersonFormPage> {
  final _nickController = TextEditingController();
  int _age = 65;
  int? _bMonth;
  int? _bDay;
  bool _ageTouched = false;
  Gender _gender = Gender.unspecified;
  int _freq = 2;
  Relation _relation = Relation.parent;
  int _untilAge = 18;
  int _afterFreq = 4;

  @override
  void initState() {
    super.initState();
    if (widget.person != null) {
      final p = widget.person!;
      _nickController.text = p.nickname;
      _age = LifeCalculator.currentAge(p.birthDate);
      _ageTouched = true;
      _bMonth = p.birthdayMonth;
      _bDay = p.birthdayDay;
      _gender = p.gender;
      _freq = snapToNearestFreq(p.meetingFrequency);
      _relation = p.relation;
      _untilAge = p.untilAge;
      _afterFreq = snapToNearestFreq(p.afterFrequency);
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
      AppToast.error(context, '呼び名を入力してください');
      return;
    }
    // 生年月日を覚えていない人も多いので、年齢から誕生日を置く
    // 編集で年齢を変えていなければ、今の生年月日をそのまま残す
    final now = DateTime.now();
    final keep = widget.person != null &&
        LifeCalculator.currentAge(widget.person!.birthDate) == _age;
    final birthDate = keep
        ? widget.person!.birthDate
        : DateTime(now.year - _age, now.month, now.day);
    final person = widget.person ?? ImportantPerson();
    person
      ..nickname = nick
      ..birthDate = birthDate
      ..gender = _gender
      ..meetingFrequency = _freq
      ..relation = _relation
      ..birthdayMonth = _bMonth
      ..birthdayDay = _bDay;
    if (_relation == Relation.child) {
      person
        ..liveTogetherUntilAge = _untilAge
        ..afterLeavingFrequency = _afterFreq;
    }
    Navigator.of(context).pop(person);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.person != null;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: GestureDetector(
          onTap: () {}, // prevent dismiss on content tap
          child: Container(
            constraints: const BoxConstraints(maxWidth: 360),
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Material(
              color: Colors.transparent,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isEdit ? '家族を編集' : '家族を追加',
                    style: GoogleFonts.zenKakuGothicNew(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 関係
                  _label('関係', required: true),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      for (final r in [
                        Relation.parent,
                        Relation.child,
                        Relation.partner,
                        Relation.other,
                      ]) ...[
                        if (r != Relation.parent) const SizedBox(width: 6),
                        Expanded(child: _relationBtn(r)),
                      ],
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 呼び名
                  _label('呼び名', required: true),
                  const SizedBox(height: 6),
                  AppInput(
                    controller: _nickController,
                    placeholder: switch (_relation) {
                      Relation.parent => '例: お母さん',
                      Relation.child => '例: ゆい',
                      Relation.partner => '例: 妻',
                      Relation.other => '例: おばあちゃん',
                    },
                    maxLength: 20,
                  ),
                  const SizedBox(height: 16),

                  // 性別（子どもは計算に使わないので聞かない）
                  if (_relation != Relation.child) ...[
                    _label('性別'),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        for (final g in [
                          (Gender.male, '男性'),
                          (Gender.female, '女性'),
                          (Gender.unspecified, '選択しない'),
                        ]) ...[
                          if (g.$1 != Gender.male) const SizedBox(width: 8),
                          Expanded(child: _genderBtn(g.$1, g.$2)),
                        ],
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],

                  // 年齢
                  _label('年齢', required: true),
                  const SizedBox(height: 6),
                  AppPicker<int>(
                    value: _age,
                    displayText: '$_age歳',
                    title: '年齢',
                    options: [
                      for (var a = 0; a <= 105; a++)
                        AppPickerOption(value: a, label: '$a歳'),
                    ],
                    onChanged: (v) => setState(() {
                      _age = v;
                      _ageTouched = true;
                    }),
                  ),
                  const SizedBox(height: 16),

                  // 誕生日（任意。節目の通知に使う）
                  _label('誕生日(任意)'),
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: () async {
                      final now = DateTime.now();
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _bMonth != null
                            ? DateTime(now.year, _bMonth!, _bDay!)
                            : now,
                        firstDate: DateTime(now.year, 1, 1),
                        lastDate: DateTime(now.year, 12, 31),
                        helpText: '誕生日(月と日)',
                      );
                      if (picked != null) {
                        setState(() {
                          _bMonth = picked.month;
                          _bDay = picked.day;
                        });
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: AppColors.bgWarm,
                        border: Border.all(color: AppColors.border),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _bMonth != null ? '$_bMonth月$_bDay日' : '入れると、当日にお知らせします',
                        style: GoogleFonts.zenKakuGothicNew(
                          fontSize: 14,
                          color: _bMonth != null
                              ? AppColors.text
                              : AppColors.textDisabled,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (_relation == Relation.child) ...[
                    _label('何歳まで一緒に暮らす'),
                    const SizedBox(height: 6),
                    AppPicker<int>(
                      value: _untilAge,
                      displayText: '$_untilAge歳まで',
                      title: '何歳まで一緒に暮らす',
                      options: [
                        for (var a = 15; a <= 30; a++)
                          AppPickerOption(value: a, label: '$a歳まで'),
                      ],
                      onChanged: (v) => setState(() => _untilAge = v),
                    ),
                    const SizedBox(height: 16),
                    _label('家を出たあと、会う頻度'),
                    const SizedBox(height: 6),
                    AppPicker<int>(
                      value: _afterFreq,
                      displayText: freqToLabel(_afterFreq),
                      title: '家を出たあと、会う頻度',
                      options: meetingFrequencies
                          .map((f) =>
                              AppPickerOption(value: f.annual, label: f.label))
                          .toList(),
                      onChanged: (v) => setState(() => _afterFreq = v),
                    ),
                    const SizedBox(height: 16),
                  ] else ...[
                    // 会う頻度
                    _label('会う頻度', required: true),
                    const SizedBox(height: 6),
                    AppPicker<int>(
                      value: _freq,
                      displayText: freqToLabel(_freq),
                      title: '会う頻度',
                      options: meetingFrequencies
                          .map((f) =>
                              AppPickerOption(value: f.annual, label: f.label))
                          .toList(),
                      onChanged: (v) => setState(() => _freq = v),
                    ),
                    const SizedBox(height: 16),
                  ],

                  Row(
                    children: [
                      Expanded(
                        child: AppButton.secondary(
                          onPressed: () => Navigator.of(context).pop(),
                          label: 'キャンセル',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: AppButton.primary(
                          onPressed: _submit,
                          label: isEdit ? '保存' : '追加',
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
        TextSpan(
          text: text,
          style: GoogleFonts.zenKakuGothicNew(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: AppColors.textMuted,
          ),
        ),
        if (required)
          TextSpan(
            text: ' *',
            style: GoogleFonts.zenKakuGothicNew(
              fontSize: 11,
              color: AppColors.accent,
            ),
          ),
      ]),
    );
  }

  Widget _relationBtn(Relation r) {
    final sel = _relation == r;
    return GestureDetector(
      onTap: () => setState(() {
        _relation = r;
        if (widget.person == null && r == Relation.partner) _freq = 365;
        if (!_ageTouched) {
          _age = switch (r) {
            Relation.parent => 65,
            Relation.child => 6,
            Relation.partner => 40,
            Relation.other => 70,
          };
        }
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 2),
        decoration: BoxDecoration(
          color: sel ? AppColors.accentSurface2 : AppColors.bgWarm,
          border: Border.all(
              color: sel ? AppColors.borderAccent : AppColors.border),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Text(r.label,
              maxLines: 1,
              style: GoogleFonts.zenKakuGothicNew(
                fontSize: 11,
                fontWeight: sel ? FontWeight.w600 : FontWeight.w400,
                color: sel ? AppColors.accent : AppColors.textSecondary,
              )),
        ),
      ),
    );
  }

  Widget _genderBtn(Gender gender, String label) {
    final sel = _gender == gender;
    return GestureDetector(
      onTap: () => setState(() => _gender = gender),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        decoration: BoxDecoration(
          color: sel ? AppColors.accentSurface2 : AppColors.bgWarm,
          border: Border.all(
              color: sel ? AppColors.borderAccent : AppColors.border),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Text(label,
              style: GoogleFonts.zenKakuGothicNew(
                fontSize: 12,
                fontWeight: sel ? FontWeight.w600 : FontWeight.w400,
                color: sel ? AppColors.accent : AppColors.textSecondary,
              )),
        ),
      ),
    );
  }

}
