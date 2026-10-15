import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_text_styles.dart';

/// プロトタイプのPlコンポーネント再現
class PillLabel extends StatelessWidget {
  const PillLabel({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: AppColors.accentSurface,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Text(text,
          style: AppTextStyles.captionLabel.copyWith(color: AppColors.accent)),
    );
  }
}
