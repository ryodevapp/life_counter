import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../shared/app_button.dart';
import '../shared/app_colors.dart';
import '../shared/app_spacing.dart';
import '../shared/app_text_styles.dart';

/// ウェルカム画面（プロトタイプの welcome 再現）
class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key, required this.onStart});

  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0.0, -0.4),
            radius: 0.7,
            colors: [
              AppColors.accentLight.withValues(alpha: 0.08),
              AppColors.accentLight.withValues(alpha: 0),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screen, vertical: AppSpacing.xl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
              children: [
                // ブランドの表示なので英字のまま。字間だけはロゴとして広げる
                Text(
                  'LIFE COUNTER',
                  style: AppTextStyles.captionLabel.copyWith(letterSpacing: 3),
                ),
                const SizedBox(height: AppSpacing.xxl),
                // グラデーション丸
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.accentLight, AppColors.accent],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),
                // タイトル
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: '人生は\n',
                        style: AppTextStyles.title,
                      ),
                      TextSpan(
                        text: '有限',
                        style: AppTextStyles.title.copyWith(
                          color: AppColors.accent,
                        ),
                      ),
                      TextSpan(
                        text: 'だから',
                        style: AppTextStyles.title,
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.l),
                Text(
                  '今日が人生の何日目か\n知っていますか\n\n残りの日々を意識することで\n毎日をもっと大切に過ごせるように',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.callout.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxxl),
                // はじめるボタン
                AppButton.primary(onPressed: onStart, label: 'はじめる'),
                const SizedBox(height: AppSpacing.xxxl),
                // 下矢印アニメーション
                const _BreathingArrow(),
              ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BreathingArrow extends StatefulWidget {
  const _BreathingArrow();

  @override
  State<_BreathingArrow> createState() => _BreathingArrowState();
}

class _BreathingArrowState extends State<_BreathingArrow>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 3500),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.3, end: 0.8).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
      ),
      child: Icon(
        CupertinoIcons.chevron_down,
        color: AppColors.textMuted,
        size: 24,
      ),
    );
  }
}
