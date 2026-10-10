import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../models/important_person.dart';
import '../../models/meeting_log.dart';
import '../../providers/important_person_provider.dart';
import '../../providers/isar_provider.dart';
import '../../providers/user_settings_provider.dart';
import '../../services/family_time.dart';
import '../../services/life_calculator.dart';
import '../../services/life_table.dart';
import '../life/important_person_form_page.dart';
import '../shared/app_button.dart';
import '../shared/app_card.dart';
import '../shared/app_colors.dart';
import '../shared/app_text_styles.dart';
import 'family_detail_page.dart';
import 'family_time_view.dart';
import 'meeting_log_sheet.dart';
import 'next_meet_row.dart';
import 'family_avatar.dart';
import '../../services/pro_service.dart';
import '../pro/pro_sheet.dart';

/// 家族タブ（最初の画面）
class FamilyPage extends ConsumerWidget {
  const FamilyPage({super.key});

  static Future<void> addPerson(BuildContext context, WidgetRef ref) async {
    final count = await ref.read(importantPersonRepositoryProvider).count();
    if (!ref.read(proProvider).canAddFamily(count)) {
      if (context.mounted) await ProSheet.show(context, reachedLimit: true);
      return;
    }
    if (!context.mounted) return;
    final result = await ImportantPersonFormPage.show(context);
    if (result != null) {
      await ref.read(importantPersonRepositoryProvider).add(result);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(userSettingsProvider);
    final persons = ref.watch(importantPersonsProvider);
    final logs = ref.watch(meetingLogsProvider).valueOrNull ?? const [];
    final myBirth = settings.birthDate;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 48, 20, 130),
        child: Column(
          children: [
            Text('FAMILY', style: AppTextStyles.labelUppercase),
            const SizedBox(height: 14),
            Text('家族と過ごせる時間',
                style: GoogleFonts.zenKakuGothicNew(
                    fontSize: 20, fontWeight: FontWeight.w500)),
            if (myBirth != null) ...[
              const SizedBox(height: 8),
              Text(
                  '今日は、人生 ${NumberFormat('#,###', 'ja_JP').format(LifeCalculator.lifeDays(myBirth))}日目',
                  style: GoogleFonts.zenKakuGothicNew(
                      fontSize: 13, color: AppColors.textMuted)),
            ],
            const SizedBox(height: 28),
            if (myBirth == null)
              const SizedBox.shrink()
            else
              persons.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
                error: (e, _) => Text('読み込めませんでした',
                    style: AppTextStyles.bodySmall),
                data: (list) => list.isEmpty
                    ? _empty(context, ref)
                    : Column(children: [
                        for (final p in list) ...[
                          _FamilyCard(
                            person: p,
                            time: FamilyTime.of(p,
                                myBirthDate: myBirth,
                                myGender: settings.gender),
                            metThisYear: _metThisYear(logs, p.id),
                          ),
                          const SizedBox(height: 14),
                        ],
                        _addButton(context, ref),
                        const SizedBox(height: 20),
                        Text('${LifeTable.source}の平均余命をもとにした目安です',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.zenKakuGothicNew(
                                fontSize: 11,
                                color: AppColors.textDisabled)),
                      ]),
              ),
          ],
        ),
      ),
    );
  }

  static int _metThisYear(List<MeetingLog> logs, int personId) {
    final year = DateTime.now().year;
    return logs
        .where((l) => l.personId == personId && l.date.year == year)
        .length;
  }

  Widget _empty(BuildContext context, WidgetRef ref) {
    return AppCard(
      child: Column(
        children: [
          Text(
            '親や子ども、パートナー。\n家族を登録すると、\nこれから一緒に過ごせる時間がわかります',
            textAlign: TextAlign.center,
            style: GoogleFonts.zenKakuGothicNew(
                fontSize: 14, height: 1.9, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),
          AppButton.primary(
              onPressed: () => addPerson(context, ref), label: '家族を追加する'),
        ],
      ),
    );
  }

  Widget _addButton(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => addPerson(context, ref),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderAccent),
        ),
        child: Text('+ 家族を追加',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySmall
                .copyWith(color: AppColors.textSecondary)),
      ),
    );
  }
}

class _FamilyCard extends StatelessWidget {
  const _FamilyCard({
    required this.person,
    required this.time,
    required this.metThisYear,
  });

  final ImportantPerson person;
  final FamilyTime time;
  final int metThisYear;

  @override
  Widget build(BuildContext context) {
    final age = LifeCalculator.currentAge(person.birthDate);
    return AppCard(
      onTap: () => FamilyDetailPage.open(context, person.id),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            FamilyAvatar(name: person.nickname, photoFile: person.photoFile),
            const SizedBox(width: 12),
            Expanded(
              child: Text(person.nickname,
                  style: GoogleFonts.zenKakuGothicNew(
                      fontSize: 16, fontWeight: FontWeight.w600)),
            ),
            _chip('${person.relation.label}・$age歳'),
          ]),
          const SizedBox(height: 16),
          FamilyTimeView(person: person, time: time),
          const SizedBox(height: 14),
          NextMeetRow(person: person),
          const SizedBox(height: 10),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: Text(
                metThisYear > 0 ? '今年会えた日  $metThisYear日' : 'まだ記録がありません',
                style: GoogleFonts.zenKakuGothicNew(
                    fontSize: 12, color: AppColors.textMuted),
              ),
            ),
            GestureDetector(
              onTap: () => MeetingLogSheet.show(context, person),
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                child: Text('会えた日を残す',
                    style: GoogleFonts.zenKakuGothicNew(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.accent)),
              ),
            ),
          ]),
        ],
      ),
    );
  }

  static Widget _chip(String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.accentSurface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(text,
            style: GoogleFonts.zenKakuGothicNew(
                fontSize: 11, color: AppColors.accent)),
      );
}
