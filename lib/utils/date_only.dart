/// 時刻を落として、その日の 0:00 にする
DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// [from] の日から [to] の日まで、暦で何日あるか(時刻は見ない。[to] が前なら負)
///
/// 時刻の差(`difference(...).inDays`)で数えると、夏時間のある地域では
/// 冬の日の 0:00 から夏の日の 0:00〜0:59 までが「日数 × 24 時間 − 1 時間」になり、1日少なく出る(LC-30 の続き)。
/// 年月日を UTC に置き直して数えるので、どの時間帯でも暦の日の差になる
int calendarDaysBetween(DateTime from, DateTime to) =>
    DateTime.utc(to.year, to.month, to.day)
        .difference(DateTime.utc(from.year, from.month, from.day))
        .inDays;

/// 1年前の同じ日。2月29日は前年の2月28日
DateTime oneYearAgo(DateTime d) {
  if (d.month == 2 && d.day == 29) return DateTime(d.year - 1, 2, 28);
  return DateTime(d.year - 1, d.month, d.day);
}
