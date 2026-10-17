import 'package:isar/isar.dart';
import '../utils/day_key.dart';

part 'daily_record.g.dart';

@collection
class DailyRecord {
  Id id = Isar.autoIncrement;

  /// 記録の日(「yyyy-MM-dd」)。日付の検索はすべてこれで行う(v1.1.1)
  /// 古い記録は起動時の移行で埋める(lib/services/day_key_migration.dart)。
  /// 文字の大小で月の範囲を取れるよう、ハッシュではなく値の索引にする。
  ///
  /// 一意の索引にはしない: Isar 3 は、既にある記録(この欄が空)に一意の索引を足すと
  /// 開くときに「Unique index violated」で失敗する(古いデータベースで確かめた)。
  /// 1日1件は、作るのを1回の書き込みの中で確かめることと、移行でのまとめで守る
  @Index(type: IndexType.value)
  String dayKey = '';

  /// 互換のために残す。その日の 0:00(作ったときの地域の時刻)。日付の判定には使わない
  /// 一意の索引は外した(別の地域で作った別の日の 0:00 が同じ時刻になることがあるため)
  @Index()
  late DateTime date;

  String? todayGoal;

  String? reflectionGood;
  String? reflectionWhy;
  String? reflectionTomorrow;

  String? weeklyReflectionHighlight;
  String? weeklyReflectionChange;

  String? morningQuestionId;
  String? greatPersonId;

  // v1.0.1 新規フィールド
  String? gratitude;        // 「今 感謝していることはある？」
  String? tomorrowMessage;  // 「明日の自分に一言伝えるなら？」

  // v1.1.0 新規フィールド(今日の問いへの答え。問いの id は morningQuestionId)
  String? stamp;   // スタンプの id(lib/models/stamp.dart)
  String? answer;  // 話す・書く欄の文
  DateTime? stampAt; // スタンプを押した(取り消した)時刻。ウィジェットとアプリの後勝ちに使う

  DateTime createdAt = DateTime.now();
  DateTime updatedAt = DateTime.now();
}

/// [day] の日の新しい記録
DailyRecord newDailyRecordFor(DateTime day) {
  final d = DateTime(day.year, day.month, day.day);
  return DailyRecord()
    ..dayKey = dayKeyOf(d)
    ..date = d;
}

extension DailyRecordDay on DailyRecord {
  /// 記録の日の 0:00(今の地域の時刻)。表示や日付の比べ合わせはこれを使う
  /// dayKey がまだ無い(移行の前の)記録は、date から移行と同じ決め方で出す
  DateTime get day => parseDayKey(dayKey) ?? parseDayKey(legacyDayKey(date))!;
}
