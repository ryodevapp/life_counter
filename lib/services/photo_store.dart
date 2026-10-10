import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path_provider_foundation/path_provider_foundation.dart';
import 'widget_sync.dart';

/// 家族と記録の写真。ウィジェットからも読めるよう、App Group の中に置く。
/// 端末の外には送らない
class PhotoStore {
  PhotoStore._();

  static Directory? _dir;

  /// 起動時に一度だけ呼ぶ（App Group が使えなければ、アプリの書類フォルダに置く）
  static Future<void> init() async {
    try {
      String? base;
      if (Platform.isIOS) {
        base = await PathProviderFoundation()
            .getContainerPath(appGroupIdentifier: WidgetSync.appGroup);
      }
      base ??= (await getApplicationDocumentsDirectory()).path;
      final dir = Directory('$base/photos');
      if (!await dir.exists()) await dir.create(recursive: true);
      _dir = dir;
    } catch (e) {
      debugPrint('PhotoStore init error: $e');
    }
  }

  static File? file(String? name) {
    if (name == null || _dir == null) return null;
    final f = File('${_dir!.path}/$name');
    return f.existsSync() ? f : null;
  }

  /// 写真を選んで保存し、ファイル名を返す（選ばなければ null）
  static Future<String?> pick() async {
    if (_dir == null) await init();
    if (_dir == null) return null;
    final x = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 82,
    );
    if (x == null) return null;
    final name = 'p${DateTime.now().microsecondsSinceEpoch}.jpg';
    await File(x.path).copy('${_dir!.path}/$name');
    return name;
  }
}
