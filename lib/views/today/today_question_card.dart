import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../models/question.dart';
import '../../models/stamp.dart';
import '../shared/app_card.dart';
import '../shared/app_colors.dart';
import '../shared/app_spacing.dart';
import '../shared/app_text_styles.dart';
import '../shared/mood_face.dart';
import '../shared/mood_shape.dart';

/// 「今日はどんな一日だった？」に、気分を1つ選んで答える
class MoodCard extends StatelessWidget {
  const MoodCard({super.key, required this.selectedId, required this.onSelect});

  final String? selectedId;

  /// 同じものをもう一度押したら null(取り消し)
  final ValueChanged<String?> onSelect;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(moodQuestion, style: AppTextStyles.headline),
          const SizedBox(height: AppSpacing.m),
          Row(
            children: [
              for (final s in stamps)
                Expanded(
                  child: _MoodButton(
                    stamp: s,
                    selected: s.id == selectedId,
                    dimmed: selectedId != null && s.id != selectedId,
                    onTap: () => onSelect(s.id == selectedId ? null : s.id),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MoodButton extends StatelessWidget {
  const _MoodButton({
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
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedOpacity(
          duration: AppMotion.fast,
          opacity: dimmed ? 0.85 : 1,
          child: Column(
            children: [
              // 選ぶと、ばねで少し大きくなり、茶色の輪が付く
              AnimatedScale(
                scale: selected ? 1.08 : 1,
                duration: AppMotion.slow,
                curve: Curves.easeOutBack,
                child: AnimatedContainer(
                  duration: AppMotion.base,
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color:
                          AppColors.accent.withValues(alpha: selected ? 1 : 0),
                      width: 1.5,
                    ),
                  ),
                  child: MoodBadge(moodId: stamp.id, size: 46),
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                stamp.label,
                style: AppTextStyles.captionLabel.copyWith(
                  color: selected
                      ? moodLooks[stamp.id]!.ink
                      : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 今日の問い: 問い → その理由を聞くもう一歩(最初から出す)→ 書く欄 → 1年前の答え → バケットリストに追加
/// 声で入れたいときは、キーボードのマイク(iOS の音声入力)を使う。アプリ独自のマイクは持たない
class TodayQuestionCard extends StatelessWidget {
  const TodayQuestionCard({
    super.key,
    required this.question,
    required this.answerController,
    required this.onAnswerChanged,
    this.answerFocus,
    this.lastYearAnswer,
    this.onAddToBucket,
  });

  static const _maxChars = 1000;

  final Question question;
  final TextEditingController answerController;
  final FocusNode? answerFocus;
  final String? lastYearAnswer;
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
          Text('今日の問い', style: AppTextStyles.captionLabel),
          const SizedBox(height: AppSpacing.s),
          Text(question.text, style: AppTextStyles.headline),
          // 名詞ひとつで答えられる問いでも、理由や背景まで書けるように、もう一歩を最初から並べる
          if (question.followUp != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: Icon(CupertinoIcons.arrow_turn_down_right,
                      size: 15, color: AppColors.accent),
                ),
                const SizedBox(width: AppSpacing.s - 2),
                Expanded(
                  child: Text(question.followUp!,
                      style: AppTextStyles.callout
                          .copyWith(color: AppColors.textSecondary)),
                ),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.l),
          // カードの中に直接書く(塗りの欄を入れ子にしない)
          TextField(
            controller: answerController,
            focusNode: answerFocus,
            minLines: 3,
            maxLines: 12,
            maxLength: _maxChars,
            onChanged: onAnswerChanged,
            style: AppTextStyles.body,
            cursorColor: AppColors.accent,
            decoration: InputDecoration(
              hintText: 'ひとことでも大丈夫です。\nキーボードのマイクで、話して入力することもできます',
              hintMaxLines: 3,
              hintStyle:
                  AppTextStyles.body.copyWith(color: AppColors.textDisabled),
              counterText: '',
              isCollapsed: true,
              border: InputBorder.none,
            ),
          ),
          if (lastYearAnswer != null && lastYearAnswer!.trim().isNotEmpty) ...[
            const SizedBox(height: AppSpacing.l),
            Text('1年前の今日、あなたはこう答えました', style: AppTextStyles.captionLabel),
            const SizedBox(height: AppSpacing.xs),
            Text(
              lastYearAnswer!,
              style:
                  AppTextStyles.callout.copyWith(color: AppColors.textSecondary),
            ),
          ],
          if (showBucket) ...[
            const SizedBox(height: AppSpacing.m),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onAddToBucket,
                style: TextButton.styleFrom(
                  minimumSize: const Size(AppSpacing.minTap, AppSpacing.minTap),
                ),
                child: Text(
                  'バケットリストに追加',
                  style:
                      AppTextStyles.footnote.copyWith(color: AppColors.accent),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
