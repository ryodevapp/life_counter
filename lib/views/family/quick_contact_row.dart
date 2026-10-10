import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/important_person.dart';
import '../../models/meeting_log.dart';
import '../../providers/isar_provider.dart';
import '../shared/app_colors.dart';
import 'meeting_log_sheet.dart';

IconData contactIcon(ContactKind k) => switch (k) {
  ContactKind.met => Icons.people_alt_outlined,
  ContactKind.call => Icons.call_outlined,
  ContactKind.video => Icons.videocam_outlined,
  ContactKind.message => Icons.chat_bubble_outline,
};

/// 家族のカードの下に並べる「つながった」ボタン。
/// 電話・ビデオ・メッセージはワンタップで今日の記録にする(取り消しできる)。
/// 会えた日は、写真とひとことを残せるシートを開く
class QuickContactRow extends ConsumerWidget {
  const QuickContactRow({super.key, required this.person});

  final ImportantPerson person;

  Future<void> _quick(
    BuildContext context,
    WidgetRef ref,
    ContactKind kind,
  ) async {
    final repo = ref.read(meetingLogRepositoryProvider);
    final now = DateTime.now();
    final log = MeetingLog()
      ..personId = person.id
      ..date = DateTime(now.year, now.month, now.day)
      ..kind = kind;
    await repo.add(log);
    if (!context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          '${person.nickname}と「${kind.label}」を残しました',
          style: GoogleFonts.zenKakuGothicNew(
            fontSize: 14,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColors.accent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 100),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: '取り消す',
          textColor: Colors.white,
          onPressed: () => repo.delete(log.id),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        for (final k in ContactKind.values)
          Expanded(
            child: Semantics(
              button: true,
              label: '${person.nickname}と${k.label}を残す',
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => k == ContactKind.met
                    ? MeetingLogSheet.show(context, person)
                    : _quick(context, ref, k),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(contactIcon(k), size: 22, color: AppColors.accent),
                      const SizedBox(height: 4),
                      Text(
                        k.label,
                        style: GoogleFonts.zenKakuGothicNew(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
