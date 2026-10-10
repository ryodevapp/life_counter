import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/important_person.dart';
import '../../services/life_calculator.dart';
import '../../services/photo_store.dart';
import '../family/family_avatar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/pro_service.dart';
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
  DateTime _birth = DateTime(1960, 1, 1);
  String? _photo;
  bool _birthTouched = false;
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
      _birth = p.birthDate;
      _photo = p.photoFile;
      _birthTouched = true;
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
    final birthDate = _birth;
    final person = widget.person ?? ImportantPerson();
    person
      ..nickname = nick
      ..birthDate = birthDate
      ..gender = _gender
      ..meetingFrequency = _freq
      ..relation = _relation
      ..photoFile = _photo;
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
                  const SizedBox(height: 20),

                  // 写真（任意。ウィジェットにも使う）
                  Center(
                    child: GestureDetector(
                      onTap: () async {
                        final name = await PhotoStore.pick();
                        if (name != null) setState(() => _photo = name);
                      },
                      child: Column(children: [
                        FamilyAvatar(
                            name: _nickController.text, photoFile: _photo, size: 72),
                        const SizedBox(height: 6),
                        Text(_photo == null ? '写真を選ぶ' : '写真を変える',
                            style: GoogleFonts.zenKakuGothicNew(
                                fontSize: 12, color: AppColors.accent)),
                        // ウィジェットに写真が出ない理由が分かるように(未購入のあいだだけ)
                        if (_photo != null)
                          Consumer(builder: (context, ref, _) {
                            if (ref.watch(proProvider).isPro) {
                              return const SizedBox.shrink();
                            }
                            return Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text('ホーム画面のウィジェットに写真を出すのは Pro の機能です',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.zenKakuGothicNew(
                                      fontSize: 11, color: AppColors.textMuted)),
                            );
                          }),
                      ]),
                    ),
                  ),
                  const SizedBox(height: 16),

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

                  // 生年月日（年齢と、誕生日の通知に使う）
                  _label('生年月日', required: true),
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _birth,
                        firstDate: DateTime(1915),
                        lastDate: DateTime.now(),
                        initialEntryMode: DatePickerEntryMode.calendarOnly,
                        initialDatePickerMode: DatePickerMode.year,
                      );
                      if (picked != null) {
                        setState(() {
                          _birth = picked;
                          _birthTouched = true;
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
                      child: Row(children: [
                        Expanded(
                          child: Text(
                            '${_birth.year}年${_birth.month}月${_birth.day}日(${LifeCalculator.currentAge(_birth)}歳)',
                            style: GoogleFonts.zenKakuGothicNew(
                                fontSize: 15, color: AppColors.text),
                          ),
                        ),
                        Icon(Icons.calendar_today_rounded,
                            color: AppColors.textMuted, size: 18),
                      ]),
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
        // 関係に合わせて、選びはじめの生年月日を変える（年の一覧から選びやすく）
        if (!_birthTouched) {
          _birth = switch (r) {
            Relation.parent => DateTime(1960, 1, 1),
            Relation.child => DateTime(2020, 1, 1),
            Relation.partner => DateTime(1988, 1, 1),
            Relation.other => DateTime(1950, 1, 1),
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
