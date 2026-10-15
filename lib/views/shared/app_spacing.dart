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
  static const double lg = 20;
  static const double sheet = 28;
  static const double full = 999;
}

/// 動き。design/design-system.md の「7. 動き」
class AppMotion {
  AppMotion._();

  static const fast = Duration(milliseconds: 150);
  static const base = Duration(milliseconds: 220);
  static const slow = Duration(milliseconds: 350);
}
