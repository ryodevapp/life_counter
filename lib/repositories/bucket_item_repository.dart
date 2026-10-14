import 'package:isar/isar.dart';
import '../models/bucket_item.dart';

class BucketItemRepository {
  BucketItemRepository(this._isar);
  final Isar _isar;

  /// まだのものを上に、それぞれ新しい順
  Stream<List<BucketItem>> watchAll() {
    return _isar.bucketItems
        .where()
        .watch(fireImmediately: true)
        .map(sortBucketItems);
  }

  Future<List<BucketItem>> getAll() async =>
      sortBucketItems(await _isar.bucketItems.where().findAll());

  Future<void> add(String title,
      {int? personId, String? sourceQuestionId}) async {
    final trimmed = title.trim();
    if (trimmed.isEmpty) return;
    // 同じものを何度も入れない(まだのものに同じ文があれば足さない)
    final exists = await _isar.bucketItems
        .filter()
        .titleEqualTo(trimmed)
        .doneAtIsNull()
        .isNotEmpty();
    if (exists) return;
    final item = BucketItem()
      ..title = trimmed
      ..personId = personId
      ..sourceQuestionId = sourceQuestionId;
    await _isar.writeTxn(() => _isar.bucketItems.put(item));
  }

  Future<void> toggleDone(int id) async {
    await _isar.writeTxn(() async {
      final item = await _isar.bucketItems.get(id);
      if (item == null) return;
      item.doneAt = item.doneAt == null ? DateTime.now() : null;
      await _isar.bucketItems.put(item);
    });
  }

  Future<void> delete(int id) async {
    await _isar.writeTxn(() => _isar.bucketItems.delete(id));
  }
}

List<BucketItem> sortBucketItems(List<BucketItem> items) {
  final sorted = [...items];
  sorted.sort((a, b) {
    final aDone = a.doneAt != null;
    final bDone = b.doneAt != null;
    if (aDone != bDone) return aDone ? 1 : -1;
    return b.createdAt.compareTo(a.createdAt);
  });
  return sorted;
}
