import 'dart:ui';

import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_spacing.dart';

/// 内容の上に浮かぶ操作の部品(タブバーなど)だけに使う、ガラスの面
/// (Apple の Liquid Glass の考え方に合わせ、内容のカードには使わない)
class GlassSurface extends StatelessWidget {
  const GlassSurface({
    super.key,
    required this.child,
    this.borderRadius = AppRadius.sheet,
    this.padding = EdgeInsets.zero,
  });

  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry padding;

  // 彩度 1.4 倍の色の行列
  static const List<double> _saturate = [
    1.315, -0.286, -0.029, 0, 0, //
    -0.085, 1.114, -0.029, 0, 0, //
    -0.085, -0.286, 1.371, 0, 0, //
    0, 0, 0, 1, 0, //
  ];

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
            color: opaque ? AppColors.border : AppColors.glassEdge, width: 0.5),
        gradient: opaque
            ? null
            : LinearGradient(
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
                // ぼかしに加えて色を少し濃くする(下の色がにじんで見え、ガラスらしくなる)
                filter: ImageFilter.compose(
                  outer: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                  inner: const ColorFilter.matrix(_saturate),
                ),
                child: surface,
              ),
      ),
    );
  }
}
