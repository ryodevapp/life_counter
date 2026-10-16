import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/l10n.dart';
import '../../models/daily_record.dart';
import '../../models/question.dart';
import '../../models/stamp.dart';
import '../../providers/question_bank_provider.dart';
import '../../utils/date_only.dart';
import '../shared/app_card.dart';
import '../shared/app_colors.dart';
import '../shared/app_spacing.dart';
import '../shared/app_text_styles.dart';
import '../shared/mood_face.dart';
import '../shared/mood_shape.dart';

/// 月ごとの気分の数を数える(良い・悪いの点数や平均は出さない)
Map<String, int> countMoods(Iterable<DailyRecord> records) {
  final counts = {for (final s in stamps) s.id: 0};
  for (final r in records) {
    if (counts.containsKey(r.stamp)) counts[r.stamp!] = counts[r.stamp!]! + 1;
  }
  return counts;
}

/// 記録の一覧の月の見出し: 「2026年10月」と、その月の気分の内訳(あった気分だけを横に並べる)
class MonthHeader extends StatelessWidget {
  const MonthHeader({super.key, required this.month, required this.records});

  final DateTime month;

  /// その月の記録
  final List<DailyRecord> records;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final counts = countMoods(records);
    final moods = [
      for (final s in stamps)
        if (counts[s.id]! > 0) (s, counts[s.id]!),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.xs, 0, AppSpacing.xs, AppSpacing.m),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(formatYearMonth(month, l.localeName),
              style: AppTextStyles.headline),
          const Spacer(),
          if (moods.isNotEmpty)
            Semantics(
              label: l.monthMoodsSemantics(moods
                  .map((m) => l.monthMoodItem(moodLabelOf(l, m.$1.id), m.$2))
                  .join(l.moodListSeparator)),
              excludeSemantics: true,
              child: Row(
                children: [
                  for (final (s, n) in moods) ...[
                    const SizedBox(width: AppSpacing.m),
                    MoodBadge(moodId: s.id, size: 18),
                    const SizedBox(width: AppSpacing.xs),
                    Text(l.monthMoodCount(n), style: AppTextStyles.footnote),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// 1年前の今日の記録(あるときだけ一覧のいちばん上に出す)
class LastYearCard extends ConsumerWidget {
  const LastYearCard({super.key, required this.records});

  /// すべての記録
  final List<DailyRecord> records;

  /// 1年前の今日の記録。無ければ null
  static DailyRecord? find(List<DailyRecord> records) {
    final ago = oneYearAgo(dateOnly(DateTime.now()));
    for (final r in records) {
      if (dateOnly(r.date) == ago && (r.answer != null || r.stamp != null)) {
        return r;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = find(records);
    if (r == null) return const SizedBox.shrink();
    final bank = ref.read(questionBankProvider);
    final mood = stampById(r.stamp);
    final q =
        r.morningQuestionId == null ? null : bank.byId(r.morningQuestionId!);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.section),
      child: AppCard(
        color: AppColors.bgWarm,
        showShadow: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(context.l10n.oneYearAgoToday,
                    style: AppTextStyles.captionLabel),
                if (mood != null) ...[
                  const SizedBox(width: AppSpacing.m),
                  MoodBadge(moodId: mood.id, size: 18),
                  const SizedBox(width: AppSpacing.xs),
                  Text(moodLabel(context, mood.id),
                      style: AppTextStyles.footnote
                          .copyWith(color: moodLooks[mood.id]?.ink)),
                ],
              ],
            ),
            if (r.answer != null) ...[
              const SizedBox(height: AppSpacing.s),
              if (q != null)
                Text(questionWithFollowUp(q),
                    style: AppTextStyles.footnote
                        .copyWith(color: AppColors.textSecondary)),
              const SizedBox(height: AppSpacing.xs),
              Text(r.answer!, style: AppTextStyles.body),
            ],
          ],
        ),
      ),
    );
  }
}
