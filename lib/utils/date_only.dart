/// 時刻を落として、その日の 0:00 にする
DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// 1年前の同じ日。2月29日は前年の2月28日
DateTime oneYearAgo(DateTime d) {
  if (d.month == 2 && d.day == 29) return DateTime(d.year - 1, 2, 28);
  return DateTime(d.year - 1, d.month, d.day);
}
