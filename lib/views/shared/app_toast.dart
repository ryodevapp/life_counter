import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_text_styles.dart';

/// 統一トースト表示
class AppToast {
  AppToast._();

  /// 成功トースト（保存、更新、削除完了等）
  static void success(BuildContext context, String message) {
    _show(context, message, AppColors.accent);
  }

  /// エラートースト（バリデーション、通信エラー等）
  static void error(BuildContext context, String message) {
    _show(context, message, AppColors.danger);
  }

  static void _show(BuildContext context, String message, Color color) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: AppTextStyles.callout.copyWith(color: Colors.white),
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.full),
        ),
        // 下は浮かぶタブバーの上に出す
        margin: const EdgeInsets.fromLTRB(
            AppSpacing.screen, 0, AppSpacing.screen, 100),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
