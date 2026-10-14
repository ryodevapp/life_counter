import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 今日タブを開き直したことを伝える(ほかの画面で直した答えを読み直すため)
final todayReloadProvider = StateProvider<int>((ref) => 0);
