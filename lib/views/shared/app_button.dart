import 'package:flutter/material.dart';
import '../../l10n/phrase_break.dart';
import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_text_styles.dart';

/// ボタン(iOS 26 と同じカプセル形)。主 = accent の塗り、副 = 薄い面
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.primary = false,
    this.expand = true,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final bool primary;
  final bool expand;

  factory AppButton.primary({
    Key? key,
    required VoidCallback? onPressed,
    required String label,
  }) {
    return AppButton(
      key: key,
      onPressed: onPressed,
      primary: true,
      // 文節で折る(最大の文字では行を増やす。1行に固定しない)
      child: PhraseText(label, textAlign: TextAlign.center),
    );
  }

  factory AppButton.secondary({
    Key? key,
    required VoidCallback? onPressed,
    required String label,
  }) {
    return AppButton(
      key: key,
      onPressed: onPressed,
      // 文節で折る(最大の文字では行を増やす。1行に固定しない)
      child: PhraseText(label, textAlign: TextAlign.center),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: expand ? double.infinity : null,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: primary ? AppColors.accent : AppColors.bgWarm,
          foregroundColor: primary ? AppColors.onAccent : AppColors.text,
          disabledBackgroundColor: AppColors.bgSub,
          disabledForegroundColor: AppColors.textDisabled,
          elevation: 0,
          minimumSize: const Size(AppSpacing.minTap, AppSpacing.buttonHeight),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          shape: const StadiumBorder(),
          splashFactory: NoSplash.splashFactory,
          textStyle: AppTextStyles.headline,
        ),
        child: child,
      ),
    );
  }
}
