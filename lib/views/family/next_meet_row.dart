import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/important_person.dart';
import '../../providers/isar_provider.dart';
import '../shared/app_colors.dart';
import 'meeting_log_sheet.dart';

/// 次に会う日の表示と設定
/// 予定がある: 「会えるまで、あと12日」/ 当日: 「今日、会えます」
/// 予定が過ぎた: 「会えましたか?」→ 会えた日の記録へ
/// 予定がない: 「次に会う日を入れる」
class NextMeetRow extends ConsumerWidget {
  const NextMeetRow({super.key, required this.person});

  final ImportantPerson person;

  static int? daysUntil(ImportantPerson p, {DateTime? now}) {
    final d = p.nextMeetDate;
    if (d == null) return null;
    final t = now ?? DateTime.now();
    final today = DateTime(t.year, t.month, t.day);
    return DateTime(d.year, d.month, d.day).difference(today).inDays;
  }

  Future<void> _pick(BuildContext context, WidgetRef ref) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate:
          person.nextMeetDate != null &&
              !person.nextMeetDate!.isBefore(
                DateTime(now.year, now.month, now.day),
              )
          ? person.nextMeetDate!
          : now,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 3),
      helpText: '${person.nickname}と次に会う日',
    );
    if (picked == null) return;
    person.nextMeetDate = picked;
    await ref.read(importantPersonRepositoryProvider).update(person);
  }

  Future<void> _clear(WidgetRef ref) async {
    person.nextMeetDate = null;
    await ref.read(importantPersonRepositoryProvider).update(person);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final days = daysUntil(person);

    if (days == null) {
      return _link(
        '次に会う日を入れる',
        () => _pick(context, ref),
        color: AppColors.textMuted,
      );
    }
    if (days < 0) {
      return Row(
        children: [
          Expanded(
            child: _text(
              '${person.nickname}と、会えましたか?',
              AppColors.textSecondary,
            ),
          ),
          _link('記録する', () async {
            await MeetingLogSheet.show(
              context,
              person,
              date: person.nextMeetDate,
            );
            await _clear(ref);
          }),
          _link('予定を消す', () => _clear(ref), color: AppColors.textMuted),
        ],
      );
    }
    return GestureDetector(
      onTap: () => _pick(context, ref),
      behavior: HitTestBehavior.opaque,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          if (days == 0)
            _text('今日、会えます', AppColors.accent, bold: true)
          else ...[
            _text('会えるまで、あと ', AppColors.textSecondary),
            Text(
              '$days',
              style: GoogleFonts.cormorantGaramond(fontFeatures: const [FontFeature.liningFigures()], 
                fontSize: 26,
                color: AppColors.accent,
                fontWeight: FontWeight.w500,
              ),
            ),
            _text(' 日', AppColors.textSecondary),
          ],
          const Spacer(),
          Icon(
            Icons.edit_calendar_outlined,
            size: 16,
            color: AppColors.textMuted,
          ),
        ],
      ),
    );
  }

  static Widget _text(String t, Color c, {bool bold = false}) => Text(
    t,
    style: GoogleFonts.zenKakuGothicNew(
      fontSize: 13,
      color: c,
      fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
    ),
  );

  static Widget _link(String t, VoidCallback onTap, {Color? color}) =>
      GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
          child: Text(
            t,
            style: GoogleFonts.zenKakuGothicNew(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color ?? AppColors.accent,
            ),
          ),
        ),
      );
}
