import 'package:budoux_dart/budoux.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'l10n.dart';

/// 日本語の文を文節(BudouX)ごとにまとめ、文節の途中で行を折らせない(LC 日本語の改行。1.1.4)。
///
/// Flutter の文字の組版(ICU の行区切り)は、かなと漢字の間ならどこでも折る。iOS の版には関係しない
/// (OS の Text の語単位の改行は、Flutter が自分で描く文字には効かない)。
/// 折ってよい所を足す U+200B では、今ある折れ目は減らないので、文節の中の字の間に
/// [wordJoiner](U+2060)を入れて折れ目を消す。文節と文節の間は今までどおり折れる。
///
/// 1つの文節が1行に入らないとき(最大の文字の「バケットリストに追加」など)は、語の途中で折らない
/// (10/23 本人「変なところで折り返さないで欲しい」)。[PhraseText] が幅を見て次の順で扱う:
/// 1. その文節だけ、文節の中の語の切れ目で折る([words]。カタカナの複合語は [compounds] で分ける)
/// 2. それでも1行に入らない語があれば、その語だけ入る大きさまで縮める。下限は今の 0.85 倍かつ 11pt
///
/// 当てるのは短い文言(ボタン・案内・見出し・やりたいことの項目など)だけ。[maxLength] より長い本文は
/// OS の標準の折りに任せる(decisions 2026-10-23 夕方)
///
/// 画面に出す文字だけに使う。読み上げは元の文にする([PhraseText])。保存・書き出しには使わない。
/// 利用者の書いた文(やりたいことの項目・今日の答え・記録の一覧)にも使う。表示のたびに分け直さないよう、
/// 分けた結果を新しい順に [cacheSize] 件まで覚えておく
class PhraseBreak {
  PhraseBreak._();

  static BudouX? _ja;

  static const _modelAsset = 'packages/budoux_dart/models/ja.json';

  /// 起動のときに1回読む。読めなければ何もしない(今までどおりの折れ方になるだけ)
  static Future<void> load() async {
    try {
      _ja = BudouX(await rootBundle.loadString(_modelAsset));
    } catch (e) {
      debugPrint('PhraseBreak load error: $e');
    }
  }

  /// テストで model を入れる・外す
  @visibleForTesting
  static set model(BudouX? m) {
    _ja = m;
    _cache.clear();
  }

  /// 文節で折る文の長さの上限(字)。これより長い本文(記録の答えなど)は OS の標準の折りに任せる
  /// (行末に空きが出るのを避ける。decisions 2026-10-23 夕方)。既定の文字の本文で2行に入る長さ
  static const maxLength = 40;

  /// 1語が入らないときに縮める下限(今の大きさに対する割合と、字の大きさの下限)
  static const minShrink = 0.85;
  static const minFontSize = 11.0;

  /// 文節で折る文か(日本語を含み、[maxLength] 字以下)
  static bool appliesTo(String text) =>
      _japanese.hasMatch(text) &&
      stripWordJoiners(text).characters.length <= maxLength;

  /// 覚えておく件数。記録の一覧(1か月で答えと振り返りが数十件)とやりたいことの項目が入る大きさ
  static const cacheSize = 512;

  /// 元の文 → 折らせないまとまり(文節。改行と空白は1つのまとまり)。挿入の順を使い、古いものから捨てる
  static final _cache = <String, ({List<String> segments, String shown})>{};

  /// テストで覚えている件数を見る
  @visibleForTesting
  static int get cachedCount => _cache.length;

  static final _japanese = RegExp(r'[぀-ヿ㐀-鿿]');
  static final _space = RegExp(r'\s');

  /// カタカナの複合語の分け方(1文節が1行に入らないときだけ使う)。arb の文言にあるもの
  static const compounds = {
    'バケットリスト': ['バケット', 'リスト'],
    'プライバシーポリシー': ['プライバシー', 'ポリシー'],
    'フィードバック': ['フィード', 'バック'],
  };

