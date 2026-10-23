import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_counter/l10n/l10n.dart';
import 'package:life_counter/l10n/phrase_break.dart';

/// 日本語の文が、文節(BudouX)の途中で行を折られた所を探す(LC 日本語の改行。1.1.4)。
///
/// 描画木の [RenderParagraph] をすべてたどり、組んだ結果の行の頭が文節の切れ目でない所を返す。
/// 改行・空白の前後で折れたものは数えない。[PhraseText] の中で割れたものは
/// 「1文節が1行に入らない」(印を入れても組版が字の途中で折った)として分けて返す。
/// 文節の辞書が読めていないとき(PHRASE=off)は何も返さない
List<PhraseSplit> findPhraseSplits(WidgetTester tester) {
  final found = <PhraseSplit>[];
  void visit(RenderObject object) {
    if (object is RenderParagraph && object.hasSize && !_isHidden(object)) {
      found.addAll(_check(object));
    }
    object.visitChildren(visit);
  }

  for (final view in tester.binding.renderViews) {
    visit(view);
  }
  return found;
}

class PhraseSplit {
  PhraseSplit({
    required this.text,
    required this.before,
    required this.after,
    required this.tooLong,
  });

  /// 文の全文(印 U+2060 は外す)
  final String text;

  /// 折れ目の前と後(数字ずつ)
  final String before;
  final String after;

  /// [PhraseText] の中でも語の途中で割れた(縮める下限に当たった)
  final bool tooLong;

  String get summary =>
      '${tooLong ? '[PhraseText でも語の途中] ' : ''}「${text.replaceAll('\n', '⏎')}」 '
      '…${before.replaceAll('\n', '⏎')}/${after.replaceAll('\n', '⏎')}…';

  @override
  String toString() => summary;
}

final _japanese = RegExp(r'[぀-ヿ㐀-鿿]');
final _space = RegExp(r'\s');

List<PhraseSplit> _check(RenderParagraph p) {
  final shown = p.text.toPlainText(includeSemanticsLabels: false);
  if (!_japanese.hasMatch(shown)) return const [];
  // 長い本文は OS の標準の折りに任せる(PhraseBreak.maxLength)
  if (!PhraseBreak.appliesTo(shown)) return const [];
  final plain = stripWordJoiners(shown);
  // PhraseText の中では、1文節が1行に入らないときに語の切れ目で折るので、語の切れ目も許す
  final inPhraseText = _isInPhraseText(p);
  final bounds = inPhraseText
      ? PhraseBreak.wordBoundaries(plain)
      : PhraseBreak.phraseBoundaries(plain);
  if (bounds == null) return const [];

  // 絵や部品を入れた文(WidgetSpan)は組み直せないので見ない
  if (!p.softWrap || !p.constraints.maxWidth.isFinite || shown.contains('\uFFFC')) {
    return const [];
  }

  // 行の頭(表示の文の位置)。RenderParagraph と同じ条件で組み直して行を見る
  final painter = TextPainter(
    text: p.text,
    textAlign: p.textAlign,
    textDirection: p.textDirection,
    textScaler: p.textScaler,
    maxLines: p.maxLines,
    locale: p.locale,
    strutStyle: p.strutStyle,
    textWidthBasis: p.textWidthBasis,
    textHeightBehavior: p.textHeightBehavior,
  )..layout(maxWidth: p.constraints.maxWidth);
  final starts = <int>{};
  for (var i = 0; i < shown.length; i++) {
    final start = painter.getLineBoundary(TextPosition(offset: i)).start;
    if (start > 0) starts.add(start);
  }
  // 行数の上限で切った文(「…」)は、見えている行の頭だけを見る
  final visibleLines = painter.computeLineMetrics().length;
  painter.dispose();
  final heads = (starts.toList()..sort()).take(visibleLines - 1).toList();
  if (heads.isEmpty) return const [];

  final result = <PhraseSplit>[];
  for (final k in heads) {
    // 表示の文の位置 → 印を外した文の位置
    final at = stripWordJoiners(shown.substring(0, k)).length;
    if (at <= 0 || at >= plain.length) continue;
    final prev = plain[at - 1];
    final next = plain[at];
    if (prev == '\n' || _space.hasMatch(prev) || _space.hasMatch(next)) {
      continue;
    }
    if (bounds.contains(at)) continue;
    // 日本語の字どうしの間でなければ数えない(英数字の語の切れ目は組版に任せる)
    if (!_japanese.hasMatch(prev) && !_japanese.hasMatch(next)) continue;
    result.add(PhraseSplit(
      text: plain,
      before: plain.substring((at - 6).clamp(0, at), at),
      after: plain.substring(at, (at + 6).clamp(at, plain.length)),
      tooLong: inPhraseText,
    ));
  }
  return result;
}

bool _isHidden(RenderObject object) {
  for (RenderObject? o = object.parent; o != null; o = o.parent) {
    if (o is RenderOpacity && o.opacity == 0) return true;
    if (o is RenderAnimatedOpacity && o.opacity.value == 0) return true;
    if (o is RenderSliverOpacity && o.opacity == 0) return true;
    if (o is RenderOffstage && o.offstage) return true;
  }
  return false;
}

bool _isInPhraseText(RenderParagraph p) {
  final creator = p.debugCreator;
  if (creator is! DebugCreator) return false;
  return creator.element.findAncestorWidgetOfExactType<PhraseText>() != null;
}

/// [PhraseText] が1語を入れるために字を縮めた所(縮めた語と倍率)。失敗にはせず、一覧に出す
List<String> findShrunkPhraseTexts(WidgetTester tester) {
  final found = <String>[];
  for (final e in find.byType(PhraseText).evaluate()) {
    final widget = e.widget as PhraseText;
    Text? text;
    void visit(Element child) {
      if (text != null) return;
      if (child.widget is Text) {
        text = child.widget as Text;
        return;
      }
      child.visitChildren(visit);
    }

    e.visitChildren(visit);
    final span = text?.textSpan;
    if (span is! TextSpan) continue;
    final base = DefaultTextStyle.of(e).style.merge(widget.style).fontSize ?? 14;
    for (final c in span.children ?? const <InlineSpan>[]) {
      final size = c.style?.fontSize;
      if (c is! TextSpan || size == null) continue;
      found.add('「${widget.data.replaceAll('\n', '⏎')}」の'
          '「${stripWordJoiners(c.text ?? '')}」 ×${(size / base).toStringAsFixed(2)}');
    }
  }
  return found;
}
