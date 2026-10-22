import 'dart:io';
import 'package:budoux_dart/budoux.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_counter/l10n/l10n.dart';
import 'package:life_counter/l10n/phrase_break.dart';

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
    for (var i = 0; i < shown.length; i++) {
      final c = shown[i];
      if (c == wordJoiner) continue;
      if (i > 0 && shown[i - 1] != wordJoiner && out.last.isNotEmpty) {
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

  test('英語・絵文字入り・model なしはそのまま', () {
    expect(PhraseBreak.apply('See the northern lights'),
        'See the northern lights');
    expect(PhraseBreak.apply('富士山に登る🗻'), '富士山に登る🗻');
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

  testWidgets('PhraseText の読み上げは元の文', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(const Directionality(
        textDirection: TextDirection.ltr, child: PhraseText('オーロラを見る')));
    expect(find.bySemanticsLabel('オーロラを見る'), findsOneWidget);
    handle.dispose();
  });
}
