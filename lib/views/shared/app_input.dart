import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_text_styles.dart';
import '../../l10n/phrase_break.dart';

/// プロトタイプのInコンポーネント再現
class AppInput extends StatelessWidget {
  const AppInput({
    super.key,
    this.controller,
    this.placeholder,
    this.maxLength,
    this.textAlign = TextAlign.start,
    this.onChanged,
    this.focusNode,
    this.textInputAction,
    this.minLines,
    this.maxLines = 1,
  });

  final TextEditingController? controller;
  final String? placeholder;
  final int? maxLength;
  final TextAlign textAlign;
  final ValueChanged<String>? onChanged;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;
  final int? minLines;
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      textInputAction: textInputAction,
      textAlign: textAlign,
      maxLength: maxLength,
      minLines: minLines,
      maxLines: maxLines,
      onChanged: onChanged,
      style: AppTextStyles.callout,
      cursorColor: AppColors.accent,
      // 今日の答えの欄と同じ見た目: 地より一段沈んだ面 + うすい枠。暗い表示でも書く場所が分かるように
      decoration: InputDecoration(
        // 案内は文節で折る(読み上げは元の文)
        hint: placeholder == null
            ? null
            : PhraseText(placeholder!,
                style: AppTextStyles.callout
                    .copyWith(color: AppColors.textDisabled)),
        filled: true,
        fillColor: AppColors.bg,
        counterText: '',
        // 高さ 48 以上(callout の1行 24 + 上下 12)
        contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.l, vertical: AppSpacing.m),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.field),
          borderSide: BorderSide(color: AppColors.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.field),
          borderSide: BorderSide(color: AppColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.field),
          borderSide: BorderSide(color: AppColors.borderAccent, width: 1.5),
        ),
      ),
    );
  }
}
