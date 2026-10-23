import 'package:flutter/material.dart';
import 'app_spacing.dart';
import 'app_text_styles.dart';
import '../../l10n/phrase_break.dart';

/// 画面の題(iOS の Large Title と同じ 34pt・太字・左寄せ)。どの画面も同じ位置・大きさ
class PageHeader extends StatelessWidget {
  const PageHeader(this.title, {super.key, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.s, bottom: AppSpacing.l),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 題は1語。最大の文字で幅に入らないときは、語の途中で折らずに1行のまま縮める(「Journa / l」にしない)
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: PhraseText(title, style: AppTextStyles.largeTitle, maxLines: 1),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}
