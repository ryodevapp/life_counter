import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// 切り替え(iOS の segmented control と同じく、白い面が選んだ項目へすべって移る)
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

  static const _padding = 3.0;
  static const _height = 38.0;
  static const _labelPadding = 22.0;

  TextStyle _style(bool selected) => GoogleFonts.zenKakuGothicNew(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: selected ? AppColors.accent : AppColors.textMuted,
      );

  @override
  Widget build(BuildContext context) {
    // どの項目も同じ幅にする(いちばん長い言葉に合わせる)
    final scale = MediaQuery.textScalerOf(context);
    var maxLabel = 0.0;
    for (final item in items) {
      final p = TextPainter(
        text: TextSpan(text: item.label, style: _style(true)),
        textDirection: TextDirection.ltr,
        textScaler: scale,
      )..layout();
      if (p.width > maxLabel) maxLabel = p.width;
    }
    final segment = maxLabel + _labelPadding * 2;
    final index = items.indexWhere((i) => i.value == selectedValue);

    return Container(
      padding: const EdgeInsets.all(_padding),
      decoration: BoxDecoration(
        color: AppColors.bgSub,
        borderRadius: BorderRadius.circular(24),
      ),
      child: SizedBox(
        width: segment * items.length,
        height: _height,
        child: Stack(
          children: [
            AnimatedPositioned(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              left: segment * (index < 0 ? 0 : index),
              top: 0,
              bottom: 0,
              width: segment,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: AppColors.cardShadow,
                ),
              ),
            ),
            Row(
              children: [
                for (final item in items)
                  Semantics(
                    button: true,
                    selected: item.value == selectedValue,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => onChanged(item.value),
                      child: SizedBox(
                        width: segment,
                        height: _height,
                        child: Center(
                          child: AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 220),
                            style: _style(item.value == selectedValue),
                            child: Text(item.label),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class SegmentItem<T> {
  const SegmentItem({required this.value, required this.label});
  final T value;
  final String label;
}