  /// 文節の中の字の間に [wordJoiner] を入れた文を返す。
  /// 日本語を含まない文、[maxLength] より長い文、model が無いときは、そのまま返す
  static String apply(String text) {
    return _entryOf(text)?.shown ?? text;
  }

  /// 幅 [maxWidth] に合わせた表示の文。文節が1行に入らないものだけ語の切れ目で折れるようにする。
  /// 返すのは表示の文の切れ端の並び。1行に入らない語は1つの切れ端にし、[PhraseFitPiece.width] にその幅を入れる
  /// (それ以外は 0。[measure] は1行で組んだ幅)
  static List<PhraseFitPiece> fit(
      String text, double maxWidth, double Function(String) measure) {
    final segments = _segmentsOf(text);
    if (segments == null) return [PhraseFitPiece(text, 0)];
    final out = <PhraseFitPiece>[];
    final b = StringBuffer();
    for (final s in segments) {
      if (s.length < 2 || measure(s) <= maxWidth) {
        b.write(_join(s));
        continue;
      }
      for (final w in words(s)) {
        final width = w.length > 1 ? measure(w) : 0.0;
        if (width <= maxWidth) {
          b.write(_join(w));
          continue;
        }
        if (b.isNotEmpty) out.add(PhraseFitPiece(b.toString(), 0));
        b.clear();
        out.add(PhraseFitPiece(_join(w), width));
      }
    }
    if (b.isNotEmpty) out.add(PhraseFitPiece(b.toString(), 0));
    return out;
  }

  /// 文節の切れ目(字の位置。UTF-16 の位置で、0 と末尾は含めない)。
  /// 撮影で「文節の途中で折れた所」を探すのに使う。model が無ければ null
  @visibleForTesting
  static Set<int>? phraseBoundaries(String text) {
    final segments = _segmentsOf(text);
    if (segments == null) return null;
    final result = <int>{};
    var pos = 0;
    for (final s in segments) {
      if (pos > 0) result.add(pos);
      pos += s.length;
    }
    return result;
  }

  /// 文節の中の語の切れ目も足した切れ目([phraseBoundaries] より多い)
  @visibleForTesting
  static Set<int>? wordBoundaries(String text) {
    final segments = _segmentsOf(text);
    if (segments == null) return null;
    final result = <int>{};
    var pos = 0;
    for (final s in segments) {
      for (final w in words(s)) {
        if (pos > 0) result.add(pos);
        pos += w.length;
      }
    }
    return result;
  }

  static String _join(String s) =>
      s.length < 2 ? s : s.characters.join(wordJoiner);

  static List<String>? _segmentsOf(String text) => _entryOf(text)?.segments;

  static ({List<String> segments, String shown})? _entryOf(String text) {
    final model = _ja;
    if (model == null || !appliesTo(text)) return null;
    final hit = _cache.remove(text);
    if (hit != null) {
      _cache[text] = hit; // 新しい側へ移す
      return hit;
    }
    final segments = _split(model, stripWordJoiners(text));
    final entry = (segments: segments, shown: segments.map(_join).join());
    _cache[text] = entry;
    if (_cache.length > cacheSize) _cache.remove(_cache.keys.first);
    return entry;
  }

  /// 字(書記素のまとまり)ごとに分ける。BudouX は UTF-16 の1単位を1字として数えるので、
  /// 2単位以上の字(絵文字・異体字セレクタ付き・濁点の結合など)は1単位の代わりの字(U+FFFC)にして渡し、
  /// 字の途中で分けない(分けると絵文字が割れる)。
  /// 改行と空白はそれだけで1つのまとまりにし、空白で折れるのを残す
  static List<String> _split(BudouX model, String plain) {
    final out = <String>[];
    final lines = plain.split('\n');
    for (var n = 0; n < lines.length; n++) {
      if (n > 0) out.add('\n');
      final line = lines[n];
      if (line.isEmpty) continue;
      final chars = line.characters.toList();
      final proxy = chars.map((c) => c.length == 1 ? c : '￼').join();
      final current = StringBuffer();
      void flush() {
        if (current.isNotEmpty) out.add(current.toString());
        current.clear();
      }

      var i = 0;
      for (final phrase in model.parse(proxy)) {
        for (var j = 0; j < phrase.length; j++, i++) {
          final c = chars[i];
          if (_space.hasMatch(c)) {
            flush();
            out.add(c);
            continue;
          }
          // 絵文字は前の文節に付ける(行の頭に絵文字だけが落ちないように)
          final glue = j > 0 || (i > 0 && c.length > 1 && !_japanese.hasMatch(c));
          if (!glue) flush();
          current.write(c);
        }
      }
      flush();
    }
    return out;
  }

