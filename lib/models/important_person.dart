import 'package:isar/isar.dart';

part 'important_person.g.dart';

@collection
class ImportantPerson {
  Id id = Isar.autoIncrement;

  late String nickname;
  late DateTime birthDate;

  @Enumerated(EnumType.name)
  Gender gender = Gender.unspecified;

  /// 年間の会う回数
  int meetingFrequency = 4;

  DateTime? lastMetDate;

  // v1.1 新規フィールド（既存のデータには値が無いので、null を既定値として扱う）
  /// 関係。既存のデータは other として読まれる（enum の先頭）
  @Enumerated(EnumType.name)
  Relation relation = Relation.other;

  /// 子ども: 何歳まで一緒に暮らすか
  int? liveTogetherUntilAge;

  /// 子ども: 家を出たあと、年に会う回数
  int? afterLeavingFrequency;

  // v1.2 新規フィールド
  /// 次に会う予定の日
  DateTime? nextMeetDate;

  /// v1.2 の途中版で使った誕生日の欄（いまは生年月日から出すので使わない）
  int? birthdayMonth;
  int? birthdayDay;

  /// 写真のファイル名（App Group の photos フォルダの中）
  String? photoFile;

  DateTime createdAt = DateTime.now();
  DateTime updatedAt = DateTime.now();

  @ignore
  int get untilAge => liveTogetherUntilAge ?? 18;

  @ignore
  int get afterFrequency => afterLeavingFrequency ?? 4;
}

enum Gender {
  male,
  female,
  unspecified,
}

/// 家族との関係（先頭の other が、値の無い既存データの読み込み先になる）
enum Relation {
  other,
  parent,
  child,
  partner,
}

extension RelationLabel on Relation {
  String get label => switch (this) {
        Relation.parent => '親',
        Relation.child => '子ども',
        Relation.partner => 'パートナー',
        Relation.other => 'その他',
      };
}
