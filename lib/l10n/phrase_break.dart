import 'package:budoux_dart/budoux.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'l10n.dart';

/// 日本語の文を文節(BudouX)ごとにまとめ、文節の途中で行を折らせない(試作。LC 日本語の改行)。
///
/// Flutter の文字の組版(ICU の行区切り)は、かなと漢字の間ならどこでも折る。iOS の版には関係しない
/// (OS の Text の語単位の改行は、Flutter が自分で描く文字には効かない)。
/// 折ってよい所を足す U+200B では、今ある折れ目は減らないので、文節の中の字の間に
/// [wordJoiner](U+2060)を入れて折れ目を消す。文節と文節の間は今までどおり折れる。
/// 1つの文節が1行に入らないときは、組版が字の途中で折る(文字は切れない)。
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

  /// 覚えておく件数。記録の一覧(1か月で答えと振り返りが数十件)とやりたいことの項目が入る大きさ
  static const cacheSize = 512;

  /// 元の文 → 印を入れた文。挿入の順を使い、古いものから捨てる
  static final _cache = <String, String>{};

  /// テストで覚えている件数を見る
  @visibleForTesting
  static int get cachedCount => _cache.length;

  static final _japanese = RegExp(r'[぀-ヿ㐀-鿿]');
  static final _space = RegExp(r'\s');

  /// 文節の中の字の間に [wordJoiner] を入れた文を返す。
  /// 日本語を含まない文、model が無いときは、そのまま返す
  static String apply(String text) {
    final model = _ja;
    if (model == null || !_japanese.hasMatch(text)) return text;
    final hit = _cache.remove(text);
    if (hit != null) {
      _cache[text] = hit; // 新しい側へ移す
      return hit;
    }
    final shown = _split(model, stripWordJoiners(text));
    _cache[text] = shown;
    if (_cache.length > cacheSize) _cache.remove(_cache.keys.first);
    return shown;
  }

  /// 字(書記素のまとまり)ごとに分ける。BudouX は UTF-16 の1単位を1字として数えるので、
  /// 2単位以上の字(絵文字・異体字セレクタ付き・濁点の結合など)は1単位の代わりの字(U+FFFC)にして渡し、
  /// 字の途中に印を入れない(入れると絵文字が割れる)。
  /// 文節の中の字をつなぐ。空白の前後にはつながず、空白で折れるのを残す
  static String _split(BudouX model, String plain) {
    return plain.split('\n').map((line) {
      if (line.isEmpty) return line;
      final chars = line.characters.toList();
      final proxy = chars.map((c) => c.length == 1 ? c : '\uFFFC').join();
      final b = StringBuffer();
      var i = 0;
      for (final phrase in model.parse(proxy)) {
        for (var j = 0; j < phrase.length; j++, i++) {
          final c = chars[i];
          // 絵文字は前の文節に付ける(行の頭に絵文字だけが落ちないように)
          final glue = j > 0 || (i > 0 && c.length > 1 && !_japanese.hasMatch(c));
          if (glue && !_space.hasMatch(c) && !_space.hasMatch(chars[i - 1])) {
            b.write(wordJoiner);
          }
          b.write(c);
        }
      }
      return b.toString();
    }).join('\n');
  }
}

/// [Text] と同じだが、日本語を文節の途中で折らない([PhraseBreak.apply])。
/// 読み上げ(semanticsLabel)は元の文のまま
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
    final shown = PhraseBreak.apply(data);
    return Text(
      shown,
      style: style,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
      semanticsLabel: shown == data ? null : stripWordJoiners(data),
    );
  }
}
