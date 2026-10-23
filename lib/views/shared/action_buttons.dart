import 'package:flutter/cupertino.dart';
import '../../l10n/l10n.dart';
import '../../l10n/phrase_break.dart';
import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_text_styles.dart';

/// 編集・削除の統一アクションバー
class ActionButtons extends StatelessWidget {
  const ActionButtons({
    super.key,
    this.onEdit,
    this.onDelete,
    this.editLabel,
    this.deleteLabel,
  });

  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  /// 省略すると「編集」「Edit」
  final String? editLabel;

  /// 省略すると「削除」「Delete」
  final String? deleteLabel;

  @override
  Widget build(BuildContext context) {
    final editLabel = this.editLabel ?? context.l10n.edit;
    final deleteLabel = this.deleteLabel ?? context.l10n.delete;
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
  String? message,
}) async {
  final l = context.l10n;
  final result = await showCupertinoDialog<bool>(
    context: context,
    builder: (ctx) => CupertinoAlertDialog(
      // 小窓は中身の高さを内在の大きさで測るので、PhraseText には文の入る幅を渡す
      title: PhraseText(title, width: cupertinoAlertTextWidth(ctx)),
      content: PhraseText(
        message ?? l.deleteConfirmMessage,
        width: cupertinoAlertTextWidth(ctx),
      ),
      actions: [
        CupertinoDialogAction(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text(l.cancel),
        ),
        CupertinoDialogAction(
          isDestructiveAction: true,
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text(l.delete),
        ),
      ],
    ),
  );
  return result ?? false;
}

/// CupertinoAlertDialog の見出しと本文の入る幅(Flutter の cupertino/dialog.dart と同じ値)。
/// 小窓の幅は 270、大きい文字(14pt が 1.4 倍を超える)では 310。左右に 20 ずつの余白
double cupertinoAlertTextWidth(BuildContext context) {
  final large = MediaQuery.textScalerOf(context).scale(14) > 14 * 1.4;
  return (large ? 310.0 : 270.0) - 20 * 2;
}
