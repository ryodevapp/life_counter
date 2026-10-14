import 'package:flutter_test/flutter_test.dart';
import 'package:life_counter/utils/date_only.dart';

void main() {
  group('dateOnly', () {
    test('drops the time', () {
      expect(dateOnly(DateTime(2026, 10, 15, 23, 59, 59)), DateTime(2026, 10, 15));
    });
  });

  group('oneYearAgo', () {
    test('same month and day one year before', () {
      expect(oneYearAgo(DateTime(2026, 10, 15)), DateTime(2025, 10, 15));
    });
    test('Feb 29 goes to Feb 28 of the previous year', () {
      expect(oneYearAgo(DateTime(2028, 2, 29)), DateTime(2027, 2, 28));
    });
    test('Mar 1 after a leap day stays Mar 1', () {
      expect(oneYearAgo(DateTime(2029, 3, 1)), DateTime(2028, 3, 1));
    });
  });
}
