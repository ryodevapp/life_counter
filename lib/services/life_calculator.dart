import '../models/important_person.dart';
import 'country_lifespans.dart';

/// 寿命・人生日数の計算ロジック
class LifeCalculator {
  LifeCalculator._();

  /// 端末の地域(ISO 3166-1 の2文字)。起動時に入れる。日本(JP)か未設定なら日本の値、
  /// それ以外はその国の WHO の値、表にない国は世界平均で計算する
  static String? regionCode;

  static CountryLifespan? get _country {
    final r = regionCode?.toUpperCase();
    if (r == null || r == 'JP') return null;
    return countryLifespans[r] ?? worldLifespan;
  }

  /// 平均寿命（年）
  static double averageLifespan(Gender gender) {
    final c = _country;
    if (c != null) {
      return switch (gender) {
        Gender.male => c.male,
        Gender.female => c.female,
        Gender.unspecified => c.both,
      };
    }
    switch (gender) {
      // 厚生労働省「令和7年簡易生命表」(2025年)
      case Gender.male:
        return 81.35;
      case Gender.female:
        return 87.33;
      case Gender.unspecified:
        return 84.34;
    }
  }

  /// 健康寿命（年）
  static double healthyLifespan(Gender gender) {
    final c = _country;
    if (c != null) {
      return switch (gender) {
        Gender.male => c.healthyMale,
        Gender.female => c.healthyFemale,
        Gender.unspecified => c.healthyBoth,
      };
    }
    switch (gender) {
      // 厚生労働科学研究「健康寿命の算定」(2022年)
      case Gender.male:
        return 72.57;
      case Gender.female:
        return 75.45;
      case Gender.unspecified:
        return 74.01;
    }
  }

  /// 誕生日から今日までの日数（1日目始まり）
  static int lifeDays(DateTime birthDate) {
    final today = DateTime.now();
    return today.difference(birthDate).inDays + 1;
  }

  /// 現在の年齢
  static int currentAge(DateTime birthDate) {
    final today = DateTime.now();
    int age = today.year - birthDate.year;
    if (today.month < birthDate.month ||
        (today.month == birthDate.month && today.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  /// 平均寿命までの残り日数
  static int remainingDays(DateTime birthDate, Gender gender) {
    final al = averageLifespan(gender);
    final daysSinceBirth = DateTime.now().difference(birthDate).inDays;
    return (al * 365.25 - daysSinceBirth).floor().clamp(0, 999999);
  }

  /// 健康寿命までの残り日数
  static int healthyRemainingDays(DateTime birthDate, Gender gender) {
    final hl = healthyLifespan(gender);
    final daysSinceBirth = DateTime.now().difference(birthDate).inDays;
    return (hl * 365.25 - daysSinceBirth).floor().clamp(0, 999999);
  }

  /// 残り年数
  static int remainingYears(DateTime birthDate, Gender gender) {
    final al = averageLifespan(gender);
    final age = currentAge(birthDate);
    return (al - age).floor().clamp(0, 999);
  }
}
