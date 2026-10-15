import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../models/question.dart';
import '../../models/stamp.dart';
import '../shared/app_card.dart';
import '../shared/app_colors.dart';
import '../shared/app_spacing.dart';
import '../shared/app_text_styles.dart';
import 'voice_input_button.dart';

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
          opacity: dimmed ? 0.55 : 1,
          child: Column(
            children: [
              AnimatedContainer(
                duration: AppMotion.fast,
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  // 選んでいないときは丸を敷かない(同じ色の透明度0。途中で灰色にならないように)
                  color: AppColors.accentSurface2
                      .withValues(alpha: selected ? 0.15 : 0),
                  border: Border.all(
                    color: AppColors.accent.withValues(alpha: selected ? 1 : 0),
                    width: 1.5,
                  ),
                ),
                child: Text(stamp.emoji, style: AppTextStyles.title),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                stamp.label,
                style: AppTextStyles.captionLabel.copyWith(
                  color: selected ? AppColors.accent : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 今日の問い: 問い → 話す・書く欄(マイクは欄の中の右下)→ 1年前の答え → やりたいことに入れる
class TodayQuestionCard extends StatefulWidget {
  const TodayQuestionCard({
    super.key,
    required this.question,
    required this.answerController,
    required this.onAnswerChanged,
    this.answerFocus,
    this.lastYearAnswer,
    this.onAddToBucket,
    @visibleForTesting this.initiallyListening = false,
  });

  /// テストで「聞いている間」の見た目を確かめるためだけに使う
  final bool initiallyListening;

  final Question question;
  final TextEditingController answerController;
  final FocusNode? answerFocus;
  final String? lastYearAnswer;
  final ValueChanged<String> onAnswerChanged;

  /// bucket の問いに答えがあるときだけ出す
  final VoidCallback? onAddToBucket;

  @override
  State<TodayQuestionCard> createState() => _TodayQuestionCardState();
}

class _TodayQuestionCardState extends State<TodayQuestionCard> {
  static const _maxChars = 1000;
  late bool _listening = widget.initiallyListening;

  /// 話し始めたときの欄の文(話した分はこの後ろにつなぐ)
  String _base = '';

  /// もう一歩の問いを出しているか。書き終えて少し手が止まったら出し、そのあとは書き足していても出したまま
  /// (答えを空にしたら引っこめる)
  bool _showFollowUp = false;
  Timer? _idle;

  /// 書く手が止まってから、もう一歩の問いを出すまでの間
  static const _followUpDelay = Duration(milliseconds: 1500);

  @override
  void initState() {
    super.initState();
    _showFollowUp = widget.answerController.text.trim().isNotEmpty;
    widget.answerController.addListener(_onAnswerEdited);
  }

  @override
  void didUpdateWidget(TodayQuestionCard old) {
    super.didUpdateWidget(old);
    if (old.answerController != widget.answerController) {
      old.answerController.removeListener(_onAnswerEdited);
      widget.answerController.addListener(_onAnswerEdited);
    }
    // 日付が変わって別の問いになったら、出し直す
    if (old.question.id != widget.question.id) {
      _showFollowUp = widget.answerController.text.trim().isNotEmpty;
    }
  }

  @override
  void dispose() {
    _idle?.cancel();
    widget.answerController.removeListener(_onAnswerEdited);
    super.dispose();
  }

  void _onAnswerEdited() {
    final hasText = widget.answerController.text.trim().isNotEmpty;
    _idle?.cancel();
    if (!hasText) {
      if (_showFollowUp) setState(() => _showFollowUp = false);
      return;
    }
    if (_showFollowUp) return;
    _idle = Timer(_followUpDelay, () {
      if (mounted && widget.answerController.text.trim().isNotEmpty) {
        setState(() => _showFollowUp = true);
      }
    });
  }

  /// もう一歩の問いを押したら、答えの続きに改行を入れて、そのまま書けるようにする
  void _continueWriting() {
    final c = widget.answerController;
    final text = c.text.endsWith('\n') ? c.text : '${c.text}\n';
    if (text.characters.length > _maxChars) return;
    c.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
    widget.onAnswerChanged(text);
    widget.answerFocus?.requestFocus();
  }

  void _onWords(String words, bool isFinal) {
    final joined = words.isEmpty
        ? _base
        : (_base.isEmpty ? words : '$_base $words');
    final text = joined.characters.length > _maxChars
        ? joined.characters.take(_maxChars).toString()
        : joined;
    widget.answerController.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
    widget.onAnswerChanged(text);
    if (isFinal) _base = text;
  }

  @override
  Widget build(BuildContext context) {
    final showBucket =
        widget.question.isBucket &&
        widget.onAddToBucket != null &&
        widget.answerController.text.trim().isNotEmpty;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('今日の問い', style: AppTextStyles.captionLabel),
          const SizedBox(height: AppSpacing.s),
          Text(widget.question.text, style: AppTextStyles.headline),
          const SizedBox(height: AppSpacing.l),
          // マイクは欄の中の右下に重ねる(欄の外に並べるとガタつくため)
          Stack(
            children: [
              TextField(
                controller: widget.answerController,
                focusNode: widget.answerFocus,
                minLines: 3,
                maxLines: 10,
                maxLength: _maxChars,
                onChanged: widget.onAnswerChanged,
                style: AppTextStyles.body,
                cursorColor: AppColors.accent,
                // カードの中に直接書く(塗りの欄を入れ子にしない)。聞いている間は下の案内とマイクの動きで示す
                decoration: InputDecoration(
                  hintText: 'ひとことでも大丈夫です。\nマイクで話して入力することもできます',
                  hintMaxLines: 2,
                  hintStyle: AppTextStyles.body.copyWith(
                    color: AppColors.textDisabled,
                  ),
                  counterText: '',
                  isCollapsed: true,
                  border: InputBorder.none,
                  // 下はマイクのボタン(押せる範囲 44)の分を空ける
                  contentPadding: const EdgeInsets.only(
                      bottom: AppSpacing.minTap + AppSpacing.s),
                ),
              ),
              Positioned(
                // マイクは見た目 36・押せる範囲 44。カードの文字の右端に揃える
                right: 0,
                bottom: 0,
                child: VoiceInputButton(
                  onStart: () => setState(() {
                    _listening = true;
                    _base = widget.answerController.text.trim();
                  }),
                  onWords: _onWords,
                  onStop: () => setState(() => _listening = false),
                ),
              ),
            ],
          ),
          // 聞いている間だけ、欄の下に出す(欄の中の文と重ならないように)
          AnimatedSize(
            duration: AppMotion.base,
            child: _listening
                ? Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.s),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.accent,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.s),
                        Expanded(
                          child: Text(
                            '聞いています。■ で止まります',
                            style: AppTextStyles.footnote.copyWith(
                              color: AppColors.accent,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : const SizedBox(width: double.infinity),
          ),
          // もう一歩の問い(答えを書いたあとにだけ。答えなくても何も起きない)
          AnimatedSize(
            duration: AppMotion.slow,
            curve: Curves.easeOutCubic,
            child: AnimatedOpacity(
              duration: AppMotion.slow,
              opacity: _showFollowUp && !_listening ? 1 : 0,
              child: _showFollowUp &&
                      !_listening &&
                      widget.question.followUp != null
                  ? _FollowUp(
                      text: widget.question.followUp!,
                      onTap: _continueWriting,
                    )
                  : const SizedBox(width: double.infinity),
            ),
          ),
          if (widget.lastYearAnswer != null &&
              widget.lastYearAnswer!.trim().isNotEmpty) ...[
            const SizedBox(height: AppSpacing.l),
            Text('1年前の今日、あなたはこう答えました', style: AppTextStyles.captionLabel),
            const SizedBox(height: AppSpacing.xs),
            Text(
              widget.lastYearAnswer!,
              style: AppTextStyles.callout.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
          if (showBucket) ...[
            const SizedBox(height: AppSpacing.m),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: widget.onAddToBucket,
                style: TextButton.styleFrom(
                  minimumSize: const Size(AppSpacing.minTap, AppSpacing.minTap),
                ),
                child: Text(
                  'バケットリストに追加',
                  style: AppTextStyles.footnote.copyWith(
                    color: AppColors.accent,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// もう一歩の問い。押すと答えの続きを書ける
class _FollowUp extends StatelessWidget {
  const _FollowUp({required this.text, required this.onTap});

  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'もう一歩。$text',
      hint: '答えの続きを書く',
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          width: double.infinity,
          margin: const EdgeInsets.only(top: AppSpacing.m),
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.l, AppSpacing.m, AppSpacing.l, AppSpacing.m),
          decoration: BoxDecoration(
            color: AppColors.accentSurface,
            borderRadius: BorderRadius.circular(AppRadius.field),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 3),
                child: Icon(CupertinoIcons.arrow_turn_down_right,
                    size: 16, color: AppColors.accent),
              ),
              const SizedBox(width: AppSpacing.s),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('もう一歩',
                        style: AppTextStyles.captionLabel
                            .copyWith(color: AppColors.accent)),
                    const SizedBox(height: 2),
                    Text(text,
                        style: AppTextStyles.callout
                            .copyWith(color: AppColors.text)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
