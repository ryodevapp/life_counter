import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../l10n/l10n.dart';
import '../../models/important_person.dart';
import '../../models/question.dart';
import '../../providers/question_bank_provider.dart';
import '../../providers/user_settings_provider.dart';
import '../../services/life_calculator.dart';
import '../../services/notification_service.dart';
import '../shared/app_card.dart';
import '../shared/app_colors.dart';
import '../shared/app_spacing.dart';
import '../shared/app_text_styles.dart';
import '../shared/app_button.dart';
import '../shared/count_up_text.dart';
import 'welcome_page.dart';
import 'birth_input_page.dart';

/// はじめての人の案内: はじめに → 生年月日 → 人生の日数 → 毎日の問い(通知)
/// 終わったら今日の画面に入り、最初の問いにそのまま答えられる
class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

enum _Screen { welcome, birth, lifeDays, question }

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  _Screen _screen = _Screen.welcome;
  DateTime? _birthDate;
  bool _finishing = false;

  void _goToLifeDays(DateTime birthDate, Gender gender) {
    setState(() {
      _birthDate = birthDate;
      _screen = _Screen.lifeDays;
    });
    ref
        .read(userSettingsProvider.notifier)
        .setBirthDateAndGender(birthDate, gender);
  }

  /// 通知を受け取るかどうかを決めて、案内を終える
  Future<void> _complete({required bool notify}) async {
    if (_finishing) return;
    setState(() => _finishing = true);
    final settings = ref.read(userSettingsProvider);
    final notifier = ref.read(userSettingsProvider.notifier);
    // 許可を求めるのは「通知を受け取る」を押したときだけ。断られたら設定も切っておく
    final enabled =
        notify ? await NotificationService.requestPermission() : false;
    await notifier.updateNotification(
      enabled: enabled,
      hour: settings.notificationHour,
      minute: settings.notificationMinute,
    );
    // 朝の通知は、案内の完了を受けて MainTabView が予約する
    await notifier.completeOnboarding();
  }

  @override
  Widget build(BuildContext context) {
    switch (_screen) {
      case _Screen.welcome:
        return WelcomePage(
            onStart: () => setState(() => _screen = _Screen.birth));
      case _Screen.birth:
        return BirthInputPage(onNext: _goToLifeDays);
      case _Screen.lifeDays:
        return _frame(
          content: _lifeDays(),
          buttons: [
            AppButton.primary(
              onPressed: () => setState(() => _screen = _Screen.question),
              label: context.l10n.next,
            ),
          ],
        );
      case _Screen.question:
        return _frame(
          content: _question(),
          buttons: [
            AppButton.primary(
              onPressed: _finishing ? null : () => _complete(notify: true),
              label: context.l10n.notifyAllow,
            ),
            const SizedBox(height: AppSpacing.s),
            TextButton(
              onPressed: _finishing ? null : () => _complete(notify: false),
              style: TextButton.styleFrom(
                minimumSize:
                    const Size(double.infinity, AppSpacing.buttonHeight),
                foregroundColor: AppColors.textSecondary,
                textStyle: AppTextStyles.body,
              ),
              child: Text(context.l10n.notifyLater),
            ),
          ],
        );
    }
  }

  /// 内容を上下の真ん中に、ボタンを下にまとめる
  Widget _frame({required Widget content, required List<Widget> buttons}) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
          child: Column(
            children: [
              Expanded(
                child: Center(child: SingleChildScrollView(child: content)),
              ),
              ...buttons,
              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _lifeDays() {
    final l = context.l10n;
    final lifeDays = LifeCalculator.lifeDays(_birthDate!);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          l.onboardingLifeDaysBefore,
          style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.l),
        CountUpText(
          target: lifeDays,
          style: AppTextStyles.counter.copyWith(color: AppColors.accent),
        ),
        const SizedBox(height: AppSpacing.s),
        Text(
          l.onboardingLifeDaysAfter,
          style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.xxl),
        Text(
          l.onboardingLifeDaysNote,
          textAlign: TextAlign.center,
          style: AppTextStyles.callout.copyWith(color: AppColors.textMuted),
        ),
      ],
    );
  }

  Widget _question() {
    final l = context.l10n;
    final settings = ref.watch(userSettingsProvider);
    final question = ref.read(questionBankProvider).forDate(DateTime.now());
    final time = DateFormat.jm(l.localeName).format(DateTime(
        2000, 1, 1, settings.notificationHour, settings.notificationMinute));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(l.onboardingQuestionTitle, style: AppTextStyles.title),
        const SizedBox(height: AppSpacing.xl),
        // 今日の問いの実物
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l.todaysQuestion, style: AppTextStyles.captionLabel),
              const SizedBox(height: AppSpacing.s),
              Text(questionWithFollowUp(question),
                  style: AppTextStyles.headline),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Text(
          l.onboardingQuestionBody,
          style: AppTextStyles.callout.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.m),
        Text(
          l.onboardingNotifyBody(time),
          style: AppTextStyles.callout.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
