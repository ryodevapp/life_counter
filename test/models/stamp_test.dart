import 'package:flutter_test/flutter_test.dart';
import 'package:life_counter/models/bucket_item.dart';
import 'package:life_counter/models/stamp.dart';
import 'package:life_counter/models/daily_record.dart';
import 'package:life_counter/repositories/bucket_item_repository.dart';
import 'package:life_counter/views/record/reflection_view.dart';

void main() {
  test('there are 5 stamps with unique ids', () {
    expect(stamps.length, 5);
    expect(stamps.map((s) => s.id).toSet().length, 5);
  });

  test('stampById finds a stamp and returns null for unknown ids', () {
    expect(stampById('happy')?.label, 'うれしい');
    expect(stampById('sad')?.label, 'かなしい');
    expect(stampById('nope'), isNull);
    expect(stampById(null), isNull);
  });

  test('bucket items: not done first, newest first in each group', () {
    BucketItem item(String t, DateTime created, {DateTime? done}) => BucketItem()
      ..title = t
      ..createdAt = created
      ..doneAt = done;
    final sorted = sortBucketItems([
      item('old', DateTime(2026, 1, 1)),
      item('done', DateTime(2026, 5, 1), done: DateTime(2026, 6, 1)),
      item('new', DateTime(2026, 3, 1)),
    ]);
    expect(sorted.map((b) => b.title), ['new', 'old', 'done']);
  });

  test('countMoods counts each mood and ignores unknown ids', () {
    DailyRecord r(String? stamp) => DailyRecord()
      ..date = DateTime(2026, 10, 1)
      ..stamp = stamp;
    final c = countMoods([r('happy'), r('happy'), r('sad'), r('old'), r(null)]);
    expect(c['happy'], 2);
    expect(c['sad'], 1);
    expect(c['calm'], 0);
    expect(c.length, 5);
  });
}
