import 'dart:ui';

import 'package:flutter/material.dart';
import 'app_colors.dart';

/// 内容の上に浮かぶ操作の部品(タブバーなど)だけに使う、ガラスの面
/// (Apple の Liquid Glass の考え方に合わせ、内容のカードには使わない)
class GlassSurface extends StatelessWidget {
  const GlassSurface({
    super.key,
    required this.child,
    this.borderRadius = 28,
    this.padding = EdgeInsets.zero,
  });

  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(borderRadius);
    // 高コントラストの設定では、透けない面にして読みやすさを優先する
    final opaque = MediaQuery.highContrastOf(context);
    final surface = Container(
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: radius,
        color: opaque ? AppColors.card : AppColors.glassFill,
        border: Border.all(
            color: opaque ? AppColors.border : AppColors.glassEdge, width: 0.8),
        gradient: opaque
            ? null
            : const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AppColors.glassHighlight, AppColors.glassFill],
              ),
      ),
      child: child,
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: AppColors.glassShadow,
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: opaque
            ? surface
            : BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                child: surface,
              ),
      ),
    );
  }
}
