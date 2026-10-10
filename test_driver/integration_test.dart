import 'dart:io';
import 'package:integration_test/integration_test_driver_extended.dart';

/// 画面写真を SCREENS_DIR(なければ build/screens)に保存する
Future<void> main() => integrationDriver(
      onScreenshot: (name, bytes, [args]) async {
        final dir = Platform.environment['SCREENS_DIR'] ?? 'build/screens';
        final file = File('$dir/$name.png');
        await file.create(recursive: true);
        await file.writeAsBytes(bytes);
        return true;
      },
    );
