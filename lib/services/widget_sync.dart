import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import '../models/important_person.dart';
import '../models/meeting_log.dart';
import 'contact_stats.dart';

/// ホーム画面・ロック画面のウィジェットに、表示する値を渡す（App Group 経由）
///
/// 次に会う日(FamilyWidget): いちばん近い予定の人と日付。Pro なら写真も
/// 思い出(MemoryWidget, Pro): 写真つきの「会えた日の記録」
class WidgetSync {
  WidgetSync._();

  static const appGroup = 'group.com.lifecounter.lifeCounter';
  static const _kinds = ['FamilyWidget', 'MemoryWidget'];
  static bool _ready = false;

  static Future<void> update({
    required List<ImportantPerson> persons,
    required List<MeetingLog> logs,
    required bool isPro,
  }) async {
    try {
      if (!_ready) {
        await HomeWidget.setAppGroupId(appGroup);
        _ready = true;
      }
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final names = {for (final p in persons) p.id: p.nickname};

      final upcoming = persons
          .where((p) => p.nextMeetDate != null && !p.nextMeetDate!.isBefore(today))
          .toList()
        ..sort((a, b) => a.nextMeetDate!.compareTo(b.nextMeetDate!));
      final next = upcoming.isEmpty ? null : upcoming.first;

      // 写真つきの記録(新しい順、最大60件)
      final memories = logs
          .where((l) => l.photoFile != null && names.containsKey(l.personId))
          .take(60)
          .map((l) => {
                'f': l.photoFile,
                'y': l.date.year,
                'm': l.date.month,
                'd': l.date.day,
                'n': names[l.personId],
                't': l.note ?? '',
              })
          .toList();

      await HomeWidget.saveWidgetData<bool>('isPro', isPro);
      await HomeWidget.saveWidgetData<bool>('hasFamily', persons.isNotEmpty);
      await HomeWidget.saveWidgetData<int>('yearCount', ContactStats.familyMetThisYear(logs));
      await HomeWidget.saveWidgetData<int>(
          'monthConnected', ContactStats.familyConnectedThisMonth(logs));
      await HomeWidget.saveWidgetData<double>(
          'nextMeetEpoch', next == null ? null : next.nextMeetDate!.millisecondsSinceEpoch / 1000);
      await HomeWidget.saveWidgetData<String>('nextMeetName', next?.nickname);
      await HomeWidget.saveWidgetData<String>('nextMeetPhoto', next?.photoFile);
      // 未購入でも「写真を付けている」ことは渡す(ウィジェットで「写真つきは Pro」と伝えるため)
      await HomeWidget.saveWidgetData<bool>('nextMeetHasPhoto', next?.photoFile != null);
      await HomeWidget.saveWidgetData<String>('memories', jsonEncode(memories));
      for (final k in _kinds) {
        await HomeWidget.updateWidget(iOSName: k);
      }
    } catch (e) {
      debugPrint('Widget sync error: $e');
    }
  }
}
