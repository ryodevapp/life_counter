import 'dart:io';
import 'package:integration_test/integration_test_driver_extended.dart';

/// 画面写真を build/screens/ に保存する
Future<void> main() => integrationDriver(
      onScreenshot: (name, bytes, [args]) async {
        final file = File('build/screens/$name.png');
        await file.create(recursive: true);
        await file.writeAsBytes(bytes);
        return true;
      },
    );
