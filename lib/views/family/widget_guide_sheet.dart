import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../shared/app_button.dart';
import '../shared/app_colors.dart';

/// ホーム画面・ロック画面にウィジェットを置く方法
class WidgetGuideSheet extends StatelessWidget {
  const WidgetGuideSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const WidgetGuideSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget step(int n, String text) => Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 24,
              height: 24,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                  shape: BoxShape.circle, color: AppColors.accentSurface2),
              child: Text('$n',
                  style: GoogleFonts.zenKakuGothicNew(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.accent)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(text,
                  style: GoogleFonts.zenKakuGothicNew(fontSize: 14, height: 1.7)),
            ),
          ]),
        );

    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(28, 28, 28, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ホーム画面に、家族を',
                style: GoogleFonts.zenKakuGothicNew(
                    fontSize: 20, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text('アプリを開かなくても、次に会う日までの日数が毎日目に入ります。',
                style: GoogleFonts.zenKakuGothicNew(
                    fontSize: 14, height: 1.8, color: AppColors.textSecondary)),
            const SizedBox(height: 20),
            step(1, 'ホーム画面の空いた所を長押し'),
            step(2, '左上の「編集」→「ウィジェットを追加」'),
            step(3, '「LifeCounter」を選んで追加'),
            const SizedBox(height: 4),
            Text('ロック画面にも置けます。ロック画面を長押しして「カスタマイズ」から。',
                style: GoogleFonts.zenKakuGothicNew(
                    fontSize: 12, height: 1.7, color: AppColors.textMuted)),
            const SizedBox(height: 24),
            AppButton.primary(
                onPressed: () => Navigator.of(context).pop(), label: 'わかった'),
          ],
        ),
      ),
    );
  }
}
