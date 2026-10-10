import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/daily_record.dart';
import '../../models/important_person.dart';
import '../../models/meeting_log.dart';
import '../../providers/important_person_provider.dart';
import '../../providers/isar_provider.dart';
import '../../providers/user_settings_provider.dart';
import '../../utils/prefs_keys.dart';
import '../family/meeting_log_sheet.dart';
import 'year_review_page.dart';
import '../family/family_avatar.dart';
import '../shared/action_buttons.dart';
import '../shared/app_card.dart';
import '../shared/app_colors.dart';
import '../shared/app_text_styles.dart';
import '../shared/app_toast.dart';

/// v1.0 の日記（中身があるものだけ）。書く画面は v1.1 でなくしたが、記録は残す
final legacyDiaryProvider = FutureProvider<List<DailyRecord>>((ref) async {
  final all = await ref.watch(dailyRecordRepositoryProvider).getAll();
  return all.where((r) => _diaryLines(r).isNotEmpty).toList();
});

List<(String, String)> _diaryLines(DailyRecord r) => [
      if (r.gratitude != null) ('感謝していること', r.gratitude!),
      if (r.todayGoal != null) ('今日やること', r.todayGoal!),
      if (r.reflectionGood != null) ('嬉しかったこと', r.reflectionGood!),
      if (r.reflectionWhy != null) ('なぜ嬉しかった', r.reflectionWhy!),
      if (r.reflectionTomorrow != null) ('明日やること', r.reflectionTomorrow!),
      if (r.tomorrowMessage != null) ('明日の自分へ', r.tomorrowMessage!),
      if (r.weeklyReflectionHighlight != null)
        ('今週のハイライト', r.weeklyReflectionHighlight!),
      if (r.weeklyReflectionChange != null)
        ('来週変えること', r.weeklyReflectionChange!),
    ];

/// 記録タブ（会えた日と、以前の日記を新しい順に1本で並べる）
class RecordsPage extends ConsumerStatefulWidget {
  const RecordsPage({super.key});

  @override
  ConsumerState<RecordsPage> createState() => _RecordsPageState();
}

