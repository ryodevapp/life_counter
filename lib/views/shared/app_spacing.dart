import 'package:flutter/physics.dart';

/// 余白(4pt 単位)。design/design-system.md の「4. 余白」
class AppSpacing {
  AppSpacing._();

  static const double xs = 4;
  static const double s = 8;
  static const double m = 12;
  static const double l = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;

  /// 画面の左右
  static const double screen = 20;

  /// カードの内側
  static const double card = 20;

  /// カードとカードの間
  static const double cardGap = 12;

  /// まとまりとまとまりの間
  static const double section = 32;

  /// 押せる範囲の最小(Apple HIG)
  static const double minTap = 44;

  /// ボタンの高さ
  static const double buttonHeight = 50;
}

/// 角の丸み。design/design-system.md の「5. 角の丸み」
class AppRadius {
  AppRadius._();

  static const double sm = 8;
  static const double md = 12;

  /// 入力欄(数行の欄)。カード(24)の内側で 20 の余白をとったとき、外の角と揃って見える丸み
  static const double field = 16;
  static const double lg = 24;
  static const double sheet = 28;
  static const double full = 999;
}

/// 動き。design/design-system.md の「7. 動き」
/// 位置・大きさはばね(少しだけ弾む)、色・透明度は時間で(弾ませない)
class AppMotion {
  AppMotion._();

  static const fast = Duration(milliseconds: 150);
  static const base = Duration(milliseconds: 220);
  static const slow = Duration(milliseconds: 350);

  /// 選んだ印がすべって移る動き(Material 3 Expressive の spatial default と同じ硬さ。
  /// 弾みは控えめにして、落ち着いたアプリに合わせる)
  static final spring =
      SpringDescription.withDampingRatio(mass: 1, stiffness: 380, ratio: 0.78);
}
