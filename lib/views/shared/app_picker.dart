import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_text_styles.dart';
import 'sheet_handle.dart';

/// 統一ピッカー（タップでボトムシートを開くセレクトUI）
class AppPicker<T> extends StatelessWidget {
  const AppPicker({
    super.key,
    required this.value,
    required this.displayText,
    required this.options,
    required this.onChanged,
    this.title,
  });

  final T value;
  final String displayText;
  final List<AppPickerOption<T>> options;
  final ValueChanged<T> onChanged;
  final String? title;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showPicker(context),
      // 見た目は AppInput と同じ(bgWarm・角 field・枠なし・高さ 48 以上)
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 48),
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.l, vertical: AppSpacing.m),
        decoration: BoxDecoration(
          color: AppColors.bgWarm,
          borderRadius: BorderRadius.circular(AppRadius.field),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(displayText, style: AppTextStyles.callout),
            ),
            Icon(
              CupertinoIcons.chevron_down,
              color: AppColors.textMuted,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  void _showPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _PickerSheet<T>(
        title: title,
        options: options,
        selectedValue: value,
        onSelected: (v) {
          Navigator.of(ctx).pop();
          onChanged(v);
        },
      ),
    );
  }
}

class AppPickerOption<T> {
  const AppPickerOption({required this.value, required this.label});
  final T value;
  final String label;
}

class _PickerSheet<T> extends StatelessWidget {
  const _PickerSheet({
    required this.options,
    required this.selectedValue,
    required this.onSelected,
    this.title,
  });

  final String? title;
  final List<AppPickerOption<T>> options;
  final T selectedValue;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.5;
    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: const BoxDecoration(
        color: AppColors.card,
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ハンドル
          const Padding(
            padding: EdgeInsets.only(top: AppSpacing.m, bottom: AppSpacing.xs),
            child: SheetHandle(),
          ),
          if (title != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.m),
              child: Text(title!, style: AppTextStyles.headline),
            ),
          const Divider(height: 1, color: AppColors.divider),
          // 選択肢リスト
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: options.length,
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
              itemBuilder: (context, index) {
                final option = options[index];
                final isSelected = option.value == selectedValue;
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onSelected(option.value),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xl, vertical: AppSpacing.l),
                    color: isSelected
                        ? AppColors.accentSurface
                        : AppColors.accentSurface.withValues(alpha: 0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            option.label,
                            style: AppTextStyles.callout.copyWith(
                              color: isSelected
                                  ? AppColors.accent
                                  : AppColors.text,
                            ),
                          ),
                        ),
                        if (isSelected)
                          const Icon(
                            CupertinoIcons.checkmark,
                            color: AppColors.accent,
                            size: 20,
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          SizedBox(
              height: MediaQuery.of(context).padding.bottom + AppSpacing.s),
        ],
      ),
    );
  }
}
