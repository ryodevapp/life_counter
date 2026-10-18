import 'package:flutter/material.dart';
import 'app_colors.dart';

/// 文字(design/design-system.md の「3. 文字」)
/// 文は端末の書体(英数字は SF、日本語はヒラギノ角ゴ)。Apple の純正アプリと同じで、
/// 「文字を大きく」の設定にも素直に従う。大きな数字だけ Cormorant Garamond
class AppTextStyles {
  AppTextStyles._();

  /// 日本語の字形をヒラギノに固定する(指定しないと中国語の字形が選ばれることがある)
  static const jpFallback = ['Hiragino Sans', 'Hiragino Kaku Gothic ProN'];

  static TextStyle _sans(double size, FontWeight weight, double height,
          [Color? color]) =>
      TextStyle(
        fontSize: size,
        fontWeight: weight,
        height: height,
        color: color ?? AppColors.text,
        fontFamilyFallback: jpFallback,
      );

  /// 大きな数字の書体。アプリに入れた Cormorant Garamond を使い、Google のサーバーからは読まない。
  /// 太さを変えられる1つのファイル(300〜700)なので、太さは fontVariations で指定する
  /// (fontWeight だけでは、ファイルの既定の太さ 300 のままになる)
  static TextStyle _serif(double size, int weight, double height) => TextStyle(
        fontFamily: 'CormorantGaramond',
        fontSize: size,
        fontWeight: FontWeight.values[weight ~/ 100 - 1],
        fontVariations: [FontVariation('wght', weight.toDouble())],
        height: height,
        color: AppColors.text,
      );

  /// 今日の「人生◯日目」だけ
  static TextStyle get counter => _serif(76, 300, 1.0);

  /// 大きな数字(人生タブなど)
  static TextStyle get display => _serif(34, 400, 1.1);

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

  /// 下のタブの文字の倍率の上限。iOS のタブバーと同じく、文字の設定を大きくしても大きくしない
  /// (Apple の Larger Text の基準で、繰り返し出る移動の部品は小さいままでよい)
  static const tabMaxTextScale = 1.0;

  /// 文字の設定がアクセシビリティの大きさ(AX1 以上)か。横並びを縦に積むかの分かれ目。
  /// 本文 17pt が標準の最大(xxxLarge)で 23pt(1.35 倍)、AX1 で 28pt(1.65 倍)なので、その間で分ける
  static bool isAccessibilitySize(BuildContext context) =>
      MediaQuery.textScalerOf(context).scale(17) / 17 > 1.5;
}
