import 'package:flutter/material.dart';
import '../../l10n/l10n.dart';
import '../../l10n/phrase_break.dart';
import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_text_styles.dart';

/// 長い文は [maxLines] 行まで見せ、それを超えるときだけ「続きを読む」を出す。押すとその場で全文に広がる
/// (「…」で切ったまま全文を読む手段がない、という作りにしない)
class ExpandableText extends StatefulWidget {
  const ExpandableText(this.text,
      {super.key, required this.style, this.maxLines = 5});

  final String text;
  final TextStyle style;
  final int maxLines;

  @override
  State<ExpandableText> createState() => _ExpandableTextState();
}

class _ExpandableTextState extends State<ExpandableText> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    // 日本語は文節の途中で折らない(表示だけ。測るのも同じ文で。読み上げは元の文)
    final shown = PhraseBreak.apply(widget.text);
    return LayoutBuilder(builder: (context, constraints) {
      // 決めた行数に収まるかを測る(収まるなら「続きを読む」は出さない)
      final painter = TextPainter(
        text: TextSpan(text: shown, style: widget.style),
        maxLines: widget.maxLines,
        textDirection: TextDirection.ltr,
        textScaler: MediaQuery.textScalerOf(context),
      )..layout(maxWidth: constraints.maxWidth);
      final overflows = painter.didExceedMaxLines;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedSize(
            duration: AppMotion.base,
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            // 1文節が1行に入らないときの扱い(語の切れ目で折る・縮める)も PhraseText に任せる
            child: PhraseText(
              widget.text,
              style: widget.style,
              maxLines: _expanded ? null : widget.maxLines,
              overflow: _expanded ? TextOverflow.visible : TextOverflow.ellipsis,
            ),
          ),
          if (overflows)
            Semantics(
              button: true,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => setState(() => _expanded = !_expanded),
                child: Padding(
                  padding: const EdgeInsets.only(
                      top: AppSpacing.xs, bottom: AppSpacing.xs),
                  child: Text(
                    _expanded ? context.l10n.showLess : context.l10n.readMore,
                    style: AppTextStyles.footnote
                        .copyWith(color: AppColors.accent),
                  ),
                ),
              ),
            ),
        ],
      );
    });
  }
}
