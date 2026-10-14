import 'package:isar/isar.dart';

part 'daily_record.g.dart';

@collection
class DailyRecord {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
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
