import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../l10n/l10n.dart';
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
          Text(context.l10n.moodQuestion, style: AppTextStyles.headline),
          const SizedBox(height: AppSpacing.m),
          MoodPicker(selectedId: selectedId, onSelect: onSelect),
        ],
      ),
    );
  }
}

/// 気分の顔5つの並び(今日の画面と、記録の編集で同じものを使う)
class MoodPicker extends StatelessWidget {
  const MoodPicker({super.key, required this.selectedId, required this.onSelect});

  final String? selectedId;

  /// 同じものをもう一度押したら null(取り消し)
  final ValueChanged<String?> onSelect;

  @override
  Widget build(BuildContext context) {
    // 大きい文字では5つが横に入らず名前が1文字ずつ折れるので、顔と名前を横に並べた行を縦に積む
    if (AppTextStyles.isAccessibilitySize(context)) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final s in stamps)
            _MoodButton(
              stamp: s,
              selected: s.id == selectedId,
              dimmed: selectedId != null && s.id != selectedId,
              onTap: () => onSelect(s.id == selectedId ? null : s.id),
              horizontal: true,
            ),
        ],
      );
    }
    return Row(
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
    );
  }
}

class _MoodButton extends StatelessWidget {
  const _MoodButton({
    required this.stamp,
    required this.selected,
    required this.dimmed,
    required this.onTap,
    this.horizontal = false,
  });

  final Stamp stamp;
  final bool selected;
  final bool dimmed;
  final VoidCallback onTap;

  /// 顔の右に名前(大きい文字のとき)。既定は顔の下に名前
  final bool horizontal;

  @override
  Widget build(BuildContext context) {
    final label = moodLabel(context, stamp.id);
    final text = Text(
      label,
      style: AppTextStyles.captionLabel.copyWith(
        color: selected ? moodTextColor(stamp.id) : AppColors.textSecondary,
      ),
    );
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        // 選んでいない顔は、ウィジェットと同じ濃さ(0.4)まで薄くして、どれを選んだかをはっきりさせる
        child: AnimatedOpacity(
          duration: AppMotion.base,
          curve: Curves.easeOut,
          opacity: dimmed ? (AppColors.dark ? 0.55 : 0.4) : 1,
          child: Flex(
            direction: horizontal ? Axis.horizontal : Axis.vertical,
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
              SizedBox(
                  height: horizontal ? 0 : AppSpacing.xs,
                  width: horizontal ? AppSpacing.m : 0),
              // 横に並べるときだけ、残りの幅で折り返す(縦のときは高さが決まらないので付けない)
              if (horizontal) Flexible(child: text) else text,
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
    this.saved = false,
  });

  static const _maxChars = 1000;

  /// 自動で保存できた直後だけ true(欄の下に「保存しました」を少しのあいだ出す)
  final bool saved;

  final Question question;
  final TextEditingController answerController;
  final FocusNode? answerFocus;
  final String? lastYearAnswer;
  final ValueChanged<String> onAnswerChanged;

  /// bucket の問いに答えがあるときだけ出す
  final VoidCallback? onAddToBucket;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final showBucket = question.isBucket &&
        onAddToBucket != null &&
        answerController.text.trim().isNotEmpty;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.todaysQuestion, style: AppTextStyles.captionLabel),
          const SizedBox(height: AppSpacing.s),
          // 問いと、理由を聞くもう一歩を1つの文で(「没頭したいことは？ それに惹かれるのは、なぜ？」)
          Text(questionWithFollowUp(question), style: AppTextStyles.headline),
          const SizedBox(height: AppSpacing.l),
          // 書く場所だと分かるように、うすい枠の欄にする
          TextField(
            controller: answerController,
            focusNode: answerFocus,
            minLines: 4,
            maxLines: null,
            maxLength: _maxChars,
            onChanged: onAnswerChanged,
            style: AppTextStyles.body,
            cursorColor: AppColors.accent,
            keyboardType: TextInputType.multiline,
            decoration: InputDecoration(
              hintText: l.answerHint,
              hintMaxLines: 3,
              hintStyle:
                  AppTextStyles.body.copyWith(color: AppColors.textDisabled),
              counterText: '',
              filled: true,
              fillColor: AppColors.bg,
              contentPadding: const EdgeInsets.all(AppSpacing.l),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.field),
                borderSide: BorderSide(color: AppColors.divider),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.field),
                borderSide: BorderSide(color: AppColors.borderAccent, width: 1.5),
              ),
            ),
          ),
          // 自動で保存されたことを、欄の下に小さく知らせる(場所は空けておき、出し入れで揺れないように)
          SizedBox(
            height: 24,
            child: Align(
              alignment: Alignment.centerRight,
              child: AnimatedOpacity(
                opacity: saved ? 1 : 0,
                duration: AppMotion.base,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(CupertinoIcons.checkmark_alt,
                        size: 14, color: AppColors.textMuted),
                    const SizedBox(width: AppSpacing.xs),
                    Text(l.answerSaved, style: AppTextStyles.footnote),
                  ],
                ),
              ),
            ),
          ),
          if (lastYearAnswer != null && lastYearAnswer!.trim().isNotEmpty) ...[
            const SizedBox(height: AppSpacing.l),
            Text(l.lastYearAnswerLabel, style: AppTextStyles.captionLabel),
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
                  l.addToBucketList,
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
