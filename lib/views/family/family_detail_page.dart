import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/important_person.dart';
import '../../providers/important_person_provider.dart';
import '../../providers/isar_provider.dart';
import '../../providers/user_settings_provider.dart';
import '../../services/family_time.dart';
import '../../services/life_calculator.dart';
import '../../services/life_table.dart';
import '../life/important_person_form_page.dart';
import '../shared/action_buttons.dart';
import '../shared/app_card.dart';
import '../shared/app_colors.dart';
import 'family_time_view.dart';
import 'meeting_log_sheet.dart';
import 'next_meet_row.dart';
import 'family_avatar.dart';
import 'share_card_sheet.dart';
import '../../services/contact_stats.dart';
import '../../models/meeting_log.dart';

/// 家族ひとりの詳細（一緒に過ごせる時間と、会えた日の記録）
class FamilyDetailPage extends ConsumerWidget {
  const FamilyDetailPage({super.key, required this.personId});

  final int personId;

  static Future<void> open(BuildContext context, int personId) {
    return Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => FamilyDetailPage(personId: personId)),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(userSettingsProvider);
    final persons = ref.watch(importantPersonsProvider).valueOrNull ?? const [];
    final matches = persons.where((p) => p.id == personId);
    final myBirth = settings.birthDate;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.accent),
      ),
      body: matches.isEmpty || myBirth == null
          ? const SizedBox.shrink()
          : _body(context, ref, matches.first, myBirth, settings.gender),
    );
  }

  Widget _body(
    BuildContext context,
    WidgetRef ref,
    ImportantPerson p,
    DateTime myBirth,
    Gender myGender,
  ) {
    final logs = (ref.watch(meetingLogsProvider).valueOrNull ?? const [])
        .where((l) => l.personId == p.id)
        .toList();
    final time = FamilyTime.of(p, myBirthDate: myBirth, myGender: myGender);
    final age = LifeCalculator.currentAge(p.birthDate);
    final lastMetDays = p.lastMetDate != null
        ? DateTime.now().difference(p.lastMetDate!).inDays
        : null;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 48),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              FamilyAvatar(name: p.nickname, photoFile: p.photoFile, size: 56),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.nickname,
                      style: GoogleFonts.zenKakuGothicNew(
                        fontSize: 24,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${p.relation.label}・$age歳',
                      style: GoogleFonts.zenKakuGothicNew(
                        fontSize: 13,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              _textButton('共有', AppColors.accent, () {
                ShareCardSheet.show(
                  context,
                  person: p,
                  time: time,
                  metThisYear: ContactStats.metThisYear(logs, p.id),
                );
              }),
              _textButton('編集', AppColors.accent, () async {
                final result = await ImportantPersonFormPage.show(
                  context,
                  person: p,
                );
                if (result != null) {
                  await ref
                      .read(importantPersonRepositoryProvider)
                      .update(result);
                }
              }),
              _textButton('削除', const Color(0xFFC17A56), () async {
                final ok = await showDeleteConfirmation(
                  context,
                  title: '${p.nickname}を削除しますか?',
                  message: 'つながった日の記録も一緒に削除されます。この操作は取り消しできません',
                );
                if (!ok) return;
                await ref
                    .read(meetingLogRepositoryProvider)
                    .deleteByPerson(p.id);
                await ref.read(importantPersonRepositoryProvider).delete(p.id);
                if (context.mounted) Navigator.of(context).pop();
              }),
            ],
          ),
          const SizedBox(height: 20),
          AppCard(
            child: FamilyTimeView(person: p, time: time),
          ),
          const SizedBox(height: 12),
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: NextMeetRow(person: p),
          ),
          if (lastMetDays != null) ...[
            const SizedBox(height: 12),
            AppCard(
              child: Text(
                lastMetDays == 0 ? '今日、会えました' : '最後に会ってから $lastMetDays日',
                style: GoogleFonts.zenKakuGothicNew(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
          const SizedBox(height: 28),
          Row(
            children: [
              Expanded(
                child: Text(
                  'つながった日の記録',
                  style: GoogleFonts.zenKakuGothicNew(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              _textButton(
                '+ 残す',
                AppColors.accent,
                () => MeetingLogSheet.show(context, p),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (logs.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                '会えた日や話した日に、ひとこと残せます',
                style: GoogleFonts.zenKakuGothicNew(
                  fontSize: 13,
                  color: AppColors.textMuted,
                ),
              ),
            )
          else
            AppCard(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Column(
                children: [
                  for (final l in logs)
                    GestureDetector(
                      onLongPress: () async {
                        final ok = await showDeleteConfirmation(
                          context,
                          title: 'この記録を削除しますか?',
                        );
                        if (ok) {
                          await ref
                              .read(meetingLogRepositoryProvider)
                              .delete(l.id);
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 84,
                              child: Text(
                                '${l.date.year}/${l.date.month}/${l.date.day}',
                                style: GoogleFonts.zenKakuGothicNew(
                                  fontSize: 12,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (l.photoFile != null) ...[
                                    LogPhoto(
                                      photoFile: l.photoFile,
                                      height: 140,
                                    ),
                                    const SizedBox(height: 8),
                                  ],
                                  Text(
                                    l.note ?? l.kind.label,
                                    style: GoogleFonts.zenKakuGothicNew(
                                      fontSize: 14,
                                      height: 1.6,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          const SizedBox(height: 24),
          Text(
            '${LifeTable.source}の平均余命をもとにした目安です',
            textAlign: TextAlign.center,
            style: GoogleFonts.zenKakuGothicNew(
              fontSize: 11,
              color: AppColors.textDisabled,
            ),
          ),
        ],
      ),
    );
  }

  static Widget _textButton(String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Text(
          label,
          style: GoogleFonts.zenKakuGothicNew(fontSize: 13, color: color),
        ),
      ),
    );
  }
}
