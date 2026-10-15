import 'package:flutter/material.dart';
import 'app_spacing.dart';
import 'app_text_styles.dart';

/// 画面の題(下のタブと同じ日本語を左寄せ)。どの画面も同じ位置・大きさ
class PageHeader extends StatelessWidget {
  const PageHeader(this.title, {super.key, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.l),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(child: Text(title, style: AppTextStyles.title)),
          ?trailing,
        ],
      ),
    );
  }
}
