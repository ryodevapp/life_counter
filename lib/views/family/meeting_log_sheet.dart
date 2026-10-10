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
import '../../services/photo_store.dart';
import 'family_avatar.dart';
import 'quick_contact_row.dart';
import '../../services/pro_service.dart';
import '../pro/pro_sheet.dart';

/// 会えた日を残すシート
class MeetingLogSheet extends ConsumerStatefulWidget {
  const MeetingLogSheet({
    super.key,
    required this.person,
    this.date,
    this.kind,
    this.memoryMode = false,
  });

  final ImportantPerson person;
  final DateTime? date;
  final ContactKind? kind;

  /// 一緒に暮らす子どもの「思い出」(つながり方は選ばせない)
  final bool memoryMode;

  static Future<void> show(
    BuildContext context,
    ImportantPerson person, {
    DateTime? date,
    ContactKind? kind,
    bool memoryMode = false,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => MeetingLogSheet(
        person: person,
        date: date,
        kind: kind,
        memoryMode: memoryMode,
      ),
    );
  }

  @override
  ConsumerState<MeetingLogSheet> createState() => _MeetingLogSheetState();
}

class _MeetingLogSheetState extends ConsumerState<MeetingLogSheet> {
  final _note = TextEditingController();
  late DateTime _date =
      (widget.date != null && widget.date!.isBefore(DateTime.now()))
      ? widget.date!
      : DateTime.now();
  bool _saving = false;
  String? _photo;
  late ContactKind _kind = widget.kind ?? ContactKind.met;

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
        ..note = _note.text.trim().isEmpty ? null : _note.text.trim()
        ..photoFile = _photo
        ..kind = _kind;
      await ref.read(meetingLogRepositoryProvider).add(log);

      final p = widget.person;
      if (_kind == ContactKind.met &&
          (p.lastMetDate == null || p.lastMetDate!.isBefore(day))) {
        p.lastMetDate = day;
        await ref.read(importantPersonRepositoryProvider).update(p);
      }
      await _maybeRequestReview();
      if (mounted) {
        // 写真つきの思い出を初めて残した直後に、一度だけ Pro を案内する(満足した瞬間なので)
        final prefs = ref.read(sharedPreferencesProvider);
        final showPro = _photo != null &&
            !ref.read(proProvider).isPro &&
            !(prefs.getBool(PrefsKeys.proAfterMemoryShown) ?? false);
        final nav = Navigator.of(context);
        final parent = nav.context;
        nav.pop();
        if (parent.mounted) AppToast.success(parent, '残しました');
        if (showPro) {
          await prefs.setBool(PrefsKeys.proAfterMemoryShown, true);
          await Future.delayed(const Duration(milliseconds: 900));
          if (parent.mounted) await ProSheet.show(parent, afterMemory: true);
        }
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
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.memoryMode
                    ? '${widget.person.nickname}との思い出'
                    : '${widget.person.nickname}とつながった日',
                style: GoogleFonts.zenKakuGothicNew(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              // つながり方(1行に4つ。キーボードが出てもシートが収まるように)
              if (!widget.memoryMode)
                Row(
                  children: [
                    for (final k in ContactKind.values) ...[
                      if (k != ContactKind.met) const SizedBox(width: 6),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _kind = k),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: _kind == k
                                  ? AppColors.accentSurface2
                                  : AppColors.bgWarm,
                              border: Border.all(
                                color: _kind == k
                                    ? AppColors.borderAccent
                                    : AppColors.border,
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  contactIcon(k),
                                  size: 18,
                                  color: _kind == k
                                      ? AppColors.accent
                                      : AppColors.textMuted,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  k.label,
                                  maxLines: 1,
                                  style: GoogleFonts.zenKakuGothicNew(
                                    fontSize: 11,
                                    fontWeight: _kind == k
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                    color: _kind == k
                                        ? AppColors.accent
                                        : AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              const SizedBox(height: 16),
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.bgWarm,
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${_date.year}年${_date.month}月${_date.day}日',
                          style: GoogleFonts.zenKakuGothicNew(fontSize: 15),
                        ),
                      ),
                      Icon(
                        Icons.calendar_today_rounded,
                        color: AppColors.textMuted,
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              AppInput(
                controller: _note,
                placeholder: 'ひとこと(例:母と温泉。よく笑ってた)',
                maxLength: 100,
                showBorder: true,
              ),
              const SizedBox(height: 4),
              if (_photo != null) ...[
                LogPhoto(photoFile: _photo, height: 140),
                const SizedBox(height: 8),
              ],
              GestureDetector(
                onTap: () async {
                  final name = await PhotoStore.pick();
                  if (name != null) setState(() => _photo = name);
                },
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Icon(
                        Icons.photo_outlined,
                        size: 18,
                        color: AppColors.accent,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _photo == null ? '写真を添える' : '写真を変える',
                        style: GoogleFonts.zenKakuGothicNew(
                          fontSize: 13,
                          color: AppColors.accent,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              AppButton.primary(onPressed: _saving ? null : _save, label: '残す'),
            ],
          ),
        ),
      ),
    );
  }
}
