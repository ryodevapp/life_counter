import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/question.dart';
import '../../models/stamp.dart';
import '../shared/app_card.dart';
import '../shared/app_colors.dart';
import '../shared/app_input.dart';
import 'voice_input_button.dart';

/// 今日の問い: 問い → スタンプ → 話す・書く欄 → 1年前の答え → やりたいことに入れる
class TodayQuestionCard extends StatelessWidget {
  const TodayQuestionCard({
    super.key,
    required this.question,
    required this.answerController,
    required this.onStamp,
    required this.onAnswerChanged,
    this.answerFocus,
    this.selectedStampId,
    this.lastYearAnswer,
    this.onAddToBucket,
  });

  final Question question;
  final TextEditingController answerController;
  final FocusNode? answerFocus;
  final String? selectedStampId;
  final String? lastYearAnswer;

  /// 同じスタンプをもう一度押したら null(取り消し)
  final ValueChanged<String?> onStamp;
  final ValueChanged<String> onAnswerChanged;

  /// bucket の問いに答えがあるときだけ出す
  final VoidCallback? onAddToBucket;

  @override
  Widget build(BuildContext context) {
    final showBucket = question.isBucket &&
        onAddToBucket != null &&
        answerController.text.trim().isNotEmpty;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('今日の問い',
              style: GoogleFonts.zenKakuGothicNew(
                  fontSize: 12,
                  letterSpacing: 1.5,
                  color: AppColors.textMuted)),
          const SizedBox(height: 10),
          Text(question.text,
              style: GoogleFonts.zenKakuGothicNew(
                  fontSize: 17,
                  fontWeight: FontWeight.w500,
                  color: AppColors.text,
                  height: 1.6)),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (final s in stamps)
                _StampButton(
                  stamp: s,
                  selected: s.id == selectedStampId,
                  dimmed: selectedStampId != null && s.id != selectedStampId,
                  onTap: () => onStamp(s.id == selectedStampId ? null : s.id),
                ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: AppInput(
                  controller: answerController,
                  focusNode: answerFocus,
                  placeholder: '話す・書く(書かなくても大丈夫です)',
                  maxLength: 1000,
                  minLines: 2,
                  maxLines: 8,
                  onChanged: onAnswerChanged,
                ),
              ),
              VoiceInputButton(onResult: (text) {
                final current = answerController.text;
                final joined = current.isEmpty ? text : '$current $text';
                answerController.text = joined;
                onAnswerChanged(joined);
              }),
            ],
          ),
          if (lastYearAnswer != null && lastYearAnswer!.trim().isNotEmpty) ...[
            const SizedBox(height: 16),
            Text('1年前の今日、あなたはこう答えました',
                style: GoogleFonts.zenKakuGothicNew(
                    fontSize: 12, color: AppColors.textMuted)),
            const SizedBox(height: 6),
            Text(lastYearAnswer!,
                style: GoogleFonts.zenKakuGothicNew(
                    fontSize: 14,
                    fontWeight: FontWeight.w300,
                    color: AppColors.textSecondary,
                    height: 1.6)),
          ],
          if (showBucket) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onAddToBucket,
                child: Text('やりたいことリストに入れる',
                    style: GoogleFonts.zenKakuGothicNew(
                        fontSize: 13, color: AppColors.accent)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StampButton extends StatelessWidget {
  const _StampButton({
    required this.stamp,
    required this.selected,
    required this.dimmed,
    required this.onTap,
  });

  final Stamp stamp;
  final bool selected;
  final bool dimmed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: stamp.label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 150),
          opacity: dimmed ? 0.3 : 1,
          child: Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: selected ? AppColors.accentSurface2 : Colors.transparent,
            ),
            child: Text(stamp.emoji, style: const TextStyle(fontSize: 26)),
          ),
        ),
      ),
    );
  }
}
