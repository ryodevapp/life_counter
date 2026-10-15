import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// 文字(design/design-system.md の「3. 文字」)
/// 文は端末の書体(英数字は SF、日本語はヒラギノ角ゴ)。Apple の純正アプリと同じで、
/// 「文字を大きく」の設定にも素直に従う。大きな数字だけ Cormorant Garamond
class AppTextStyles {
  AppTextStyles._();

  /// 日本語の字形をヒラギノに固定する(指定しないと中国語の字形が選ばれることがある)
  static const jpFallback = ['Hiragino Sans', 'Hiragino Kaku Gothic ProN'];

  static TextStyle _sans(double size, FontWeight weight, double height,
          [Color color = AppColors.text]) =>
      TextStyle(
        fontSize: size,
        fontWeight: weight,
        height: height,
        color: color,
        fontFamilyFallback: jpFallback,
      );

  /// 今日の「人生◯日目」だけ
  static TextStyle get counter => GoogleFonts.cormorantGaramond(
        fontSize: 76,
        fontWeight: FontWeight.w300,
        height: 1.0,
        color: AppColors.text,
      );

  /// 大きな数字(人生タブなど)
  static TextStyle get display => GoogleFonts.cormorantGaramond(
        fontSize: 34,
        fontWeight: FontWeight.w400,
        height: 1.1,
        color: AppColors.text,
      );

  /// 画面のいちばん上の題。ヒラギノは SF より黒く見えるので、34pt・太字にせず 28pt・600 にとどめる
  static TextStyle get largeTitle => _sans(28, FontWeight.w600, 1.25);

  /// 詳しい画面の題・まとまりの題
  static TextStyle get title => _sans(22, FontWeight.w700, 1.35);

  /// カードの題・問いの文
  static TextStyle get headline => _sans(17, FontWeight.w600, 1.5);

  /// 本文・答え(日本語は行の間を広めに)
  static TextStyle get body => _sans(17, FontWeight.w400, 1.6);

  /// 一覧の本文・説明
  static TextStyle get callout => _sans(15, FontWeight.w400, 1.6);

  /// 日付・補足
  static TextStyle get footnote =>
      _sans(13, FontWeight.w400, 1.5, AppColors.textMuted);

  /// 小さい見出し(「今日の問い」など)・ラベル
  static TextStyle get captionLabel =>
      _sans(13, FontWeight.w600, 1.4, AppColors.textMuted);

  /// 下のタブの文字(iOS のタブバーと同じ 10〜11pt)
  static TextStyle get tab => _sans(11, FontWeight.w600, 1.2);
}
