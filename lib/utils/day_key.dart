/// 記録の日付を「yyyy-MM-dd」の文字で表す。端末のタイムゾーンが変わっても、同じ日は同じ文字のまま
///
/// [d] の年・月・日をそのまま使う(ローカル時刻なら、その地域で見た日付)
String dayKeyOf(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${_two(d.month)}-${_two(d.day)}';

/// 「yyyy-MM-dd」をその日の 0:00(ローカル)に戻す。形が違う・ありえない日付なら null
DateTime? parseDayKey(String key) {
  final m = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(key);
  if (m == null) return null;
  final y = int.parse(m[1]!), mo = int.parse(m[2]!), d = int.parse(m[3]!);
  final date = DateTime(y, mo, d);
  // 2026-02-30 のように繰り上がる日付は受け取らない
  if (date.year != y || date.month != mo || date.day != d) return null;
  return date;
}

/// その月の最初と最後の日の key(文字の大小で範囲を取れる)。月の繰り上がりは直す(13月 → 翌年1月)
(String, String) monthDayKeyRange(int year, int month) {
  final first = DateTime(year, month, 1);
  final last = DateTime(first.year, first.month + 1, 0);
  return (dayKeyOf(first), dayKeyOf(last));
}

/// v1.1.0 までの記録の date(作ったときの地域の 0:00 を時刻の一点で保存したもの)から日を決める
///
/// 今の地域で読んで 0:00 ちょうどなら、その日(ふつうはこれ)。
/// 0:00 でなければ、作ったあとに地域が変わっている。そのときは「どこかの地域(UTC-12〜+14)で
/// 15 分刻みの時差で 0:00 になる日」を探し、候補が2つなら今の地域の時差に近いほうを採る。
/// どれにも当たらなければ、今の地域で読んだ日。
/// [localOffset] は今の地域の時差(テスト用。省略すると端末の時差)
String legacyDayKey(DateTime stored, {Duration? localOffset}) {
  final utc = stored.toUtc();
  final offset = localOffset ?? stored.toLocal().timeZoneOffset;
  // 年月日を「今の地域で見た値」にした UTC の DateTime(端末の地域に左右されない)
  final local = utc.add(offset);
  if (local.hour == 0 &&
      local.minute == 0 &&
      local.second == 0 &&
      local.millisecond == 0 &&
      local.microsecond == 0) {
    return dayKeyOf(local);
  }
  final sinceMidnight = utc.difference(DateTime.utc(utc.year, utc.month, utc.day));
  const minOffset = Duration(hours: -12), maxOffset = Duration(hours: 14);
  // 実在する時差は 15 分刻み
  final step = const Duration(minutes: 15).inMicroseconds;
  final candidates = [-sinceMidnight, const Duration(hours: 24) - sinceMidnight]
      .where((o) =>
          o >= minOffset && o <= maxOffset && o.inMicroseconds % step == 0)
      .toList();
  if (candidates.isEmpty) return dayKeyOf(local);
  candidates.sort((a, b) =>
      (a - offset).abs().compareTo((b - offset).abs()));
  return dayKeyOf(utc.add(candidates.first));
}

String _two(int n) => n.toString().padLeft(2, '0');