  /// 文節を語に分ける(1文節が1行に入らないときだけ使う)。
  /// - カタカナとそれ以外の間、ひらがなの後の漢字の前、英数字と日本語の間で分ける
  /// - 漢字の後の送りがな・助詞(「追加する」の「する」)、数字の後の漢字(「10月」)は分けない
  /// - 開きかっこは後ろに、閉じかっこ・句読点は前に付ける(「20日」「（火）」)
  /// - カタカナの複合語は [compounds] で分ける
  @visibleForTesting
  static List<String> words(String phrase) {
    final chars = phrase.characters.toList();
    final out = <String>[];
    final current = StringBuffer();
    _Kind? prev;
    var prevOpen = false;
    for (final c in chars) {
      final k = _kindOf(c);
      var cut = current.isNotEmpty && !prevOpen && k != _Kind.close;
      if (cut && prev != null) {
        cut = switch ((prev, k)) {
          (_Kind.open, _) => false,
          (_, _Kind.open) => true,
          (_Kind.close, _) => true,
          (_Kind.kata, _Kind.kata) => false,
          (_Kind.kata, _) || (_, _Kind.kata) => true,
          (_Kind.hira, _Kind.kanji) => true,
          (_Kind.alnum, _Kind.kanji) => false,
          (_Kind.alnum, _Kind.alnum) => false,
          (_Kind.alnum, _) || (_, _Kind.alnum) => true,
          _ => false,
        };
      }
      if (cut) {
        out.add(current.toString());
        current.clear();
      }
      current.write(c);
      prev = k;
      prevOpen = k == _Kind.open;
    }
    if (current.isNotEmpty) out.add(current.toString());
    return [
      for (final w in out)
        for (final c in _splitCompound(w)) ..._splitAuxiliary(c)
    ];
  }

  /// 漢字で始まる語の送りがなの後ろの助動詞の前で分ける(大きな見出しの「生まれ/ましたか？」「過ごして/いきますか。」)。
  /// 「て」の後と「ます・ました・ません」の前だけ。ひらがなだけの語(「ひとことでも」)は分けない
  static final _auxiliary = RegExp(r'(?<=[ぁ-ゖ]て)(?=[ぁ-ゖ]{2})|(?<=[㐀-鿿々][ぁ-ゖ]*)(?=ま[すしせ])');

  static List<String> _splitAuxiliary(String word) {
    if (!_kanjiStart.hasMatch(word)) return [word];
    final out = <String>[];
    var from = 0;
    for (final m in _auxiliary.allMatches(word)) {
      if (m.start <= from) continue;
      out.add(word.substring(from, m.start));
      from = m.start;
    }
    out.add(word.substring(from));
    return out;
  }

  static final _kanjiStart = RegExp(r'^[㐀-鿿々]');

  static List<String> _splitCompound(String word) {
    for (final e in compounds.entries) {
      final at = word.indexOf(e.key);
      if (at < 0) continue;
      return [
        if (at > 0) word.substring(0, at),
        ...e.value,
        if (at + e.key.length < word.length) word.substring(at + e.key.length),
      ];
    }
    return [word];
  }

  static final _kata = RegExp(r'^[ァ-ヺー・]$');
  static final _hira = RegExp(r'^[ぁ-ゖゝゞ]$');
  static final _kanji = RegExp(r'^[㐀-鿿々〆]$');
  static final _alnum = RegExp(r'^[0-9A-Za-z０-９Ａ-Ｚａ-ｚ]$');
  static final _open = RegExp(r'^[（(「『【〈《〔［\[“‘]$');

