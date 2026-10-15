import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/question.dart';
import '../../models/stamp.dart';
import '../shared/app_card.dart';
import '../shared/app_colors.dart';
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
          Text(moodQuestion,
              style: GoogleFonts.zenKakuGothicNew(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: AppColors.text)),
          const SizedBox(height: 14),
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
          duration: const Duration(milliseconds: 150),
          opacity: dimmed ? 0.55 : 1,
          child: Column(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color:
                      selected ? AppColors.accentSurface2 : AppColors.bgWarm,
                  border: Border.all(
                      color: AppColors.accent.withValues(alpha: selected ? 1 : 0),
                      width: 1.5),
                ),
                child: Text(stamp.emoji, style: const TextStyle(fontSize: 24)),
              ),
              const SizedBox(height: 6),
              Text(stamp.label,
                  style: GoogleFonts.zenKakuGothicNew(
                      fontSize: 11,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                      color: selected
                          ? AppColors.accent
                          : AppColors.textSecondary)),
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

  OutlineInputBorder _border(Color color) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: color),
      );

  @override
  Widget build(BuildContext context) {
    final showBucket = widget.question.isBucket &&
        widget.onAddToBucket != null &&
        widget.answerController.text.trim().isNotEmpty;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('今日の問い',
              style: GoogleFonts.zenKakuGothicNew(
                  fontSize: 12, letterSpacing: 1.5, color: AppColors.textMuted)),
          const SizedBox(height: 10),
          Text(widget.question.text,
              style: GoogleFonts.zenKakuGothicNew(
                  fontSize: 17,
                  fontWeight: FontWeight.w500,
                  color: AppColors.text,
                  height: 1.6)),
          const SizedBox(height: 16),
          // マイクは欄の中の右下に重ねる(欄の外に並べるとガタつくため)
          Stack(
            children: [
              TextField(
                controller: widget.answerController,
                focusNode: widget.answerFocus,
                minLines: 4,
                maxLines: 10,
                maxLength: _maxChars,
                onChanged: widget.onAnswerChanged,
                style: GoogleFonts.zenKakuGothicNew(
                    fontSize: 15,
                    fontWeight: FontWeight.w300,
                    color: AppColors.text,
                    height: 1.7),
                decoration: InputDecoration(
                  hintText: '書く、または右下のマイクで話す\n(書かなくても大丈夫です)',
                  hintMaxLines: 2,
                  hintStyle: GoogleFonts.zenKakuGothicNew(
                      fontSize: 14,
                      fontWeight: FontWeight.w300,
                      color: AppColors.textDisabled,
                      height: 1.6),
                  filled: true,
                  fillColor: AppColors.bgWarm,
                  counterText: '',
                  contentPadding: const EdgeInsets.fromLTRB(16, 14, 16, 52),
                  border: _border(Colors.transparent),
                  enabledBorder: _border(
                      _listening ? AppColors.accent : Colors.transparent),
                  focusedBorder: _border(
                      _listening ? AppColors.accent : AppColors.borderAccent),
                ),
              ),
              Positioned(
                right: 10,
                bottom: 10,
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
            duration: const Duration(milliseconds: 180),
            child: _listening
                ? Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                              color: AppColors.accent, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text('聞いています。話し終えたら ■ を押してください',
                              style: GoogleFonts.zenKakuGothicNew(
                                  fontSize: 12, color: AppColors.accent)),
                        ),
                      ],
                    ),
                  )
                : const SizedBox(width: double.infinity),
          ),
          if (widget.lastYearAnswer != null &&
              widget.lastYearAnswer!.trim().isNotEmpty) ...[
            const SizedBox(height: 16),
            Text('1年前の今日、あなたはこう答えました',
                style: GoogleFonts.zenKakuGothicNew(
                    fontSize: 12, color: AppColors.textMuted)),
            const SizedBox(height: 6),
            Text(widget.lastYearAnswer!,
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
                onPressed: widget.onAddToBucket,
                child: Text('やりたいこと(バケットリスト)に入れる',
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
