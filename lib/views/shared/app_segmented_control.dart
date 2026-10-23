import 'package:flutter/material.dart';
import '../../l10n/phrase_break.dart';
import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_text_styles.dart';
import 'sliding_pill_track.dart';

/// 切り替え(iOS 26 の segmented control に合わせる)
/// カプセルの土台に、白いカプセルの印。横幅いっぱい・項目は均等の幅。印はばねで移り、指でなぞっても選べる
class AppSegmentedControl<T> extends StatelessWidget {
  const AppSegmentedControl({
    super.key,
    required this.items,
    required this.selectedValue,
    required this.onChanged,
  });

  final List<SegmentItem<T>> items;
  final T selectedValue;
  final ValueChanged<T> onChanged;

  static const _height = 36.0;
  static const _inset = 3.0;

  /// 横並びのとき、項目の名前の左右に空ける幅(印の端に字が触れないように)
  static const _labelGap = 8.0;

  static TextStyle _labelStyle(bool selected) => AppTextStyles.callout.copyWith(
        fontSize: 14,
        fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
      );

  /// どれかの名前が、均等に分けた1項目の幅に1行で入らないか(太字で測る)
  bool _labelsOverflow(BuildContext context, double width) {
    if (!width.isFinite) return false;
    final slot = (width - _inset * 2) / items.length - _labelGap * 2;
    final scaler = MediaQuery.textScalerOf(context);
    final direction = Directionality.of(context);
    for (final item in items) {
      final p = TextPainter(
        text: TextSpan(text: item.label, style: _labelStyle(true)),
        textDirection: direction,
        textScaler: scaler,
        maxLines: 1,
      )..layout();
      final w = p.width;
      p.dispose();
      if (w > slot) return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final index = items.indexWhere((i) => i.value == selectedValue);
    // 大きい文字(AX1 以上)か、標準の最大でも名前が1項目の幅に入らない(SE の「バケットリスト」など)ときは、
    // 名前を切らずに縦に並べる(decisions 2026-10-23 夕方の段階表の②)
    if (AppTextStyles.isAccessibilitySize(context)) {
      return _buildStacked(index < 0 ? 0 : index);
    }
    return LayoutBuilder(builder: (context, constraints) {
      if (_labelsOverflow(context, constraints.maxWidth)) {
        return _buildStacked(index < 0 ? 0 : index);
      }
      return _buildRow(context, index);
    });
  }

  Widget _buildRow(BuildContext context, int index) {
    // 押せる範囲は 44 を保つ(見た目の土台は 36)
    return SizedBox(
      height: AppSpacing.minTap,
      child: Center(
        child: Container(
          height: _height,
          decoration: ShapeDecoration(
            color: AppColors.bgSub,
            shape: StadiumBorder(),
          ),
          child: SlidingPillTrack(
            count: items.length,
            index: index < 0 ? 0 : index,
            pillInset: _inset,
            onSelect: (i) => onChanged(items[i].value),
            pillDecoration: ShapeDecoration(
              color: AppColors.segmentPill,
              shape: StadiumBorder(),
              shadows: [
                BoxShadow(
                  color: AppColors.softShadow,
                  offset: Offset(0, 2),
                  blurRadius: 6,
                ),
                BoxShadow(
                  color: AppColors.faintShadow,
                  offset: Offset(0, 0),
                  blurRadius: 1,
                ),
              ],
            ),
            itemBuilder: (context, i, t) => Semantics(
              button: true,
              selected: i == index,
              child: Center(
                child: Text(
                  items[i].label,
                  maxLines: 1,
                  style: _labelStyle(t > 0.5).copyWith(
                    color: Color.lerp(AppColors.textMuted, AppColors.text, t),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 大きい文字のときの形: 同じ土台の中に項目を縦に並べ、選んだ項目に白い面を敷く
  Widget _buildStacked(int index) {
    return Container(
      padding: const EdgeInsets.all(_inset),
      decoration: ShapeDecoration(
        color: AppColors.bgSub,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < items.length; i++)
            Semantics(
              button: true,
              selected: i == index,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onChanged(items[i].value),
                child: AnimatedContainer(
                  duration: AppMotion.base,
                  curve: Curves.easeOutCubic,
                  constraints:
                      const BoxConstraints(minHeight: AppSpacing.minTap),
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.l, vertical: AppSpacing.xs),
                  alignment: Alignment.centerLeft,
                  decoration: ShapeDecoration(
                    color: i == index ? AppColors.segmentPill : null,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md)),
                  ),
                  // 幅に入らない名前は、語の切れ目で行を増やす(「バケット / リスト」)。
                  // それでも入らない1語だけ縮める(下限 0.85 倍かつ 11pt。PhraseText)
                  child: PhraseText(
                    items[i].label,
                    style: _labelStyle(i == index).copyWith(
                      color: i == index ? AppColors.text : AppColors.textMuted,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class SegmentItem<T> {
  const SegmentItem({required this.value, required this.label});
  final T value;
  final String label;
}
