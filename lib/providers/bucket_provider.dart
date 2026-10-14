import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/bucket_item.dart';
import 'isar_provider.dart';

/// やりたいことリスト(まだのものが上、それぞれ新しい順)
final bucketItemsProvider = StreamProvider<List<BucketItem>>((ref) {
  return ref.watch(bucketItemRepositoryProvider).watchAll();
});
