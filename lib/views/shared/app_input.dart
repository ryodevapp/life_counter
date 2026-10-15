import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_text_styles.dart';

/// プロトタイプのInコンポーネント再現
class AppInput extends StatelessWidget {
  const AppInput({
    super.key,
    this.controller,
    this.placeholder,
    this.maxLength,
    this.textAlign = TextAlign.start,
    this.onChanged,
    this.showBorder = false,
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
  final bool showBorder;
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
      decoration: InputDecoration(
        hintText: placeholder,
        hintStyle: AppTextStyles.callout.copyWith(color: AppColors.textDisabled),
        filled: true,
        fillColor: AppColors.bgWarm,
        counterText: '',
        // 高さ 48 以上(callout の1行 24 + 上下 12)
        contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.l, vertical: AppSpacing.m),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.field),
          borderSide: showBorder
              ? const BorderSide(color: AppColors.border)
              : BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.field),
          borderSide: showBorder
              ? const BorderSide(color: AppColors.border)
              : BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.field),
          borderSide: showBorder
              ? const BorderSide(color: AppColors.borderAccent)
              : BorderSide.none,
        ),
      ),
    );
  }
}
