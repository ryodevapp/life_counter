import 'package:isar/isar.dart';

part 'bucket_item.g.dart';

/// やりたいことリストの1件
@collection
class BucketItem {
  Id id = Isar.autoIncrement;

  late String title;

  /// 「誰と」(大切な人の id)。自分だけのことなら null
  int? personId;

  /// 今日の問いから入れたときの問いの id
  String? sourceQuestionId;

  DateTime createdAt = DateTime.now();

  /// できた日。できていなければ null(できても一覧からは消さない)
  DateTime? doneAt;
}
