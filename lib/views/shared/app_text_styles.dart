import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// タイポグラフィ（iOS HIG準拠の最小サイズ）
/// Body: Zen Kaku Gothic New / Display: Cormorant Garamond
class AppTextStyles {
  AppTextStyles._();

  // Display (Cormorant Garamond)
  static TextStyle get displayLarge => GoogleFonts.cormorantGaramond(
        fontSize: 80,
        fontWeight: FontWeight.w300,
        height: 1.0,
      );

  static TextStyle get displayMedium => GoogleFonts.cormorantGaramond(
        fontSize: 48,
        fontWeight: FontWeight.w300,
        height: 1.0,
      );

  static TextStyle get displaySmall => GoogleFonts.cormorantGaramond(
        fontSize: 32,
        fontWeight: FontWeight.w300,
      );

  static TextStyle get headlineLarge => GoogleFonts.cormorantGaramond(
        fontSize: 44,
        fontWeight: FontWeight.w300,
        height: 1.35,
      );

  static TextStyle get headlineMedium => GoogleFonts.cormorantGaramond(
        fontSize: 30,
        fontWeight: FontWeight.w300,
      );

  static TextStyle get headlineSmall => GoogleFonts.cormorantGaramond(
        fontSize: 24,
        fontWeight: FontWeight.w400,
      );

  // Counter (today tab)
  static TextStyle get counter => GoogleFonts.cormorantGaramond(
        fontSize: 76,
        fontWeight: FontWeight.w300,
        height: 1.0,
      );

  // Body (Zen Kaku Gothic New)
  static TextStyle get bodyLarge => GoogleFonts.zenKakuGothicNew(
        fontSize: 17, // iOS HIG body default
        fontWeight: FontWeight.w400,
        height: 1.6,
      );

  static TextStyle get bodyMedium => GoogleFonts.zenKakuGothicNew(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        height: 1.6,
      );

  static TextStyle get bodySmall => GoogleFonts.zenKakuGothicNew(
        fontSize: 14,
        fontWeight: FontWeight.w400,
      );

  static TextStyle get caption => GoogleFonts.zenKakuGothicNew(
        fontSize: 13, // 旧12 → 13
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
      );

  // ── デザインシステムの7段(design/design-system.md の「3. 文字」)。新しく書く文字はここから選ぶ ──

  /// 大きな数字(人生タブなど)
  static TextStyle get display => GoogleFonts.cormorantGaramond(
        fontSize: 34,
        fontWeight: FontWeight.w300,
        height: 1.1,
        color: AppColors.text,
      );

  /// 画面の題・詳しい画面の題
  static TextStyle get title => GoogleFonts.zenKakuGothicNew(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        height: 1.35,
        color: AppColors.text,
      );

  /// カードの題・問いの文
  static TextStyle get headline => GoogleFonts.zenKakuGothicNew(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        height: 1.4,
        color: AppColors.text,
      );

  /// 本文・答え
  static TextStyle get body => GoogleFonts.zenKakuGothicNew(
        fontSize: 17,
        fontWeight: FontWeight.w400,
        height: 1.65,
        color: AppColors.text,
      );

  /// 一覧の本文・説明
  static TextStyle get callout => GoogleFonts.zenKakuGothicNew(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        height: 1.6,
        color: AppColors.text,
      );

  /// 日付・補足
  static TextStyle get footnote => GoogleFonts.zenKakuGothicNew(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: AppColors.textMuted,
      );

  /// 小さい見出し(「今日の問い」など)・ラベル
  static TextStyle get captionLabel => GoogleFonts.zenKakuGothicNew(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        height: 1.4,
        color: AppColors.textMuted,
      );

  // ── ここから下は以前の名前(新しく使わない。直すときに上の7段へ寄せる) ──

  // Labels（カード内ヘッダー等）
  static TextStyle get label => GoogleFonts.zenKakuGothicNew(
        fontSize: 12, // 旧10 → 12
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        color: AppColors.textMuted,
      );

  // Section headers (YOUR LIFE, RECORDS等)
  static TextStyle get labelUppercase => GoogleFonts.zenKakuGothicNew(
        fontSize: 12, // 旧10 → 12
        fontWeight: FontWeight.w600,
        letterSpacing: 3.0,
        color: AppColors.textMuted,
      );

  // Pill label (PERMA category)
  static TextStyle get pill => GoogleFonts.zenKakuGothicNew(
        fontSize: 11, // 旧9 → 11
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        color: AppColors.accent,
      );

  // Tab label
  static TextStyle get tabLabel => GoogleFonts.zenKakuGothicNew(
        fontSize: 11, // 旧8 → 11
        fontWeight: FontWeight.w400,
      );

  static TextStyle get tabLabelActive => GoogleFonts.zenKakuGothicNew(
        fontSize: 11, // 旧8 → 11
        fontWeight: FontWeight.w600,
      );
}
