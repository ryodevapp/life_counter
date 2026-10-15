import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';
import 'app_spacing.dart';

/// プロトタイプのBtコンポーネント再現
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
      child: Text(label),
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
      child: Text(label),
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
          foregroundColor: primary ? Colors.white : AppColors.text,
          disabledBackgroundColor: AppColors.bgSub,
          disabledForegroundColor: AppColors.textDisabled,
          elevation: 0,
          minimumSize: const Size(AppSpacing.minTap, AppSpacing.buttonHeight),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          textStyle: GoogleFonts.zenKakuGothicNew(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        child: child,
      ),
    );
  }
}
