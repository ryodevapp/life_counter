import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';
import 'app_spacing.dart';

/// 切り替え(Apple HIG の segmented control に合わせる)
/// 横幅いっぱい・項目は均等の幅で、白い面が選んだ項目へすべって移る。どの画面でも同じ形
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

  static const _inset = 3.0;
  static const _height = AppSpacing.minTap;

  @override
  Widget build(BuildContext context) {
    final index = items.indexWhere((i) => i.value == selectedValue);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return Container(
      height: _height + _inset * 2,
      padding: const EdgeInsets.all(_inset),
      decoration: BoxDecoration(
        color: AppColors.bgSub,
        borderRadius: BorderRadius.circular(AppRadius.md + _inset),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final segment = constraints.maxWidth / items.length;
          return Stack(
            children: [
              AnimatedPositioned(
                duration: reduceMotion ? Duration.zero : AppMotion.base,
                curve: Curves.easeOutCubic,
                left: segment * (index < 0 ? 0 : index),
                top: 0,
                bottom: 0,
                width: segment,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    boxShadow: AppColors.cardShadow,
                  ),
                ),
              ),
              Row(
                children: [
                  for (final item in items)
                    Expanded(
                      child: Semantics(
                        button: true,
                        selected: item.value == selectedValue,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => onChanged(item.value),
                          child: Center(
                            child: AnimatedDefaultTextStyle(
                              duration: AppMotion.base,
                              style: GoogleFonts.zenKakuGothicNew(
                                fontSize: 14,
                                fontWeight: item.value == selectedValue
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                                color: item.value == selectedValue
                                    ? AppColors.accent
                                    : AppColors.textMuted,
                              ),
                              child: Text(item.label, maxLines: 1),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class SegmentItem<T> {
  const SegmentItem({required this.value, required this.label});
  final T value;
  final String label;
}
