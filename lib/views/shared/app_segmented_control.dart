import 'package:flutter/material.dart';
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

  @override
  Widget build(BuildContext context) {
    final index = items.indexWhere((i) => i.value == selectedValue);
    // 大きい文字では横に入らず項目の名前が切れるので、縦に並べる
    if (AppTextStyles.isAccessibilitySize(context)) {
      return _buildStacked(index < 0 ? 0 : index);
    }
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
                  style: AppTextStyles.callout.copyWith(
                    fontSize: 14,
                    fontWeight: t > 0.5 ? FontWeight.w600 : FontWeight.w400,
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
                  // 1語の名前なので、SE の最大の文字で幅に入らないときは1行のまま縮める(「バケットリス / ト」にしない)
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      items[i].label,
                      maxLines: 1,
                      style: AppTextStyles.callout.copyWith(
                        fontSize: 14,
                        fontWeight:
                            i == index ? FontWeight.w600 : FontWeight.w400,
                        color:
                            i == index ? AppColors.text : AppColors.textMuted,
                      ),
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
