import 'package:flutter_test/flutter_test.dart';
import 'package:life_counter/models/important_person.dart';
import 'package:life_counter/services/country_lifespans.dart';
import 'package:life_counter/services/life_calculator.dart';

void main() {
  group('LifeCalculator', () {
    test('平均寿命の値が正しい', () {
      expect(LifeCalculator.averageLifespan(Gender.male), 81.35);
      expect(LifeCalculator.averageLifespan(Gender.female), 87.33);
      expect(LifeCalculator.averageLifespan(Gender.unspecified), 84.34);
    });

    test('健康寿命の値が正しい', () {
      expect(LifeCalculator.healthyLifespan(Gender.male), 72.57);
      expect(LifeCalculator.healthyLifespan(Gender.female), 75.45);
      expect(LifeCalculator.healthyLifespan(Gender.unspecified), 74.01);
    });

    test('lifeDays: 生まれた日が1日目', () {
      final today = DateTime.now();
      final birthDate = DateTime(today.year, today.month, today.day);
      expect(LifeCalculator.lifeDays(birthDate), 1);
    });

    test('lifeDays: 昨日生まれなら2日目', () {
      final yesterday =
          DateTime.now().subtract(const Duration(days: 1));
      final birthDate =
          DateTime(yesterday.year, yesterday.month, yesterday.day);
      expect(LifeCalculator.lifeDays(birthDate), 2);
    });

    test('currentAge: 30歳のユーザー', () {
      final today = DateTime.now();
      final birthDate = DateTime(today.year - 30, today.month, today.day);
      expect(LifeCalculator.currentAge(birthDate), 30);
    });

    test('remainingDays: 正の値を返す', () {
      final birthDate = DateTime(1995, 1, 1);
      final remaining =
          LifeCalculator.remainingDays(birthDate, Gender.male);
      expect(remaining, greaterThan(0));
    });

    test('remainingDays: 非常に高齢でも0にはならない(105歳以上の平均余命、約1年)', () {
      final birthDate = DateTime(1900, 1, 1);
      final remaining =
          LifeCalculator.remainingDays(birthDate, Gender.male);
      expect(remaining, inInclusiveRange(365, 400));
    });

    test('remainingYears: 正の整数を返す', () {
      final birthDate = DateTime(1995, 1, 1);
      final years =
          LifeCalculator.remainingYears(birthDate, Gender.male);
      expect(years, greaterThan(0));
      expect(years, lessThan(100));
    });
  });

  group('LifeCalculator の国ごとの平均', () {
    tearDown(() => LifeCalculator.regionCode = null);

    test('日本か未設定なら、これまでの日本の値', () {
      LifeCalculator.regionCode = 'JP';
      expect(LifeCalculator.averageLifespan(Gender.male), 81.35);
      LifeCalculator.regionCode = null;
      expect(LifeCalculator.healthyLifespan(Gender.female), 75.45);
    });

    test('米国なら米国の WHO の値', () {
      LifeCalculator.regionCode = 'US';
      expect(LifeCalculator.averageLifespan(Gender.male), 76.2);
      expect(LifeCalculator.healthyLifespan(Gender.unspecified), 64.6);
    });

    test('表にない国は世界平均', () {
      LifeCalculator.regionCode = 'ZZ';
      expect(LifeCalculator.averageLifespan(Gender.unspecified),
          worldLifespan.both);
    });
  });

  group('その年齢の平均余命(生命表)', () {
    tearDown(() => LifeCalculator.regionCode = null);
    final now = DateTime(2026, 10, 16);

    test('日本: 72歳の女性は約18.4年、85歳の男性は約6.4年(引き算のように消えない)', () {
      expect(
          LifeCalculator.expectedYearsAhead(
              DateTime(1954, 10, 16), Gender.female, now),
          closeTo(18.39, 0.05));
      expect(
          LifeCalculator.expectedYearsAhead(
              DateTime(1941, 10, 16), Gender.male, now),
          closeTo(6.44, 0.05));
    });

    test('105歳を越えても0にならない', () {
      expect(
          LifeCalculator.expectedYearsAhead(
              DateTime(1915, 1, 1), Gender.male, now),
          greaterThan(1.0));
    });

    test('米国は WHO の表(75歳の男性は約11年)', () {
      LifeCalculator.regionCode = 'US';
      final y = LifeCalculator.expectedYearsAhead(
          DateTime(1951, 10, 16), Gender.male, now);
      expect(y, inInclusiveRange(10.0, 13.0));
    });

    test('若い人では、生まれたときの平均からの引き算とほぼ同じ', () {
      final y = LifeCalculator.expectedYearsAhead(
          DateTime(1986, 10, 16), Gender.male, now);
      expect((y - (81.35 - 40)).abs(), lessThan(1.5));
    });
  });
}
