import '../models/daily_record.dart';
import '../utils/day_key.dart';

/// 移行で書くものと消すもの
class DayKeyMigrationPlan {
  const DayKeyMigrationPlan({required this.put, required this.deleteIds});

  /// dayKey を埋めた(まとめた)記録
  final List<DailyRecord> put;

  /// ほかの記録にまとめたので消す id
  final List<int> deleteIds;
}

/// すべての記録から、移行の中身を決める(データベースに触らない)
/// [localOffset] は今の地域の時差(テスト用。省略すると端末の時差)
DayKeyMigrationPlan planDayKeyMigration(List<DailyRecord> records,
    {Duration? localOffset}) {
  final byKey = <String, List<DailyRecord>>{};
  for (final r in records) {
    // dayKey が入っていればそのまま(新しい版で作ったもの)。無ければ date から
    final key = r.dayKey.isNotEmpty
        ? r.dayKey
        : legacyDayKey(r.date, localOffset: localOffset);
    byKey.putIfAbsent(key, () => []).add(r);
  }
  final put = <DailyRecord>[];
  final deleteIds = <int>[];
  for (final entry in byKey.entries) {
    final group = entry.value;
    if (group.length == 1) {
      final r = group.single;
      if (r.dayKey != entry.key) put.add(r..dayKey = entry.key);
      continue;
    }
    final merged = mergeSameDayRecords(group)..dayKey = entry.key;
    put.add(merged);
    deleteIds.addAll(group.where((r) => r.id != merged.id).map((r) => r.id));
  }
  return DayKeyMigrationPlan(put: put, deleteIds: deleteIds);
}

/// 同じ日の記録を1つにまとめる
///
/// - いちばん新しく直した(updatedAt)記録を土台にし、その id を残す
/// - 空でない項目を残す。文の欄で中身が違うときは、新しいほうを先にして両方つなぐ(文は消さない)
/// - スタンプは押した時刻(stampAt)の新しいほう。時刻が無ければ新しく直した記録のもの
/// - 作った時刻はいちばん古いもの、直した時刻はいちばん新しいもの
DailyRecord mergeSameDayRecords(List<DailyRecord> records) {
  assert(records.isNotEmpty);
  final sorted = [...records]..sort((a, b) {
      final c = b.updatedAt.compareTo(a.updatedAt);
      return c != 0 ? c : b.id.compareTo(a.id);
    });
  final base = sorted.first;

  String? firstNonEmpty(String? Function(DailyRecord r) get) {
    for (final r in sorted) {
      final v = get(r);
      if (v != null && v.trim().isNotEmpty) return v;
    }
    return null;
  }

  String? joinTexts(String? Function(DailyRecord r) get) {
    final texts = <String>[];
    for (final r in sorted) {
      final v = get(r);
      if (v == null || v.trim().isEmpty) continue;
      if (!texts.any((t) => t.trim() == v.trim())) texts.add(v);
    }
    return texts.isEmpty ? null : texts.join('\n\n');
  }

  // スタンプ: 押した時刻があるものの中で最新。無ければ新しい順で最初にスタンプがあるもの
  DailyRecord? stampSource;
  for (final r in sorted) {
    final at = r.stampAt;
    if (at == null) continue;
    if (stampSource == null || at.isAfter(stampSource.stampAt!)) stampSource = r;
  }
  stampSource ??= sorted.firstWhere((r) => r.stamp != null,
      orElse: () => base);

  final merged = DailyRecord()
    ..id = base.id
    ..dayKey = base.dayKey
    ..date = base.date
    ..todayGoal = joinTexts((r) => r.todayGoal)
    ..reflectionGood = joinTexts((r) => r.reflectionGood)
    ..reflectionWhy = joinTexts((r) => r.reflectionWhy)
    ..reflectionTomorrow = joinTexts((r) => r.reflectionTomorrow)
    ..weeklyReflectionHighlight = joinTexts((r) => r.weeklyReflectionHighlight)
    ..weeklyReflectionChange = joinTexts((r) => r.weeklyReflectionChange)
    ..gratitude = joinTexts((r) => r.gratitude)
    ..tomorrowMessage = joinTexts((r) => r.tomorrowMessage)
    ..answer = joinTexts((r) => r.answer)
    ..morningQuestionId = firstNonEmpty((r) => r.morningQuestionId)
    ..greatPersonId = firstNonEmpty((r) => r.greatPersonId)
    ..stamp = stampSource.stamp
    ..stampAt = stampSource.stampAt
    ..createdAt = sorted
        .map((r) => r.createdAt)
        .reduce((a, b) => a.isBefore(b) ? a : b)
    ..updatedAt = base.updatedAt;
  return merged;
}
