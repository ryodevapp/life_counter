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
/// 画面に出す文字だけに使う。読み上げは元の文にする([PhraseText])。保存・書き出しには使わない
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
  static set model(BudouX? m) => _ja = m;

  static final _japanese = RegExp(r'[぀-ヿ㐀-鿿]');
  static final _surrogate = RegExp(r'[\ud800-\udfff]');
  static final _space = RegExp(r'\s');

  /// 文節の中の字の間に [wordJoiner] を入れた文を返す。
  /// 日本語を含まない文、絵文字など(UTF-16 の2単位の字)を含む文、model が無いときは、そのまま返す
  static String apply(String text) {
    final model = _ja;
    if (model == null ||
        !_japanese.hasMatch(text) ||
        _surrogate.hasMatch(text)) {
      return text;
    }
    final plain = stripWordJoiners(text);
    return plain.split('\n').map((line) {
      if (line.isEmpty) return line;
      return model.parse(line).map(_joinPhrase).join();
    }).join('\n');
  }

  /// 文節の中の字をつなぐ。空白の前後にはつながず、空白で折れるのを残す
  static String _joinPhrase(String phrase) {
    final b = StringBuffer();
    for (var i = 0; i < phrase.length; i++) {
      final c = phrase[i];
      if (i > 0 && !_space.hasMatch(c) && !_space.hasMatch(phrase[i - 1])) {
        b.write(wordJoiner);
      }
      b.write(c);
    }
    return b.toString();
  }
}

/// [Text] と同じだが、日本語を文節の途中で折らない([PhraseBreak.apply])。
/// 読み上げ(semanticsLabel)は元の文のまま
class PhraseText extends StatelessWidget {
  const PhraseText(this.data, {super.key, this.style, this.textAlign});

  final String data;
  final TextStyle? style;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    final shown = PhraseBreak.apply(data);
    return Text(
      shown,
      style: style,
      textAlign: textAlign,
      semanticsLabel: shown == data ? null : stripWordJoiners(data),
    );
  }
}
