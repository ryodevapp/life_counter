import 'package:isar/isar.dart';
import '../utils/day_key.dart';

part 'important_person.g.dart';

@collection
class ImportantPerson {
  Id id = Isar.autoIncrement;

  late String nickname;

  /// v1.1.4 までの誕生日(作ったときの地域の 0:00 を時刻の一点で保存したもの)。
  /// 互換のために書き続けるが、読むときは [birthDayKey] を先に使う(LC-30)
  late DateTime birthDate;

  /// 誕生日の「yyyy-MM-dd」。時間帯が変わっても同じ日のまま(LC-30)
  String? birthDayKey;

  @Enumerated(EnumType.name)
  Gender gender = Gender.unspecified;

  /// 年間の会う回数
  int meetingFrequency = 4;

  /// v1.1.4 までの最後に会った日(時刻の一点)。読むときは [lastMetDayKey] を先に使う(LC-30)
  DateTime? lastMetDate;

  /// 最後に会った日の「yyyy-MM-dd」(LC-30)
  String? lastMetDayKey;

  DateTime createdAt = DateTime.now();
  DateTime updatedAt = DateTime.now();

  /// 誕生日(その地域の 0:00)。[birthDayKey] が無い・読めなければ古い値から日を決める
  @ignore
  DateTime get birthDay => dayFromKeyOrLegacy(birthDayKey, birthDate)!;

  /// 最後に会った日(その地域の 0:00)。無ければ null
  @ignore
  DateTime? get lastMetDay => dayFromKeyOrLegacy(lastMetDayKey, lastMetDate);

  /// 誕生日を入れる。古い形と dayKey の両方に書く
  void setBirthDay(DateTime d) {
    birthDate = DateTime(d.year, d.month, d.day);
    birthDayKey = dayKeyOf(d);
  }

  /// 最後に会った日を入れる(null で消す)。古い形と dayKey の両方に書く
  void setLastMetDay(DateTime? d) {
    lastMetDate = d == null ? null : DateTime(d.year, d.month, d.day);
    lastMetDayKey = d == null ? null : dayKeyOf(d);
  }
}

enum Gender {
  male,
  female,
  unspecified,
}
