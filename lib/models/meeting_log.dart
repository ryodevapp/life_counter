import 'package:isar/isar.dart';

part 'meeting_log.g.dart';

/// 家族と会えた日の記録
@collection
class MeetingLog {
  Id id = Isar.autoIncrement;

  @Index()
  late int personId;

  @Index()
  late DateTime date;

  String? note;

  /// 写真のファイル名（App Group の photos フォルダの中）
  String? photoFile;

  /// つながり方。値の無い既存データは met(会えた)として読まれる（enum の先頭）
  @Enumerated(EnumType.name)
  ContactKind kind = ContactKind.met;

  DateTime createdAt = DateTime.now();
}

/// 家族とのつながり方（先頭の met が、値の無い既存データの読み込み先になる）
/// video は v2.0 の試作版の名残。画面では call と同じ「話した」として扱う
enum ContactKind { met, call, video, message }

/// 画面で選べるつながり方(電話とビデオ通話は「話した」にまとめる)
const selectableContactKinds = [ContactKind.met, ContactKind.call, ContactKind.message];

extension ContactKindLabel on ContactKind {
  String get label => switch (this) {
        ContactKind.met => '会えた',
        ContactKind.call => '話した',
        ContactKind.video => '話した',
        ContactKind.message => 'メッセージ',
      };

  /// アプリの記号（絵文字は使わず、Material のアイコン名で持つ）
  String get iconName => switch (this) {
        ContactKind.met => 'met',
        ContactKind.call => 'call',
        ContactKind.video => 'video',
        ContactKind.message => 'message',
      };
}
