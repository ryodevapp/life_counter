import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:in_app_review/in_app_review.dart';
import '../../models/important_person.dart';
import '../../models/meeting_log.dart';
import '../../providers/isar_provider.dart';
import '../../providers/user_settings_provider.dart';
import '../../utils/prefs_keys.dart';
import '../shared/app_button.dart';
import '../shared/app_colors.dart';
import '../shared/app_input.dart';
import '../shared/app_toast.dart';

/// 会えた日を残すシート
class MeetingLogSheet extends ConsumerStatefulWidget {
  const MeetingLogSheet({super.key, required this.person});

  final ImportantPerson person;

  static Future<void> show(BuildContext context, ImportantPerson person) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => MeetingLogSheet(person: person),
    );
  }

  @override
  ConsumerState<MeetingLogSheet> createState() => _MeetingLogSheetState();
}

class _MeetingLogSheetState extends ConsumerState<MeetingLogSheet> {
  final _note = TextEditingController();
  DateTime _date = DateTime.now();
  bool _saving = false;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final day = DateTime(_date.year, _date.month, _date.day);
      final log = MeetingLog()
        ..personId = widget.person.id
        ..date = day
        ..note = _note.text.trim().isEmpty ? null : _note.text.trim();
      await ref.read(meetingLogRepositoryProvider).add(log);

      final p = widget.person;
      if (p.lastMetDate == null || p.lastMetDate!.isBefore(day)) {
        p.lastMetDate = day;
        await ref.read(importantPersonRepositoryProvider).update(p);
      }
      await _maybeRequestReview();
      if (mounted) {
        Navigator.of(context).pop();
        AppToast.success(context, '残しました');
      }
    } catch (e) {
      debugPrint('Meeting log save error: $e');
      if (mounted) {
        setState(() => _saving = false);
        AppToast.error(context, '保存できませんでした。もう一度お試しください');
      }
    }
  }

  /// 2回目の記録を残したときに、一度だけ評価をお願いする
  Future<void> _maybeRequestReview() async {
    final prefs = ref.read(sharedPreferencesProvider);
    if (prefs.getBool(PrefsKeys.reviewRequestedMeeting) ?? false) return;
    final count = await ref.read(meetingLogRepositoryProvider).count();
    if (count < 2) return;
    await prefs.setBool(PrefsKeys.reviewRequestedMeeting, true);
    final review = InAppReview.instance;
    if (await review.isAvailable()) {
      Future.delayed(const Duration(seconds: 1), review.requestReview);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottom),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${widget.person.nickname}と会えた日',
                style: GoogleFonts.zenKakuGothicNew(
                    fontSize: 17, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text('電話やビデオ通話の日も、残して大丈夫です',
                style: GoogleFonts.zenKakuGothicNew(
                    fontSize: 12, color: AppColors.textMuted)),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _date,
                  firstDate: DateTime(2000),
                  lastDate: DateTime.now(),
                );
                if (picked != null) setState(() => _date = picked);
              },
              child: Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.bgWarm,
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(children: [
                  Expanded(
                    child: Text('${_date.year}年${_date.month}月${_date.day}日',
                        style: GoogleFonts.zenKakuGothicNew(fontSize: 15)),
                  ),
                  Icon(Icons.calendar_today_rounded,
                      color: AppColors.textMuted, size: 18),
                ]),
              ),
            ),
            const SizedBox(height: 12),
            AppInput(
              controller: _note,
              placeholder: 'ひとこと(例:母と温泉。よく笑ってた)',
              maxLength: 100,
              showBorder: true,
            ),
            const SizedBox(height: 16),
            AppButton.primary(
                onPressed: _saving ? null : _save, label: '残す'),
          ],
        ),
      ),
    );
  }
}
