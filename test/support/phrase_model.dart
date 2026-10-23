import 'dart:io';

import 'package:budoux_dart/budoux.dart';

/// パッケージに入っている ja の model をファイルから読む(アセットの読み込みはテストでは使わない)
BudouX loadPhraseModel() {
  final config = File('.dart_tool/package_config.json').readAsStringSync();
  final m =
      RegExp(r'"rootUri":\s*"([^"]*budoux_dart[^"]*)"').firstMatch(config)!;
  final root = Uri.parse(m.group(1)!);
  final dir = root.isAbsolute ? root.toFilePath() : '.dart_tool/${root.path}';
  return BudouX(File('$dir/lib/models/ja.json').readAsStringSync());
}
