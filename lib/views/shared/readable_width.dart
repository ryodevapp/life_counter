import 'package:flutter/widgets.dart';

import 'app_spacing.dart';

/// 中身を読みやすい最大の幅(`AppSpacing.readableWidth`)までにして、左右の真ん中に置く。
/// 幅が足りる iPhone では、今までどおり横幅いっぱい(幅はきっちり与え、高さは子に任せる)
class ReadableWidth extends StatelessWidget {
  const ReadableWidth({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      heightFactor: 1,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppSpacing.readableWidth),
        child: SizedBox(width: double.infinity, child: child),
      ),
    );
  }
}
