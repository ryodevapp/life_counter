import 'dart:io';
import 'package:budoux_dart/budoux.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_counter/l10n/l10n.dart';
import 'package:life_counter/l10n/phrase_break.dart';
import 'package:life_counter/views/shared/expandable_text.dart';

/// パッケージに入っている ja の model をファイルから読む(アセットの読み込みはテストでは使わない)
BudouX _loadModel() {
  final config =
      File('.dart_tool/package_config.json').readAsStringSync();
  final m = RegExp(r'"rootUri":\s*"([^"]*budoux_dart[^"]*)"').firstMatch(config)!;
  final root = Uri.parse(m.group(1)!);
  final dir = root.isAbsolute ? root.toFilePath() : '.dart_tool/${root.path}';
  return BudouX(File('$dir/lib/models/ja.json').readAsStringSync());
}

void main() {
  setUpAll(() => PhraseBreak.model = _loadModel());
  tearDownAll(() => PhraseBreak.model = null);

  /// 印を「|」でない形で見るため、文節の境(印の無い所)で分ける
  List<String> phrases(String shown) {
    final out = <String>[''];
    final chars = shown.characters.toList();
    for (var i = 0; i < chars.length; i++) {
      final c = chars[i];
      if (c == wordJoiner) continue;
      if (i > 0 && chars[i - 1] != wordJoiner && out.last.isNotEmpty) {
        out.add('');
      }
      out.last += c;
    }
    return out;
  }

  test('文節の中だけをつなぎ、文節の間は折れるまま', () {
    expect(phrases(PhraseBreak.apply('オーロラを見る')), ['オーロラを', '見る']);
    expect(phrases(PhraseBreak.apply('バケットリストに追加')),
        ['バケットリストに', '追加']);
  });

  test('印を外すと元の文に戻る', () {
    const s = '両親と温泉旅行に行く';
    expect(stripWordJoiners(PhraseBreak.apply(s)), s);
  });

  test('絵文字入りも文節で折り、絵文字の途中には印を入れない', () {
    for (final s in ['富士山に登る🗻', '家族で温泉に行く❤️', '👨‍👩‍👧と旅行する', 'がか゚き']) {
      final shown = PhraseBreak.apply(s);
      expect(stripWordJoiners(shown), s);
      // 字(書記素)の数は変わらない = どの字も割れていない
      expect(shown.characters.where((c) => c != wordJoiner).toList(),
          s.characters.toList());
    }
    expect(phrases(PhraseBreak.apply('富士山に登る🗻')), ['富士山に', '登る🗻']);
  });

  test('英語・model なしはそのまま', () {
    expect(PhraseBreak.apply('See the northern lights'),
        'See the northern lights');
    PhraseBreak.model = null;
    expect(PhraseBreak.apply('オーロラを見る'), 'オーロラを見る');
    PhraseBreak.model = _loadModel();
  });

  test('改行と空白は残し、空白の前後はつながない', () {
    final shown = PhraseBreak.apply('家族で 温泉\n行く');
    expect(stripWordJoiners(shown), '家族で 温泉\n行く');
    expect(shown.contains('$wordJoiner '), isFalse);
    expect(shown.contains(' $wordJoiner'), isFalse);
  });

  test('同じ文は覚えた結果を返し、覚える件数には上限がある', () {
    PhraseBreak.model = _loadModel(); // 覚えたものを空にする
    final first = PhraseBreak.apply('両親と温泉旅行に行く');
    expect(PhraseBreak.cachedCount, 1);
    expect(identical(PhraseBreak.apply('両親と温泉旅行に行く'), first), isTrue);
    for (var i = 0; i < PhraseBreak.cacheSize + 10; i++) {
      PhraseBreak.apply('今日は$i回目の散歩に行った');
    }
    expect(PhraseBreak.cachedCount, PhraseBreak.cacheSize);
  });

  test('長い本文(40字より長い)は文節で折らず、OS の標準の折りに任せる', () {
    const long = '今日は朝から雨が降っていたけれど、午後には晴れて、近所の公園まで歩いた。帰りにパン屋に寄った。';
    expect(long.length, greaterThan(PhraseBreak.maxLength));
    expect(PhraseBreak.apply(long), long);
    expect(PhraseBreak.fit(long, 10, (s) => 1000).single.text, long);
  });

  test('短い文の一覧でも重くない(40字の文 300件を2回)', () {
    PhraseBreak.model = _loadModel();
    final items = List.generate(
        300, (i) => '今日は$i番目の日。朝から雨が降っていたけれど、午後には晴れた。');
    final sw = Stopwatch()..start();
    items.forEach(PhraseBreak.apply);
    final firstMs = sw.elapsedMilliseconds;
    sw.reset();
    items.forEach(PhraseBreak.apply);
    final againMs = sw.elapsedMilliseconds;
    // ignore: avoid_print
    print('PhraseBreak 300件: 初回 ${firstMs}ms / 2回目 ${againMs}ms');
    expect(againMs, lessThanOrEqualTo(firstMs));
    expect(againMs, lessThan(20));
  });

  test('1文節が1行に入らないときの語の切れ目(カタカナの複合語・数字と単位・かっこ)', () {
    expect(PhraseBreak.words('バケットリストに'), ['バケット', 'リスト', 'に']);
    expect(PhraseBreak.words('プライバシーポリシー'), ['プライバシー', 'ポリシー']);
    expect(PhraseBreak.words('フィードバックを'), ['フィード', 'バック', 'を']);
    expect(PhraseBreak.words('10月20日（火）'), ['10月', '20日', '（火）']);
    expect(PhraseBreak.words('2026年10月23日に'), ['2026年', '10月', '23日に']);
    // 複合動詞は送りがなの後で分ける(1文節が入らないときだけ)
    expect(PhraseBreak.words('記録を書き出す'), ['記録を', '書き', '出す']);
    // 大きな見出し: 送りがなの後の助動詞の前で分ける。ひらがなだけの語は分けない
    expect(PhraseBreak.words('生まれましたか？'), ['生まれ', 'ましたか？']);
    expect(PhraseBreak.words('過ごしていきますか。'), ['過ごして', 'いき', 'ますか。']);
    expect(PhraseBreak.words('ひとことでも'), ['ひとことでも']);
    expect(PhraseBreak.words('大丈夫です。'), ['大丈夫です。']);
  });

  test('fit は入らない文節だけを語の切れ目で折れるようにし、入らない語を切れ端に分ける', () {
    // 1字 = 10 の幅とする
    double measure(String s) => s.characters.length * 10.0;
    String shown(List<PhraseFitPiece> ps) => ps.map((p) => p.text).join();
    final wide = PhraseBreak.fit('バケットリストに追加', 60, measure);
    expect(stripWordJoiners(shown(wide)), 'バケットリストに追加');
    // 「バケットリストに」(8字)は入らないので語に分ける。「追加」は文節のまま
    expect(phrases(shown(wide)), ['バケット', 'リスト', 'に', '追加']);
    expect(wide.every((p) => p.width == 0), isTrue);
    final narrow = PhraseBreak.fit('バケットリストに追加', 30, measure);
    // 「バケット」(4字)だけが入らない
    expect([for (final p in narrow) if (p.width > 0) stripWordJoiners(p.text)],
        ['バケット']);
    expect(narrow.firstWhere((p) => p.width > 0).width, 40);
    expect(stripWordJoiners(shown(narrow)), 'バケットリストに追加');
    final fits = PhraseBreak.fit('バケットリストに追加', 200, measure);
    expect(shown(fits), PhraseBreak.apply('バケットリストに追加'));
  });

  testWidgets('PhraseText は入らない1語だけを縮める(下限 0.85 倍)。読み上げは元の文',
      (tester) async {
    final handle = tester.ensureSemantics();
    Future<Text> pumpAt(double width, double scale) async {
      await tester.pumpWidget(MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(scale)),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: SizedBox(
                width: width,
                child: const PhraseText('バケットリストに追加',
                    style: TextStyle(fontSize: 10))),
          ),
        ),
      ));
      return tester.widget<Text>(find.byType(Text));
    }

    // 1字 10pt × 3倍 = 30pt。「バケット」は 120pt。幅 110 では「バケット」だけ縮める
    final shrunk = await pumpAt(110, 3);
    final spans = (shrunk.textSpan! as TextSpan).children!.cast<TextSpan>();
    final small = spans.where((s) => s.style?.fontSize != null).toList();
    expect(small.map((s) => stripWordJoiners(s.text!)), ['バケット']);
    expect(small.single.style!.fontSize, lessThan(10));
    expect(small.single.style!.fontSize, greaterThanOrEqualTo(8.5));
    expect(find.bySemanticsLabel('バケットリストに追加'), findsOneWidget);
    // 幅が足りれば縮めない
    final roomy = await pumpAt(1000, 3);
    expect(roomy.textSpan, isNull);
    handle.dispose();
  });

  testWidgets('PhraseText の読み上げは元の文', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(const Directionality(
        textDirection: TextDirection.ltr, child: PhraseText('オーロラを見る')));
    expect(find.bySemanticsLabel('オーロラを見る'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('入力欄の案内と ExpandableText も、画面は印入り・読み上げは元の文', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('ja'),
      home: Scaffold(
        body: Column(children: [
          const TextField(
              decoration: InputDecoration(hint: PhraseText('バケットリストに追加'))),
          ExpandableText('家族で温泉に行く', style: const TextStyle()),
        ]),
      ),
    ));
    await tester.pump();
    final shownTexts = tester
        .widgetList<Text>(find.byType(Text))
        .map((t) => t.data ?? '')
        .toList();
    expect(shownTexts, contains(PhraseBreak.apply('バケットリストに追加')));
    expect(shownTexts, contains(PhraseBreak.apply('家族で温泉に行く')));
    expect(find.bySemanticsLabel(RegExp('バケットリストに追加')), findsWidgets);
    expect(find.bySemanticsLabel('家族で温泉に行く'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp(wordJoiner)), findsNothing);
    handle.dispose();
  });
}
