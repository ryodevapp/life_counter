import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 今日タブを開き直したことを伝える(ほかの画面で直した答えを読み直すため)
final todayReloadProvider = StateProvider<int>((ref) => 0);

/// 答えの欄にキーボードを出してほしいことを伝える(ウィジェットの「書く」から開いたとき)
final answerFocusRequestProvider = StateProvider<int>((ref) => 0);
