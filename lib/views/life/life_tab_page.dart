import 'package:flutter/material.dart';
import '../shared/app_text_styles.dart';
import 'your_time_section.dart';

/// 人生タブ（家族は「家族」タブへ移った）
class LifeTabPage extends StatelessWidget {
  const LifeTabPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 48, 20, 130),
        child: Column(
          children: [
            Text('YOUR TIME', style: AppTextStyles.labelUppercase),
            const SizedBox(height: 28),
            const YourTimeSection(),
          ],
        ),
      ),
    );
  }
}
