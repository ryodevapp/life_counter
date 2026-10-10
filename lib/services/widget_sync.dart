import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import '../models/important_person.dart';
import '../models/meeting_log.dart';

/// ホーム画面のウィジェットに、表示する値を渡す（App Group 経由）
class WidgetSync {
  WidgetSync._();

  static const appGroup = 'group.com.lifecounter.lifeCounter';
  static const _widgetName = 'FamilyWidget';
  static bool _ready = false;

  /// ウィジェットの見た目（warm は無料。night / sakura / sea は Pro）
  static const styles = {
    'warm': 'あたたかい(標準)',
    'night': '夜',
    'sakura': 'さくら',
    'sea': '海',
  };

  static Future<void> update({
    required List<ImportantPerson> persons,
    required List<MeetingLog> logs,
    required String style,
  }) async {
    try {
      if (!_ready) {
        await HomeWidget.setAppGroupId(appGroup);
        _ready = true;
      }
      final year = DateTime.now().year;
      final today = DateTime.now();
      final todayStart = DateTime(today.year, today.month, today.day);

      // いちばん近い「次に会う日」
      final upcoming = persons
          .where((p) => p.nextMeetDate != null && !p.nextMeetDate!.isBefore(todayStart))
          .toList()
        ..sort((a, b) => a.nextMeetDate!.compareTo(b.nextMeetDate!));
      final metThisYear = logs.where((l) => l.date.year == year).length;

      String label, value, unit;
      if (upcoming.isNotEmpty) {
        final p = upcoming.first;
        label = '${p.nickname}に会えるまで、あと';
        value = '${p.nextMeetDate!.difference(todayStart).inDays}';
        unit = '日';
        await HomeWidget.saveWidgetData<double>('nextMeetEpoch',
            p.nextMeetDate!.millisecondsSinceEpoch / 1000);
        await HomeWidget.saveWidgetData<String>('nextMeetName', p.nickname);
      } else {
        await HomeWidget.saveWidgetData<double>('nextMeetEpoch', null);
        await HomeWidget.saveWidgetData<String>('nextMeetName', null);
        if (persons.isEmpty) {
          label = '家族を登録すると、ここに表示されます';
          value = '';
          unit = '';
        } else {
          label = '今年、家族と会えた日';
          value = '$metThisYear';
          unit = '日';
        }
      }
      await HomeWidget.saveWidgetData<String>('label', label);
      await HomeWidget.saveWidgetData<String>('value', value);
      await HomeWidget.saveWidgetData<String>('unit', unit);
      await HomeWidget.saveWidgetData<String>(
          'sub', upcoming.isNotEmpty && persons.isNotEmpty ? '今年会えた日 $metThisYear日' : '');
      await HomeWidget.saveWidgetData<String>('style', style);
      await HomeWidget.updateWidget(iOSName: _widgetName);
    } catch (e) {
      debugPrint('Widget sync error: $e');
    }
  }
}
