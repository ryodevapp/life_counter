import '../models/important_person.dart';
import 'life_table.dart';

/// 家族と一緒に過ごせる時間の計算
///
/// 親・パートナーなど: 自分と相手の平均余命のうち短いほう × 年に会う回数
/// 子ども: 親である自分が先に旅立つ前提で、自分の平均余命を上限にする。
///   一緒に暮らす期間（夏休みの回数）と、家を出たあと会える回数に分ける
class FamilyTime {
  const FamilyTime({
    required this.togetherYears,
    required this.meetCount,
    this.summersAtHome,
    this.meetCountAfterLeaving,
  });

  /// これから一緒に過ごせる年数（目安）
  final double togetherYears;

  /// これから会える回数（目安）。子どもは家を出たあとの回数
  final int meetCount;

  /// 子ども: 一緒に暮らす夏休みの回数（家を出ていれば null）
  final int? summersAtHome;

  /// 子ども: 家を出たあと会える回数
  final int? meetCountAfterLeaving;

  /// 会う頻度が高い（週1以上）なら、回数より年数で見せる
  bool get showYears => meetCount > 2000;

  static FamilyTime of(
    ImportantPerson p, {
    required DateTime myBirthDate,
    required Gender myGender,
    DateTime? now,
  }) {
    final today = now ?? DateTime.now();
    final mine = LifeTable.expectancyFromBirth(myBirthDate, myGender, now: today);

    if (p.relation == Relation.child) {
      // 夏休みの回数は満年齢で数える（日数 ÷ 365.25 だと誕生日当日に1歳ずれる）
      var age = today.year - p.birthDate.year;
      if (today.month < p.birthDate.month ||
          (today.month == p.birthDate.month && today.day < p.birthDate.day)) {
        age--;
      }
      final yearsAtHome = (p.untilAge - age).clamp(0, 99).toDouble();
      final summers = (p.untilAge - age).clamp(0, 99);
      final afterYears = (mine - yearsAtHome).clamp(0, 99).toDouble();
      final after = (afterYears * p.afterFrequency).floor();
      return FamilyTime(
        togetherYears: mine,
        meetCount: after,
        summersAtHome: summers > 0 ? summers : null,
        meetCountAfterLeaving: after,
      );
    }

    final theirs = LifeTable.expectancyFromBirth(p.birthDate, p.gender, now: today);
    final years = mine < theirs ? mine : theirs;
    return FamilyTime(
      togetherYears: years,
      meetCount: (years * p.meetingFrequency).floor(),
    );
  }
}