  static _Kind _kindOf(String c) {
    if (_kata.hasMatch(c)) return _Kind.kata;
    if (_hira.hasMatch(c)) return _Kind.hira;
    if (_kanji.hasMatch(c)) return _Kind.kanji;
    if (_alnum.hasMatch(c)) return _Kind.alnum;
    if (_open.hasMatch(c)) return _Kind.open;
    return _Kind.close; // 閉じかっこ・句読点・記号・絵文字は前に付ける
  }
}

enum _Kind { kata, hira, kanji, alnum, open, close }

/// [PhraseBreak.fit] の切れ端。[width] が 0 でなければ、1行に入らない語(その幅)
class PhraseFitPiece {
  const PhraseFitPiece(this.text, this.width);
  final String text;
  final double width;
}

/// [Text] と同じだが、日本語を文節の途中で折らない([PhraseBreak])。
/// 1文節が1行に入らないときは、その文節を語の切れ目で折り、それでも入らない語があれば、
/// その語だけ入る大きさまで縮める(下限は今の 0.85 倍かつ 11pt)。読み上げ(semanticsLabel)は元の文のまま。
///
/// 幅を見るのに [LayoutBuilder] を使うので、内在の大きさを測る親(IntrinsicWidth など)の中では使わない
class PhraseText extends StatelessWidget {
  const PhraseText(this.data,
      {super.key, this.style, this.textAlign, this.maxLines, this.overflow});

  final String data;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  @override
  Widget build(BuildContext context) {
    final semanticsLabel = stripWordJoiners(data);
    final simple = PhraseBreak.apply(data);
    if (simple == data) {
      return _text(simple, null);
    }
    return LayoutBuilder(builder: (context, constraints) {
      final maxWidth = constraints.maxWidth;
      if (!maxWidth.isFinite) return _text(simple, semanticsLabel);
      final effective = DefaultTextStyle.of(context).style.merge(style);
      final scaler = MediaQuery.textScalerOf(context);
      final direction = Directionality.of(context);
      double measure(String s, TextScaler sc) {
        final p = TextPainter(
          text: TextSpan(text: s, style: effective),
          textDirection: direction,
          textScaler: sc,
          maxLines: 1,
        )..layout();
        final w = p.width;
        p.dispose();
        return w;
      }

      // ほとんどの文は1行に入るか、どの文節も1行に入る。そのときは今までどおり
      if (measure(simple, scaler) <= maxWidth) {
        return _text(simple, semanticsLabel);
      }
      final pieces =
          PhraseBreak.fit(data, maxWidth, (s) => measure(s, scaler));
      if (pieces.every((p) => p.width == 0)) {
        return _text(pieces.map((p) => p.text).join(), semanticsLabel);
      }
      // 1行に入らない語がある: その語だけ、入る大きさまで縮める。
      // 下限は今の大きさの [PhraseBreak.minShrink] 倍かつ [PhraseBreak.minFontSize] pt(それでも入らなければ字の間で折れる)
      final fontSize = effective.fontSize ?? 14;
      final now = scaler.scale(fontSize);
      final floor = (now * PhraseBreak.minShrink)
          .clamp(PhraseBreak.minFontSize, now)
          .toDouble();
      return Text.rich(
        TextSpan(children: [
          for (final p in pieces)
            if (p.width == 0)
              TextSpan(text: p.text)
            else
              // 測った幅は字の大きさにほぼ比例する。丸めの分だけ少し余らせる
              TextSpan(
                text: p.text,
                style: TextStyle(
                    fontSize: fontSize *
                        (now * maxWidth / p.width * 0.98).clamp(floor, now) /
                        now),
              ),
        ]),
        style: style,
        textAlign: textAlign,
        maxLines: maxLines,
        overflow: overflow,
        semanticsLabel: semanticsLabel,
      );
    });
  }

  Widget _text(String shown, String? semanticsLabel) {
    return Text(
      shown,
      style: style,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
      semanticsLabel: shown == data ? null : semanticsLabel,
    );
  }
}
