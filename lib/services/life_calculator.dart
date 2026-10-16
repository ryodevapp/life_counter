import '../models/important_person.dart';
import 'country_lifespans.dart';
import 'life_tables.dart';

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

  /// これからの日数の目安(その年齢の平均余命から)
  static int remainingDays(DateTime birthDate, Gender gender) =>
      (expectedYearsAhead(birthDate, gender) * 365.25).floor();

  /// 健康寿命までの残り日数
  static int healthyRemainingDays(DateTime birthDate, Gender gender) {
    final hl = healthyLifespan(gender);
    final daysSinceBirth = DateTime.now().difference(birthDate).inDays;
    return (hl * 365.25 - daysSinceBirth).floor().clamp(0, 999999);
  }

  /// これからの年数の目安(その年齢の平均余命から)
  static int remainingYears(DateTime birthDate, Gender gender) =>
      expectedYearsAhead(birthDate, gender).floor();

  // ─── 年齢ごとの平均余命(生命表)で出す「これから」 ───
  // 「生まれたときの平均寿命 − いまの年齢」は、年を重ねた人ほど短く出てしまう(若くして亡くなった人も含む平均のため)。
  // その年齢まで生きた人の平均余命を使うので、0 にはならず、平均を越えた人にも目安が出る

  /// いまの正確な年齢(年。誕生日からの日数 ÷ 365.25)
  static double exactAge(DateTime birthDate, [DateTime? now]) =>
      (now ?? DateTime.now()).difference(birthDate).inDays / 365.25;

  /// 日本の生命表(1歳ごと)を、年齢の間は直線でつないで引く
  static double _jp(List<double> table, double age) {
    if (age <= 0) return table.first;
    if (age >= table.length - 1) return table.last;
    final i = age.floor();
    final t = age - i;
    return table[i] * (1 - t) + table[i + 1] * t;
  }

  static double _jpSex(Gender g, double age) => switch (g) {
        Gender.male => _jp(jpLifeTableMale, age),
        Gender.female => _jp(jpLifeTableFemale, age),
        Gender.unspecified =>
          (_jp(jpLifeTableMale, age) + _jp(jpLifeTableFemale, age)) / 2,
      };

  /// WHO の表(年齢区分の始まりごと)を直線でつなぐ。85歳を越えたら、日本の表の減り方の比で伸ばす
  static double _who(
      ({List<double> male, List<double> female, List<double> both}) t,
      Gender g,
      double age) {
    final row = switch (g) {
      Gender.male => t.male,
      Gender.female => t.female,
      Gender.unspecified => t.both,
    };
    final last = whoAgeStarts.length - 1;
    if (age >= whoAgeStarts[last]) {
      return row[last] * _jpSex(g, age) / _jpSex(g, whoAgeStarts[last].toDouble());
    }
    for (var i = 0; i < last; i++) {
      final a0 = whoAgeStarts[i], a1 = whoAgeStarts[i + 1];
      if (age < a1) {
        final t = ((age - a0) / (a1 - a0)).clamp(0.0, 1.0);
        return row[i] * (1 - t) + row[i + 1] * t;
      }
    }
    return row[last];
  }

  /// その年齢の平均余命(年)。住んでいる国の表で出す
  static double expectedYearsAhead(DateTime birthDate, Gender gender,
      [DateTime? now]) {
    final age = exactAge(birthDate, now).clamp(0.0, 120.0);
    final r = regionCode?.toUpperCase();
    if (r == null || r == 'JP') return _jpSex(gender, age);
    final who = whoLifeTables[r];
    if (who != null) return _who(who, gender, age);
    // 台湾・香港など WHO に無い国は、日本の表を「生まれたときの平均寿命の比」で伸び縮みさせる
    final c = countryLifespans[r];
    if (c != null) {
      final jp0 = _jpSex(gender, 0);
      final c0 = switch (gender) {
        Gender.male => c.male,
        Gender.female => c.female,
        Gender.unspecified => c.both,
      };
      return _jpSex(gender, age) * c0 / jp0;
    }
    return _who(whoLifeTables['WORLD']!, gender, age);
  }

  /// その年齢の平均寿命を越えているか(数字は出したまま、ひとこと添えるために使う)
  static bool isPastAverage(DateTime birthDate, Gender gender) =>
      currentAge(birthDate) >= averageLifespan(gender);
}
