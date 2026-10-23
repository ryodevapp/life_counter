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

  test('長い一覧でも重くない(200字の答え 300件を2回)', () {
    PhraseBreak.model = _loadModel();
    final answers = List.generate(300,
        (i) => '今日は$i番目の日。朝から雨が降っていたけれど、午後には晴れて、近所の公園まで歩いた。' * 4);
    final sw = Stopwatch()..start();
    answers.forEach(PhraseBreak.apply);
    final firstMs = sw.elapsedMilliseconds;
    sw.reset();
    answers.forEach(PhraseBreak.apply);
    final againMs = sw.elapsedMilliseconds;
    // ignore: avoid_print
    print('PhraseBreak 300件: 初回 ${firstMs}ms / 2回目 ${againMs}ms');
    expect(againMs, lessThan(firstMs));
    expect(againMs, lessThan(20));
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
