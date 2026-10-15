import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_text_styles.dart';

/// 編集・削除の統一アクションバー
class ActionButtons extends StatelessWidget {
  const ActionButtons({
    super.key,
    this.onEdit,
    this.onDelete,
    this.editLabel = '編集',
    this.deleteLabel = '削除',
  });

  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final String editLabel;
  final String deleteLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (onEdit != null)
          Expanded(
            child: GestureDetector(
              onTap: onEdit,
              child: Container(
                constraints:
                    const BoxConstraints(minHeight: AppSpacing.buttonHeight),
                decoration: BoxDecoration(
                  color: AppColors.bgWarm,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Center(
                  child: Text(
                    editLabel,
                    style: AppTextStyles.callout
                        .copyWith(color: AppColors.textSecondary),
                  ),
                ),
              ),
            ),
          ),
        if (onEdit != null && onDelete != null)
          const SizedBox(width: AppSpacing.s),
        if (onDelete != null)
          Expanded(
            child: GestureDetector(
              onTap: onDelete,
              child: Container(
                constraints:
                    const BoxConstraints(minHeight: AppSpacing.buttonHeight),
                decoration: BoxDecoration(
                  color: AppColors.bgWarm,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Center(
                  child: Text(
                    deleteLabel,
                    style:
                        AppTextStyles.callout.copyWith(color: AppColors.danger),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// 統一された削除確認ダイアログ
Future<bool> showDeleteConfirmation(
  BuildContext context, {
  required String title,
  String message = 'この操作は取り消しできません',
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.card,
      title: Text(title, style: AppTextStyles.headline),
      content: Text(message,
          style:
              AppTextStyles.callout.copyWith(color: AppColors.textSecondary)),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sheet)),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          style: TextButton.styleFrom(
              minimumSize: const Size(AppSpacing.minTap, AppSpacing.minTap)),
          child: Text('キャンセル',
              style: AppTextStyles.callout
                  .copyWith(color: AppColors.textSecondary)),
        ),
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          style: TextButton.styleFrom(
              minimumSize: const Size(AppSpacing.minTap, AppSpacing.minTap)),
          child: Text('削除',
              style: AppTextStyles.callout.copyWith(color: AppColors.danger)),
        ),
      ],
    ),
  );
  return result ?? false;
}
