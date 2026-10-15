import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/daily_record.dart';
import '../../models/stamp.dart';
import '../../providers/question_bank_provider.dart';
import '../../utils/date_only.dart';
import '../shared/app_card.dart';
import '../shared/app_colors.dart';
import '../shared/app_spacing.dart';
import '../shared/app_text_styles.dart';

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
    final counts = countMoods(records);
    final moods = [
      for (final s in stamps)
        if (counts[s.id]! > 0) '${s.emoji} ${counts[s.id]}日',
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.xs, 0, AppSpacing.xs, AppSpacing.m),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text('${month.year}年${month.month}月', style: AppTextStyles.headline),
          const Spacer(),
          if (moods.isNotEmpty)
            Semantics(
              label: 'この月の気分',
              child: Text(moods.join('  '), style: AppTextStyles.footnote),
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
            Text(
                '1年前の今日${mood == null ? '' : '　${mood.emoji} ${mood.label}'}',
                style: AppTextStyles.captionLabel),
            if (r.answer != null) ...[
              const SizedBox(height: AppSpacing.s),
              if (q != null)
                Text(q.text,
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
