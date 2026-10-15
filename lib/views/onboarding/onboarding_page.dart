import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/important_person.dart';
import '../../providers/isar_provider.dart';
import '../../providers/user_settings_provider.dart';
import '../../services/life_calculator.dart';
import '../../services/notification_service.dart';
import '../shared/app_colors.dart';
import '../shared/app_spacing.dart';
import '../shared/app_text_styles.dart';
import '../shared/app_button.dart';
import '../shared/app_input.dart';
import '../shared/count_up_text.dart';
import 'welcome_page.dart';
import 'birth_input_page.dart';

/// オンボーディング全体フロー
class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

enum _Screen { welcome, birth, steps }

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  _Screen _screen = _Screen.welcome;
  int _step = 0;
  DateTime? _birthDate;
  Gender _gender = Gender.unspecified;
  final _goalController = TextEditingController();

  @override
  void dispose() {
    _goalController.dispose();
    super.dispose();
  }

  void _goToBirth() => setState(() => _screen = _Screen.birth);

  void _goToSteps(DateTime birthDate, Gender gender) {
    setState(() {
      _birthDate = birthDate;
      _gender = gender;
      _screen = _Screen.steps;
      _step = 0;
    });
    ref
        .read(userSettingsProvider.notifier)
        .setBirthDateAndGender(birthDate, gender);
  }

  void _nextStep() {
    if (_step < 3) {
      setState(() => _step++);
    } else {
      _complete();
    }
  }

  void _prevStep() {
    if (_step > 0) setState(() => _step--);
  }

  Future<void> _complete() async {
    // オンボーディングのゴールをIsarに保存
    if (_goalController.text.isNotEmpty) {
      final repo = ref.read(dailyRecordRepositoryProvider);
      final record = await repo.getOrCreate(DateTime.now());
      record.todayGoal = _goalController.text;
      await repo.save(record);
    }
    // 通知許可リクエスト
    await NotificationService.requestPermission();
    // 朝の通知は、オンボーディングの完了を受けて MainTabView が予約する
    await ref.read(userSettingsProvider.notifier).completeOnboarding();
  }

  @override
  Widget build(BuildContext context) {
    switch (_screen) {
      case _Screen.welcome:
        return WelcomePage(onStart: _goToBirth);
      case _Screen.birth:
        return BirthInputPage(onNext: _goToSteps);
      case _Screen.steps:
        return _buildSteps();
    }
  }

  Widget _buildSteps() {
    final lifeDays = LifeCalculator.lifeDays(_birthDate!);
    final remainingDays =
        LifeCalculator.remainingDays(_birthDate!, _gender);

    return Scaffold(
      backgroundColor: AppColors.bg,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xxxl),
                    child: _stepContent(lifeDays, remainingDays),
                  ),
                ),
              ),
              // ページインジケーター
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (i) {
                  return AnimatedContainer(
                    duration: AppMotion.slow,
                    curve: Curves.easeOutCubic,
                    margin:
                        const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                    width: i == _step ? AppSpacing.xl : AppSpacing.s,
                    height: AppSpacing.s,
                    decoration: BoxDecoration(
                      color: i == _step ? AppColors.accent : AppColors.bgSub,
                      borderRadius: BorderRadius.circular(AppRadius.full),
                    ),
                  );
                }),
              ),
              const SizedBox(height: AppSpacing.xl),
              // ナビゲーションボタン
              Row(
                children: [
                  if (_step > 0) ...[
                    Expanded(
                      child:
                          AppButton.secondary(onPressed: _prevStep, label: '戻る'),
                    ),
                    const SizedBox(width: AppSpacing.s),
                  ],
                  Expanded(
                    child: AppButton.primary(
                      onPressed: _nextStep,
                      label: _step == 3 ? 'はじめる' : '次へ',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stepContent(int lifeDays, int remainingDays) {
    switch (_step) {
      case 0:
        // Step 1: 人生○○日目（カウントアップ）
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ブランドの表示なので英字のまま。字間だけはロゴとして広げる
            Text(
              'YOUR LIFE IN NUMBERS',
              style: AppTextStyles.captionLabel.copyWith(letterSpacing: 3),
            ),
            const SizedBox(height: AppSpacing.xxxl),
            Text(
              'あなたの人生は今日で',
              style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.l),
            CountUpText(
              target: lifeDays,
              style: AppTextStyles.counter.copyWith(color: AppColors.accent),
            ),
            const SizedBox(height: AppSpacing.s),
            Text(
              '日目です',
              style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
            ),
          ],
        );
      case 1:
        // Step 2: 残りの人生
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'これからの日々は',
              style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.l),
            CountUpText(
              target: remainingDays,
              style: AppTextStyles.counter.copyWith(color: AppColors.accent),
            ),
            const SizedBox(height: AppSpacing.s),
            Text(
              '日（平均からの目安）',
              style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.xxl),
            Text(
              'この日々を\nどう過ごしますか？',
              textAlign: TextAlign.center,
              style: AppTextStyles.callout.copyWith(color: AppColors.textMuted),
            ),
          ],
        );
      case 2:
        // Step 3: たった一度きり
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('\u{1F932}', style: AppTextStyles.display), // 🤲
            const SizedBox(height: AppSpacing.xxl),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: 'でも\n今日という日は\n人生で',
                    style: AppTextStyles.title,
                  ),
                  TextSpan(
                    text: 'たった一度きり',
                    style:
                        AppTextStyles.title.copyWith(color: AppColors.accent),
                  ),
                  TextSpan(
                    text: 'です',
                    style: AppTextStyles.title,
                  ),
                ],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        );
      case 3:
        // Step 4: 今日何をしますか + 入力
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '後悔のない毎日を\n',
                    style: AppTextStyles.title,
                  ),
                  TextSpan(
                    text: '一緒に積み重ねて',
                    style:
                        AppTextStyles.title.copyWith(color: AppColors.accent),
                  ),
                  TextSpan(
                    text: 'いけますように',
                    style: AppTextStyles.title,
                  ),
                ],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xxl),
            Container(
              width: AppSpacing.xxl,
              height: 1,
              color: AppColors.accent.withValues(alpha: 0.3),
            ),
            const SizedBox(height: AppSpacing.xxl),
            Text(
              '今日を素晴らしい一日にするために\n何をしますか？',
              style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            AppInput(
              controller: _goalController,
              placeholder: '小さなことでOK',
              maxLength: 200,
              textAlign: TextAlign.center,
            ),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }
}
