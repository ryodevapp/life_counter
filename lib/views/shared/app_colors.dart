import 'package:flutter/material.dart';

/// カラーパレット(design/design-system.md の「2. 色」。比は背景に対する値)
/// 端末の明るい表示・暗い表示に合わせて切り替わる。[dark] は LifeCounterApp が
/// 端末の設定から決め、変わったら画面全体を作り直す
class AppColors {
  AppColors._();

  /// いまの表示が暗い表示か
  static bool dark = false;

  static Color _pick(int light, int darkValue) =>
      Color(dark ? darkValue : light);

  // Background
  static Color get bg => _pick(0xFFFDFBF7, 0xFF1C1A18);
  static Color get bgWarm => _pick(0xFFF8F3EB, 0xFF2A2622);
  static Color get bgSub => _pick(0xFFF2EDE4, 0xFF332E29);

  // Card
  static Color get card => _pick(0xFFFFFFFF, 0xFF262320);

  /// 切り替え(リスト/カレンダーなど)の選んだ側。暗い表示では溝より明るくして浮かせる
  static Color get segmentPill => _pick(0xFFFFFFFF, 0xFF4A443D);

  // Accent (warm brown)。暗い表示では明るめの茶にして、暗い地でも読める濃さにする
  /// 文字・アイコン・主ボタンの塗り(明るい表示 5.0:1 / 暗い表示 6.4:1)
  static Color get accent => _pick(0xFF9A5F38, 0xFFD69B6B);
  static Color get accentLight => _pick(0xFFD4A574, 0xFFE3B98C);
  static Color get accentSurface => _pick(0x149A5F38, 0x1FD69B6B);
  static Color get accentSurface2 => _pick(0x269A5F38, 0x33D69B6B);

  /// アクセントや消す色の塗りの上に置く文字(明るい表示は白、暗い表示は濃い茶)
  static Color get onAccent => _pick(0xFFFFFFFF, 0xFF1C1A18);

  // Text
  static Color get text => _pick(0xFF2C2520, 0xFFF2EEE9);
  static Color get textSecondary => _pick(0xFF4A4039, 0xFFDAD3CB);
  /// 小さい見出し・日付・説明(5.5:1 / 6.9:1)
  static Color get textMuted => _pick(0xFF6E665D, 0xFFAEA59B);
  /// 入力欄の例の文・押せない状態だけ。読ませる文には使わない
  static Color get textDisabled => _pick(0xFF8A8279, 0xFF7E766D);

  /// 消す操作だけ
  static Color get danger => _pick(0xFFB3261E, 0xFFF2867B);

  // Border
  static Color get border => _pick(0x0F2C2520, 0x1FFFFFFF);
  static Color get borderAccent => _pick(0x409A5F38, 0x66D69B6B);

  /// 行の区切り線
  static Color get divider => _pick(0xFFECE6DC, 0xFF3A342F);

  // Glass(内容の上に浮かぶタブバーなどだけに使う)
  static Color get glassFill => _pick(0xB3FFFFFF, 0xB3262320);
  static Color get glassHighlight => _pick(0xE6FFFFFF, 0x33FFFFFF);
  static Color get glassEdge => _pick(0xCCFFFFFF, 0x26FFFFFF);
  /// ガラスの上で、選んだタブの下に敷くカプセル(少し沈んだ色 + 明るい縁)
  static Color get glassPill => _pick(0x1F9A5F38, 0x33D69B6B);
  static List<BoxShadow> get glassShadow => [
        // 輪郭の細い線(背景の上でも形が分かるように)
        BoxShadow(color: _pick(0x122C2520, 0x1FFFFFFF), spreadRadius: 0.5),
        BoxShadow(
          color: _pick(0x1A2C2520, 0x66000000),
          offset: const Offset(0, 10),
          blurRadius: 30,
        ),
      ];

  /// 切り替えやタブの、浮いた部品の薄い影
  static Color get softShadow => _pick(0x142C2520, 0x40000000);
  static Color get faintShadow => _pick(0x0A2C2520, 0x26000000);

  // Shadow
  /// カードの影は1段だけ(線は引かない)。暗い表示では影の代わりに地の明るさで浮かせる
  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: _pick(0x0F2C2520, 0x00000000),
          offset: const Offset(0, 1),
          blurRadius: 3,
        ),
      ];
}
