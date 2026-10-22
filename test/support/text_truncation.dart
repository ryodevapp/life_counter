import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_counter/views/shared/expandable_text.dart';

/// 画面の文字が「…」や行数の上限で切れていないかを見る(LC の撮影の比べの穴: 1行が「…」で消えても合格になる)。
///
/// 描画木の [RenderParagraph] をすべてたどり、組んだ結果で切れたものを返す。
/// - 行数の上限を超えた([RenderParagraph.didExceedMaxLines])。「…」・切り落とし・薄く消すのどれでも
/// - 折り返さない文([RenderParagraph.softWrap] が偽)が、横の幅からはみ出した
///
/// 切れてよいもの(全文を読む手段が隣にあるもの)は数えない:
/// - [ExpandableText] の畳んだ文(「続きを読む」で全文に広がる)
///
/// [FittedBox] で縮めて1行に収める文は、幅の上限が無い中で組むので切れに数えられない(縮めるのは切れではない)。
/// 見えていない画面(下のタブの裏・前の画面)の文も、組まれていれば数える
List<TextTruncation> findTruncatedText(WidgetTester tester) {
  final found = <TextTruncation>[];
  void visit(RenderObject object) {
    if (object is RenderParagraph && object.hasSize) {
      final truncation = _check(object);
      if (truncation != null) found.add(truncation);
    }
    object.visitChildren(visit);
  }

  for (final view in tester.binding.renderViews) {
    visit(view);
  }
  return found;
}

/// 切れた文があれば失敗にする。[where] は失敗の文に入れる場所の名前(画面の名前など)
void expectNoTruncatedText(WidgetTester tester, {String where = ''}) {
  final found = findTruncatedText(tester);
  if (found.isEmpty) return;
  fail(describeTruncations(where, found));
}

/// 失敗の文。1行に1つ、場所・文字の大きさ・位置・文を出す
String describeTruncations(String where, List<TextTruncation> found) {
  final head = where.isEmpty ? '' : '$where: ';
  return '$head文字が切れています(${found.length}箇所)\n'
      '${found.map((t) => '  - $t').join('\n')}';
}

class TextTruncation {
  TextTruncation({
    required this.text,
    required this.reason,
    required this.rect,
    required this.textScale,
  });

  /// 文の全文(行を折らせない印 U+2060 は外す)
  final String text;

  /// 切れ方(行数の上限・横のはみ出し)
  final String reason;

  /// 画面の上の位置(論理の点)
  final Rect rect;

  /// 文字の倍率(既定 1.0、AX5 は 3.1)
  final double textScale;

  /// 位置を除いた中身(同じ文が何枚にも写るときに1つにまとめるため)
  String get summary => '「$text」 $reason 文字×${textScale.toStringAsFixed(1)}';

  @override
  String toString() {
    final r = rect;
    return '$summary '
        '(${r.left.toStringAsFixed(0)},${r.top.toStringAsFixed(0)} '
        '${r.width.toStringAsFixed(0)}×${r.height.toStringAsFixed(0)})';
  }
}

TextTruncation? _check(RenderParagraph p) {
  String? reason;
  if (p.didExceedMaxLines) {
    reason = '行数の上限 ${p.maxLines ?? 1} 行(${p.overflow.name})';
  } else if (!p.softWrap && p.constraints.maxWidth.isFinite) {
    // 折り返さない文は、上限の無い幅で組んだときの幅と比べる
    final full = p.getMaxIntrinsicWidth(double.infinity);
    if (full > p.size.width + 0.5) {
      reason =
          '横のはみ出し ${full.toStringAsFixed(0)}pt > ${p.size.width.toStringAsFixed(0)}pt';
    }
  }
  if (reason == null || _isAllowed(p)) return null;
  final topLeft = p.localToGlobal(Offset.zero);
  return TextTruncation(
    text: p.text.toPlainText().replaceAll('⁠', ''),
    reason: reason,
    rect: topLeft & p.size,
    textScale: p.textScaler.scale(100) / 100,
  );
}

bool _isAllowed(RenderParagraph p) => _isHidden(p) || _isInExpandableText(p);

/// 組まれていても見えない文(入力欄に字があるときの案内の文・裏に置いた画面)は数えない
bool _isHidden(RenderObject object) {
  for (RenderObject? o = object.parent; o != null; o = o.parent) {
    if (o is RenderOpacity && o.opacity == 0) return true;
    if (o is RenderAnimatedOpacity && o.opacity.value == 0) return true;
    if (o is RenderSliverOpacity && o.opacity == 0) return true;
    if (o is RenderOffstage && o.offstage) return true;
  }
  return false;
}

bool _isInExpandableText(RenderParagraph p) {
  final creator = p.debugCreator;
  if (creator is! DebugCreator) return false;
  final element = creator.element;
  return element.findAncestorWidgetOfExactType<ExpandableText>() != null;
}
