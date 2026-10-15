import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/daily_record.dart';
import '../../models/stamp.dart';
import '../../providers/question_bank_provider.dart';
import '../../services/question_bank.dart';
import '../../utils/date_only.dart';
import '../shared/app_card.dart';
import '../shared/app_colors.dart';

/// 月ごとの気分の数を数える(良い・悪いの点数や平均は出さない)
Map<String, int> countMoods(Iterable<DailyRecord> records) {
  final counts = {for (final s in stamps) s.id: 0};
  for (final r in records) {
    if (counts.containsKey(r.stamp)) counts[r.stamp!] = counts[r.stamp!]! + 1;
  }
  return counts;
}

/// ふりかえり: 1年前の今日(あるときだけ)・月の気分・月の問いと答え
class ReflectionView extends ConsumerStatefulWidget {
  const ReflectionView({super.key, required this.records});

  /// すべての記録
  final List<DailyRecord> records;

  @override
  ConsumerState<ReflectionView> createState() => _ReflectionViewState();
}

class _ReflectionViewState extends ConsumerState<ReflectionView> {
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);

  TextStyle get _label =>
      GoogleFonts.zenKakuGothicNew(fontSize: 12, color: AppColors.textMuted);

  @override
  Widget build(BuildContext context) {
    final bank = ref.read(questionBankProvider);
    final inMonth = widget.records
        .where((r) => r.date.year == _month.year && r.date.month == _month.month)
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    final counts = countMoods(inMonth);
    final maxCount = counts.values.fold<int>(0, (a, b) => a > b ? a : b);
    final answered = inMonth.where((r) => r.answer != null).toList();

    final ago = oneYearAgo(dateOnly(DateTime.now()));
    DailyRecord? lastYear;
    for (final r in widget.records) {
      if (dateOnly(r.date) == ago && (r.answer != null || r.stamp != null)) {
        lastYear = r;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (lastYear != null) ...[
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('1年前の今日', style: _label),
                const SizedBox(height: 10),
                ..._entry(lastYear, bank),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              tooltip: '前の月',
              onPressed: () =>
                  setState(() => _month = DateTime(_month.year, _month.month - 1)),
              icon: const Icon(Icons.chevron_left, color: AppColors.textMuted),
            ),
            Text('${_month.year}年${_month.month}月',
                style: GoogleFonts.zenKakuGothicNew(
                    fontSize: 15, fontWeight: FontWeight.w500)),
            IconButton(
              tooltip: '次の月',
              onPressed: () =>
                  setState(() => _month = DateTime(_month.year, _month.month + 1)),
              icon: const Icon(Icons.chevron_right, color: AppColors.textMuted),
            ),
          ],
        ),
        const SizedBox(height: 8),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('この月の気分', style: _label),
              const SizedBox(height: 12),
              if (maxCount == 0)
                Text('この月は、まだ気分の記録がありません',
                    style: GoogleFonts.zenKakuGothicNew(
                        fontSize: 13, color: AppColors.textDisabled))
              else
                for (final s in stamps)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Text(s.emoji, style: const TextStyle(fontSize: 18)),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 64,
                          child: Text(s.label,
                              style: GoogleFonts.zenKakuGothicNew(
                                  fontSize: 12, color: AppColors.textSecondary)),
                        ),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: counts[s.id]! / maxCount,
                              minHeight: 8,
                              backgroundColor: AppColors.bgWarm,
                              color: AppColors.accentLight,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 32,
                          child: Text('${counts[s.id]}日',
                              textAlign: TextAlign.right,
                              style: GoogleFonts.zenKakuGothicNew(
                                  fontSize: 12, color: AppColors.textMuted)),
                        ),
                      ],
                    ),
                  ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text('この月の問いと答え', style: _label),
        const SizedBox(height: 8),
        if (answered.isEmpty)
          AppCard(
            child: Text('この月は、まだ答えた問いがありません',
                style: GoogleFonts.zenKakuGothicNew(
                    fontSize: 13, color: AppColors.textDisabled)),
          )
        else
          for (final r in answered)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _entry(r, bank),
                ),
              ),
            ),
      ],
    );
  }

  /// 日付と気分 → 問い → 答え
  List<Widget> _entry(DailyRecord r, QuestionBank bank) {
    final mood = stampById(r.stamp);
    final q = r.morningQuestionId == null ? null : bank.byId(r.morningQuestionId!);
    return [
      Row(
        children: [
          Text('${r.date.month}月${r.date.day}日',
              style: GoogleFonts.zenKakuGothicNew(
                  fontSize: 13, fontWeight: FontWeight.w500)),
          if (mood != null) ...[
            const SizedBox(width: 10),
            Text('${mood.emoji} ${mood.label}',
                style: GoogleFonts.zenKakuGothicNew(
                    fontSize: 12, color: AppColors.textSecondary)),
          ],
        ],
      ),
      if (r.answer != null) ...[
        const SizedBox(height: 8),
        if (q != null)
          Text(q.text,
              style: GoogleFonts.zenKakuGothicNew(
                  fontSize: 12, color: AppColors.textMuted, height: 1.5)),
        const SizedBox(height: 4),
        Text(r.answer!,
            style: GoogleFonts.zenKakuGothicNew(
                fontSize: 14,
                fontWeight: FontWeight.w300,
                color: AppColors.text,
                height: 1.6)),
      ],
    ];
  }
}
