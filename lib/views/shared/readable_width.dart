import 'package:flutter/widgets.dart';

import 'app_spacing.dart';
import 'app_text_styles.dart';

/// 中身を読みやすい最大の幅までにして、左右の真ん中に置く。
/// 最大の幅は、既定の文字で `AppSpacing.readableWidth`。文字を大きくした人には、本文の文字が
/// 大きくなった分だけ広げる(UIKit の readableContentGuide も文字の大きさで幅が変わる。
/// 1行に入る字の数を保ち、大きな文字で折り返しが増えすぎないように)。
/// 幅が足りる iPhone では、今までどおり横幅いっぱい(幅はきっちり与え、高さは子に任せる)
class ReadableWidth extends StatelessWidget {
  const ReadableWidth({super.key, required this.child});

  final Widget child;

  /// 文字の大きさに合わせた最大の幅
  static double maxWidthOf(BuildContext context) {
    final bodySize = AppTextStyles.body.fontSize!;
    final scale = MediaQuery.textScalerOf(context).scale(bodySize) / bodySize;
    return AppSpacing.readableWidth * (scale < 1 ? 1 : scale);
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      heightFactor: 1,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidthOf(context)),
        child: SizedBox(width: double.infinity, child: child),
      ),
    );
  }
}
