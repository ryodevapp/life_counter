import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../models/important_person.dart';
import '../../services/family_time.dart';
import '../shared/app_colors.dart';

final _fmt = NumberFormat('#,###', 'ja_JP');

/// 「年に◯回会うなら」の言い方
String meetPhrase(int annual) {
  if (annual >= 365) return 'ほとんど毎日会うなら';
  if (annual >= 75) return '週に1〜2回会うなら';
  if (annual >= 18) return '月に1〜2回会うなら';
  if (annual >= 4) return '数ヶ月に1回会うなら';
  if (annual >= 2) return '年に1〜2回会うなら';
  return '年に1回会うなら';
}

/// 家族ひとりぶんの「一緒に過ごせる時間」の表示
class FamilyTimeView extends StatelessWidget {
  const FamilyTimeView({super.key, required this.person, required this.time});

  final ImportantPerson person;
  final FamilyTime time;

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    if (person.relation == Relation.child && time.summersAtHome != null) {
      children
        ..add(_line('一緒に暮らす夏休みは、これから'))
        ..add(_number('${time.summersAtHome}', '回'))
        ..add(const SizedBox(height: 8))
        ..add(_line(
            '家を出たあとも、${meetPhrase(person.afterFrequency).replaceAll('会うなら', '')}会えるなら 約${_fmt.format(time.meetCountAfterLeaving)}回'))
        ..add(const SizedBox(height: 6))
        ..add(_soft('今年の夏休みは、どこへ行こう'));
    } else {
      final annual = person.relation == Relation.child
          ? person.afterFrequency
          : person.meetingFrequency;
      if (annual <= 0) {
        children.add(_line('なかなか会えなくても、声を届けることはできます'));
      } else if (time.showYears) {
        children
          ..add(_line('これから一緒に過ごせる時間は'))
          ..add(_number('${time.togetherYears.floor()}', '年', approx: true));
      } else {
        children
          ..add(_line('${meetPhrase(annual)}、これから会えるのは'))
          ..add(_number(_fmt.format(time.meetCount), '回', approx: true));
        if (person.relation == Relation.parent) {
          children
            ..add(const SizedBox(height: 6))
            ..add(_soft('次に会える日を、楽しみに'));
        }
      }
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }

  static Widget _line(String text) => Text(text,
      style: GoogleFonts.zenKakuGothicNew(
          fontSize: 13, color: AppColors.textSecondary, height: 1.6));

  static Widget _soft(String text) => Text(text,
      style: GoogleFonts.zenKakuGothicNew(
          fontSize: 13, color: AppColors.accent, height: 1.6));

  static Widget _number(String value, String unit, {bool approx = false}) =>
      Text.rich(TextSpan(
        children: [
          if (approx)
            TextSpan(
              text: '約 ',
              style: GoogleFonts.zenKakuGothicNew(
                  fontSize: 14, color: AppColors.textMuted),
            ),
          TextSpan(
            text: value,
            style: GoogleFonts.cormorantGaramond(
              fontSize: 44,
              fontWeight: FontWeight.w300,
              color: AppColors.accent,
              height: 1.2,
            ),
          ),
          TextSpan(
            text: ' $unit',
            style: GoogleFonts.zenKakuGothicNew(
                fontSize: 14, color: AppColors.textMuted),
          ),
        ],
      ));
}
