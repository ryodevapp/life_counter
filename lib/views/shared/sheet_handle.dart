import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_spacing.dart';

/// 下から出るシートの上のつまみ(幅 36)。どのシートも同じ形
class SheetHandle extends StatelessWidget {
  const SheetHandle({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 36,
        height: 4,
        decoration: BoxDecoration(
          color: AppColors.bgSub,
          borderRadius: BorderRadius.circular(AppRadius.full),
        ),
      ),
    );
  }
}