class _RecordsPageState extends ConsumerState<RecordsPage> {
  Future<void> _addLog(List<ImportantPerson> persons) async {
    if (persons.isEmpty) {
      AppToast.error(context, '先に、家族タブで家族を登録してください');
      return;
    }
    if (persons.length == 1) {
      await MeetingLogSheet.show(context, persons.first);
      return;
    }
    final picked = await showModalBottomSheet<ImportantPerson>(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(height: 16),
          Text('だれと会えましたか',
              style: GoogleFonts.zenKakuGothicNew(
                  fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          for (final p in persons)
            ListTile(
              title: Text(p.nickname),
              trailing: Text(p.relation.label,
                  style: TextStyle(color: AppColors.textMuted)),
              onTap: () => Navigator.of(ctx).pop(p),
            ),
          const SizedBox(height: 8),
        ]),
      ),
    );
    if (picked != null && mounted) await MeetingLogSheet.show(context, picked);
  }

  @override
  Widget build(BuildContext context) {
    final persons = ref.watch(importantPersonsProvider).valueOrNull ?? const [];
    final logs = ref.watch(meetingLogsProvider).valueOrNull ?? const [];
    final diary = ref.watch(legacyDiaryProvider).valueOrNull ?? const [];
    final prefs = ref.watch(sharedPreferencesProvider);
    final showBanner = diary.isNotEmpty &&
        !(prefs.getBool(PrefsKeys.legacyDiaryBannerDismissed) ?? false);

    final names = {for (final p in persons) p.id: p.nickname};
    final items = <(DateTime, Widget)>[
      for (final l in logs) (l.date, _logItem(l, names[l.personId])),
      for (final d in diary) (d.date, _diaryItem(d)),
    ]..sort((a, b) => b.$1.compareTo(a.$1));

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 48, 20, 130),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(child: Text('RECORDS', style: AppTextStyles.labelUppercase)),
            const SizedBox(height: 14),
            Center(
              child: Text('家族とつながった日',
                  style: GoogleFonts.zenKakuGothicNew(
                      fontSize: 20, fontWeight: FontWeight.w500)),
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: () => _addLog(persons),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderAccent),
                ),
                child: Text('+ つながった日を残す',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.zenKakuGothicNew(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.accent)),
              ),
            ),
            const SizedBox(height: 10),
            Center(
              child: TextButton(
                onPressed: () => YearReviewPage.open(context),
                child: Text('${DateTime.now().year}年のふりかえりを見る',
                    style: GoogleFonts.zenKakuGothicNew(
                        fontSize: 13, color: AppColors.accent, fontWeight: FontWeight.w600)),
              ),
            ),
            if (showBanner) ...[
              const SizedBox(height: 16),
              _banner(prefs),
            ],
            const SizedBox(height: 16),
            if (items.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Text('家族と会えた日や話した日を、\nここに残せます',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.zenKakuGothicNew(
                        fontSize: 13, height: 1.8, color: AppColors.textMuted)),
              )
            else
              for (final it in items) ...[it.$2, const SizedBox(height: 10)],
          ],
        ),
      ),
    );
  }

  Widget _banner(SharedPreferences prefs) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      decoration: BoxDecoration(
        color: AppColors.accentSurface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(children: [
        Expanded(
          child: Text('以前の日記は、この一覧に残っています',
              style: GoogleFonts.zenKakuGothicNew(
                  fontSize: 13, color: AppColors.textSecondary)),
        ),
        IconButton(
          tooltip: '閉じる',
          icon: Icon(Icons.close, size: 18, color: AppColors.textMuted),
          onPressed: () async {
            await prefs.setBool(PrefsKeys.legacyDiaryBannerDismissed, true);
            setState(() {});
          },
        ),
      ]),
    );
  }

  static String _date(DateTime d) {
    final now = DateTime.now();
    return d.year == now.year ? '${d.month}/${d.day}' : '${d.year}/${d.month}/${d.day}';
  }

  Widget _logItem(MeetingLog l, String? name) {
    return GestureDetector(
      onLongPress: () async {
        final ok = await showDeleteConfirmation(context, title: 'この記録を削除しますか?');
        if (ok) await ref.read(meetingLogRepositoryProvider).delete(l.id);
      },
      child: AppCard(
        padding: const EdgeInsets.all(18),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(
            width: 72,
            child: Text(_date(l.date),
                style: GoogleFonts.zenKakuGothicNew(
                    fontSize: 12, color: AppColors.textMuted)),
          ),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${name ?? '家族'} ・ ${l.kind.label}',
                  style: GoogleFonts.zenKakuGothicNew(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.accent)),
              const SizedBox(height: 4),
              if (l.photoFile != null) ...[
                LogPhoto(photoFile: l.photoFile, height: 160),
                const SizedBox(height: 8),
              ],
              if (l.note != null)
                Text(l.note!,
                  style: GoogleFonts.zenKakuGothicNew(fontSize: 14, height: 1.6)),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _diaryItem(DailyRecord d) {
    return AppCard(
      padding: const EdgeInsets.all(18),
      color: AppColors.bgWarm,
      showShadow: false,
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(
          width: 72,
          child: Text(_date(d.date),
              style: GoogleFonts.zenKakuGothicNew(
                  fontSize: 12, color: AppColors.textMuted)),
        ),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('日記',
                style: GoogleFonts.zenKakuGothicNew(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMuted)),
            for (final (label, text) in _diaryLines(d)) ...[
              const SizedBox(height: 6),
              Text(label,
                  style: GoogleFonts.zenKakuGothicNew(
                      fontSize: 11, color: AppColors.textMuted)),
              Text(text,
                  style: GoogleFonts.zenKakuGothicNew(fontSize: 14, height: 1.6)),
            ],
          ]),
        ),
      ]),
    );
  }
}
