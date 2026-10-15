import 'package:flutter/cupertino.dart';
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
                  borderRadius: BorderRadius.circular(AppRadius.full),
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
                  borderRadius: BorderRadius.circular(AppRadius.full),
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

/// 削除の確認(iOS の確認の小窓と同じ形。「削除」は赤、既定の選択にしない)
Future<bool> showDeleteConfirmation(
  BuildContext context, {
  required String title,
  String message = 'この操作は取り消せません。',
}) async {
  final result = await showCupertinoDialog<bool>(
    context: context,
    builder: (ctx) => CupertinoAlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        CupertinoDialogAction(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text('キャンセル'),
        ),
        CupertinoDialogAction(
          isDestructiveAction: true,
          onPressed: () => Navigator.of(ctx).pop(true),
          child: const Text('削除'),
        ),
      ],
    ),
  );
  return result ?? false;
}
