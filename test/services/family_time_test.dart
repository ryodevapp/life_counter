import 'package:flutter_test/flutter_test.dart';
import 'package:life_counter/models/important_person.dart';
import 'package:life_counter/services/family_time.dart';
import 'package:life_counter/services/life_table.dart';

void main() {
  final now = DateTime(2026, 10, 10);
  DateTime born(int age) => DateTime(now.year - age, now.month, now.day);

  group('LifeTable', () {
    test('表にある年齢はそのままの値', () {
      expect(LifeTable.expectancy(65, Gender.female), 24.38);
      expect(LifeTable.expectancy(40, Gender.male), 42.03);
    });

    test('間の年齢は直線で補う', () {
      expect(LifeTable.expectancy(67.5, Gender.female),
          closeTo((24.38 + 19.97) / 2, 0.001));
    });

    test('平均寿命を超えた85歳でも、余命は0にならない', () {
      expect(LifeTable.expectancy(85, Gender.female), 8.37);
      expect(LifeTable.expectancy(110, Gender.male), greaterThanOrEqualTo(1));
    });
  });

  group('FamilyTime', () {
    test('65歳の母に年2回会う40歳男性: 約48回', () {
      final mother = ImportantPerson()
        ..nickname = '母'
        ..birthDate = born(65)
        ..gender = Gender.female
        ..meetingFrequency = 2
        ..relation = Relation.parent;
      final t = FamilyTime.of(mother,
          myBirthDate: born(40), myGender: Gender.male, now: now);
      expect(t.meetCount, inInclusiveRange(48, 49));
    });

    test('85歳の母でも回数が出る(以前は平均寿命超えで出なかった)', () {
      final mother = ImportantPerson()
        ..nickname = '母'
        ..birthDate = born(85)
        ..gender = Gender.female
        ..meetingFrequency = 4
        ..relation = Relation.parent;
      final t = FamilyTime.of(mother,
          myBirthDate: born(55), myGender: Gender.male, now: now);
      expect(t.meetCount, greaterThan(0));
    });

    test('6歳の子: 夏休み12回、その後は自分の余命から', () {
      final child = ImportantPerson()
        ..nickname = 'ゆい'
        ..birthDate = born(6)
        ..relation = Relation.child
        ..liveTogetherUntilAge = 18
        ..afterLeavingFrequency = 4;
      final t = FamilyTime.of(child,
          myBirthDate: born(40), myGender: Gender.male, now: now);
      expect(t.summersAtHome, 12);
      expect(t.meetCountAfterLeaving, inInclusiveRange(119, 120));
    });

    test('既存データ(関係・子どもの欄が無い)は既定値で計算できる', () {
      final p = ImportantPerson()
        ..nickname = '友人'
        ..birthDate = born(40)
        ..meetingFrequency = 4;
      expect(p.relation, Relation.other);
      expect(p.untilAge, 18);
      final t = FamilyTime.of(p,
          myBirthDate: born(40), myGender: Gender.male, now: now);
      expect(t.meetCount, greaterThan(0));
    });
  });
}
