import 'package:flutter/material.dart';

/// カラーパレット(design/design-system.md の「2. 色」。比は背景 #FDFBF7 に対する値)
class AppColors {
  AppColors._();

  // Background
  static const Color bg = Color(0xFFFDFBF7);
  static const Color bgWarm = Color(0xFFF8F3EB);
  static const Color bgSub = Color(0xFFF2EDE4);

  // Card
  static const Color card = Color(0xFFFFFFFF);

  // Accent (warm brown)
  /// 文字・アイコン・主ボタンの塗り(5.0:1)
  static const Color accent = Color(0xFF9A5F38);
  static const Color accentLight = Color(0xFFD4A574);
  static const Color accentSurface = Color(0x149A5F38);
  static const Color accentSurface2 = Color(0x269A5F38);

  // Text（コントラスト比改善）
  static const Color text = Color(0xFF2C2520);
  static const Color textSecondary = Color(0xFF4A4039); // 旧#5C534A → 濃く
  /// 小さい見出し・日付・説明(5.5:1)
  static const Color textMuted = Color(0xFF6E665D);
  /// 入力欄の例の文・押せない状態だけ。読ませる文には使わない(3.7:1)
  static const Color textDisabled = Color(0xFF8A8279);

  /// 消す操作だけ(6.3:1)
  static const Color danger = Color(0xFFB3261E);

  // Border
  static const Color border = Color(0x0F2C2520);
  static const Color borderAccent = Color(0x409A5F38);

  /// 行の区切り線
  static const Color divider = Color(0xFFECE6DC);

  // Glass(内容の上に浮かぶタブバーなどだけに使う)
  static const Color glassFill = Color(0xB3FFFFFF); // 白 70%
  static const Color glassHighlight = Color(0xE6FFFFFF); // 上の縁の明るさ 90%
  static const Color glassEdge = Color(0xCCFFFFFF); // 細い明るい縁(光の当たる縁)
  /// ガラスの上で、選んだタブの下に敷くカプセル(少し沈んだ色 + 明るい縁)
  static const Color glassPill = Color(0x1F9A5F38);
  static const List<BoxShadow> glassShadow = [
    // 輪郭の細い線(明るい背景の上でも形が分かるように)
    BoxShadow(color: Color(0x122C2520), spreadRadius: 0.5),
    BoxShadow(
      color: Color(0x1A2C2520),
      offset: Offset(0, 10),
      blurRadius: 30,
    ),
  ];

  // Shadow
  static const List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Color(0x0A2C2520),
      offset: Offset(0, 1),
      blurRadius: 3,
    ),
    BoxShadow(
      color: Color(0x082C2520),
      offset: Offset(0, 4),
      blurRadius: 12,
    ),
  ];
}
