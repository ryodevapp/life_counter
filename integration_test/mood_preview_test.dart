import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:life_counter/models/stamp.dart';
import 'package:life_counter/views/shared/app_card.dart';
import 'package:life_counter/views/shared/app_colors.dart';
import 'package:life_counter/views/shared/app_spacing.dart';
import 'package:life_counter/views/shared/app_text_styles.dart';
import 'package:life_counter/views/shared/mood_face.dart';
import 'package:life_counter/views/shared/mood_shape.dart';
import 'helpers.dart';

/// 気分の選び方の候補を、アプリと同じ部品で並べて撮る(本人に見比べてもらう見本。アプリには入らない)
const _lineColor = {
  'happy': Color(0xFFB8692F),
  'calm': Color(0xFF5F8C66),
  'neutral': Color(0xFF857B70),
  'tired': Color(0xFF6A7E99),
  'sad': Color(0xFF7E6E9E),
};

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  const selected = 'calm';

  Widget label(String text, bool sel, [Color? color]) => Text(text,
      style: AppTextStyles.captionLabel.copyWith(
          color: sel ? (color ?? AppColors.accent) : AppColors.textSecondary));

  Widget row(Widget Function(Stamp s, bool sel) item) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          for (final s in stamps)
            Opacity(
              opacity: s.id == selected ? 1 : 0.9,
              child: item(s, s.id == selected),
            ),
        ],
      );

  Widget card(String title, Widget child) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.cardGap),
        child: AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTextStyles.captionLabel),
              const SizedBox(height: AppSpacing.s),
              Text(moodQuestion, style: AppTextStyles.headline),
              const SizedBox(height: AppSpacing.l),
              child,
            ],
          ),
        ),
      );

  testWidgets('mood picker candidates', (tester) async {
    await tester.pumpWidget(MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(fontFamilyFallback: AppTextStyles.jpFallback),
      home: Scaffold(
        backgroundColor: AppColors.bg,
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.screen),
            children: [
              card(
                '案1 線の顔 + うすい色',
                row((s, sel) => Column(children: [
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: AppColors.accent
                                  .withValues(alpha: sel ? 1 : 0),
                              width: 1.5),
                        ),
                        child: MoodFace(
                          moodId: s.id,
                          size: 46,
                          ink: moodLooks[s.id]!.ink,
                          tint: moodLooks[s.id]!.light.withValues(alpha: 0.6),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      label(s.label, sel, moodLooks[s.id]!.ink),
                    ])),
              ),
              card(
                '案2 線の顔・一色(選ぶと色が付く)',
                row((s, sel) => Column(children: [
                      SizedBox(
                        width: 52,
                        height: 52,
                        child: Center(
                          child: MoodFace(
                            moodId: s.id,
                            size: 46,
                            ink: sel ? AppColors.accent : AppColors.textMuted,
                            tint: sel ? AppColors.accentSurface2 : null,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      label(s.label, sel),
                    ])),
              ),
              card(
                '案2b 線の顔・気分の色(調査のおすすめ)',
                row((s, sel) => Column(children: [
                      AnimatedContainer(
                        duration: Duration.zero,
                        width: 52,
                        height: 52,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _lineColor[s.id]!
                              .withValues(alpha: sel ? 0.16 : 0),
                        ),
                        child: MoodFace(
                          moodId: s.id,
                          size: 36,
                          ink: _lineColor[s.id]!,
                          stroke: sel ? 2 : 1.5,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      label(s.label, sel, _lineColor[s.id]),
                    ])),
              ),
              card(
                '案3 言葉の札 + 色の点',
                Wrap(
                  spacing: AppSpacing.s,
                  runSpacing: AppSpacing.s,
                  children: [
                    for (final s in stamps)
                      Container(
                        constraints: const BoxConstraints(minHeight: 40),
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.l - 2),
                        decoration: ShapeDecoration(
                          color: s.id == selected
                              ? moodLooks[s.id]!.light.withValues(alpha: 0.5)
                              : AppColors.card,
                          shape: StadiumBorder(
                              side: BorderSide(
                                  color: s.id == selected
                                      ? moodLooks[s.id]!.ink
                                      : AppColors.divider)),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: moodLooks[s.id]!.deep)),
                          const SizedBox(width: AppSpacing.s),
                          Text(s.label,
                              style: AppTextStyles.callout.copyWith(
                                  color: s.id == selected
                                      ? moodLooks[s.id]!.ink
                                      : AppColors.textSecondary)),
                        ]),
                      ),
                  ],
                ),
              ),
              card(
                '参考 前の絵文字',
                row((s, sel) => Column(children: [
                      Container(
                        width: 48,
                        height: 48,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: sel ? AppColors.accentSurface2 : AppColors.bgWarm,
                          border: Border.all(
                              color: AppColors.accent
                                  .withValues(alpha: sel ? 1 : 0),
                              width: 1.5),
                        ),
                        child: Text(s.emoji, style: AppTextStyles.title),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      label(s.label, sel),
                    ])),
              ),
            ],
          ),
        ),
      ),
    ));
    await wait(tester, 1500);
    await binding.takeScreenshot('mood_candidates');
  });
}
