import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../models/important_person.dart';
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
import 'next_meet_row.dart';
import 'family_avatar.dart';
import 'quick_contact_row.dart';
import 'widget_guide_sheet.dart';
import '../../utils/prefs_keys.dart';
import 'meeting_log_sheet.dart';
import '../../services/contact_stats.dart';
import '../../services/pro_service.dart';
import '../pro/pro_sheet.dart';

/// 初回だけ: 家族の登録画面を開き、登録できたらウィジェットの置き方を案内する
class FirstRunGuide extends ConsumerStatefulWidget {
  const FirstRunGuide({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<FirstRunGuide> createState() => _FirstRunGuideState();
}

class _FirstRunGuideState extends ConsumerState<FirstRunGuide> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _run());
  }

  Future<void> _run() async {
    final prefs = ref.read(sharedPreferencesProvider);
    if (!(prefs.getBool(PrefsKeys.firstRunGuide) ?? false)) return;
    await prefs.setBool(PrefsKeys.firstRunGuide, false);
    final repo = ref.read(importantPersonRepositoryProvider);
    if (await repo.count() > 0 || !mounted) return;
    final result = await ImportantPersonFormPage.show(context);
    if (result == null || !mounted) return;
    await repo.add(result);
    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) await WidgetGuideSheet.show(context);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

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
            Text(
              '家族と過ごせる時間',
              style: GoogleFonts.zenKakuGothicNew(
                fontSize: 20,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (myBirth != null) ...[
              const SizedBox(height: 8),
              Text(
                '今日は、人生 ${NumberFormat('#,###', 'ja_JP').format(LifeCalculator.lifeDays(myBirth))}日目',
                style: GoogleFonts.zenKakuGothicNew(
                  fontSize: 13,
                  color: AppColors.textMuted,
                ),
              ),
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
                error: (e, _) =>
                    Text('読み込めませんでした', style: AppTextStyles.bodySmall),
                data: (list) => list.isEmpty
                    ? _empty(context, ref)
                    : Column(
                        children: [
                          const _HowToTip(),
                          for (final p in list) ...[
                            _FamilyCard(
                              person: p,
                              time: FamilyTime.of(
                                p,
                                myBirthDate: myBirth,
                                myGender: settings.gender,
                              ),
                              metThisYear: ContactStats.metThisYear(logs, p.id),
                              connectedThisMonth:
                                  ContactStats.connectedThisMonth(logs, p.id),
                            ),
                            const SizedBox(height: 14),
                          ],
                          _addButton(context, ref),
                          const SizedBox(height: 20),
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
              ),
          ],
        ),
      ),
    );
  }

  Widget _empty(BuildContext context, WidgetRef ref) {
    return AppCard(
      child: Column(
        children: [
          Text(
            '親や子ども、パートナー。\n家族を登録すると、\nこれから一緒に過ごせる時間がわかります',
            textAlign: TextAlign.center,
            style: GoogleFonts.zenKakuGothicNew(
              fontSize: 14,
              height: 1.9,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          AppButton.primary(
            onPressed: () => addPerson(context, ref),
            label: '家族を追加する',
          ),
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
        child: Text(
          '+ 家族を追加',
          textAlign: TextAlign.center,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _FamilyCard extends StatelessWidget {
  const _FamilyCard({
    required this.person,
    required this.time,
    required this.metThisYear,
    required this.connectedThisMonth,
  });

  final ImportantPerson person;
  final FamilyTime time;
  final int metThisYear;
  final int connectedThisMonth;

  @override
  Widget build(BuildContext context) {
    final age = LifeCalculator.currentAge(person.birthDate);
    return AppCard(
      onTap: () => FamilyDetailPage.open(context, person.id),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              FamilyAvatar(name: person.nickname, photoFile: person.photoFile),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  person.nickname,
                  style: GoogleFonts.zenKakuGothicNew(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              _chip('${person.relation.label}・$age歳'),
            ],
          ),
          const SizedBox(height: 16),
          FamilyTimeView(person: person, time: time),
          const SizedBox(height: 14),
          NextMeetRow(person: person),
          const SizedBox(height: 10),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 12),
          if (time.summersAtHome != null) ...[
            // 一緒に暮らしている子ども: 「会えた」「電話した」は意味がないので、思い出を残す形に
            Row(
              children: [
                Expanded(
                  child: Text(
                    '今年の思い出 $metThisYear件',
                    style: GoogleFonts.zenKakuGothicNew(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: () =>
                      MeetingLogSheet.show(context, person, memoryMode: true),
                  icon: Icon(
                    Icons.photo_outlined,
                    size: 18,
                    color: AppColors.accent,
                  ),
                  label: Text(
                    '思い出を残す',
                    style: GoogleFonts.zenKakuGothicNew(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.accent,
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            Text(
              '今月つながった日 $connectedThisMonth日 ・ 今年会えた日 $metThisYear日',
              style: GoogleFonts.zenKakuGothicNew(
                fontSize: 12,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 6),
            QuickContactRow(person: person),
          ],
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
    child: Text(
      text,
      style: GoogleFonts.zenKakuGothicNew(
        fontSize: 11,
        color: AppColors.accent,
      ),
    ),
  );
}


/// 使い方の案内(家族を登録したあと、閉じるまで出す)
class _HowToTip extends ConsumerStatefulWidget {
  const _HowToTip();

  @override
  ConsumerState<_HowToTip> createState() => _HowToTipState();
}

class _HowToTipState extends ConsumerState<_HowToTip> {
  @override
  Widget build(BuildContext context) {
    final prefs = ref.watch(sharedPreferencesProvider);
    if (prefs.getBool(PrefsKeys.familyTipDismissed) ?? false) {
      return const SizedBox.shrink();
    }
    Widget line(IconData icon, String text) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(icon, size: 18, color: AppColors.accent),
            const SizedBox(width: 10),
            Expanded(
              child: Text(text,
                  style: GoogleFonts.zenKakuGothicNew(fontSize: 13, height: 1.6)),
            ),
          ]),
        );
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
        decoration: BoxDecoration(
          color: AppColors.accentSurface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('使い方',
              style: GoogleFonts.zenKakuGothicNew(
                  fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          line(Icons.touch_app_outlined, '会えた日・話した日に、カードの下のボタンを押して残します'),
          line(Icons.event_outlined, '「次に会う日を入れる」で、帰省の日までを数えます'),
          line(Icons.widgets_outlined, 'ホーム画面にウィジェットを置くと、毎日目に入ります'),
          Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            TextButton(
              onPressed: () => WidgetGuideSheet.show(context),
              child: Text('ウィジェットの置き方',
                  style: GoogleFonts.zenKakuGothicNew(fontSize: 13, color: AppColors.accent)),
            ),
            TextButton(
              onPressed: () async {
                await prefs.setBool(PrefsKeys.familyTipDismissed, true);
                setState(() {});
              },
              child: Text('閉じる',
                  style: GoogleFonts.zenKakuGothicNew(
                      fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
            ),
          ]),
        ]),
      ),
    );
  }
}
