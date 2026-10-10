import '../models/important_person.dart';

/// 年齢ごとの平均余命（厚生労働省「令和6年簡易生命表」の主な年齢）
/// 表の間の年齢は直線で補う
class LifeTable {
  LifeTable._();

  // [年齢, 男, 女]
  static const _rows = <List<double>>[
    [0, 81.09, 87.13],
    [10, 71.32, 77.37],
    [20, 61.44, 67.48],
    [30, 51.71, 57.67],
    [40, 42.03, 47.88],
    [50, 32.57, 38.24],
    [60, 23.63, 28.92],
    [65, 19.47, 24.38],
    [70, 15.60, 19.97],
    [75, 12.08, 15.75],
    [80, 8.96, 11.83],
    [85, 6.31, 8.37],
    [90, 4.27, 5.55],
  ];

  static const source = '厚生労働省「令和6年簡易生命表」';

  /// その年齢から先の平均余命（年）
  static double expectancy(double age, Gender gender) {
    double pick(List<double> row) => switch (gender) {
          Gender.male => row[1],
          Gender.female => row[2],
          Gender.unspecified => (row[1] + row[2]) / 2,
        };

    if (age <= 0) return pick(_rows.first);
    final last = _rows.last;
    if (age >= last[0]) {
      // 90歳より先は表が無いので、ゆるやかに減らす（最低1年）
      return (pick(last) - (age - last[0]) * 0.3).clamp(1.0, 99.0);
    }
    for (var i = 0; i < _rows.length - 1; i++) {
      final a0 = _rows[i][0], a1 = _rows[i + 1][0];
      if (age >= a0 && age <= a1) {
        final t = (age - a0) / (a1 - a0);
        return pick(_rows[i]) + (pick(_rows[i + 1]) - pick(_rows[i])) * t;
      }
    }
    return pick(last);
  }

  /// 誕生日から、今日時点の平均余命（年）
  static double expectancyFromBirth(DateTime birthDate, Gender gender,
      {DateTime? now}) {
    final today = now ?? DateTime.now();
    final age = today.difference(birthDate).inDays / 365.25;
    return expectancy(age, gender);
  }
}
