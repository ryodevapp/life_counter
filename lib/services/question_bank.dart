import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/question.dart';

/// 日付から問いの番号(1〜365)を出す。
///
/// 同じ月日なら毎年同じ値になる。うるう年の2月29日は2月28日と同じ値、
/// うるう年の3月1日以降は1引くので、12月31日は常に365になる。
int questionDayOfYear(DateTime date) {
  final start = DateTime.utc(date.year, 1, 1);
  final day = DateTime.utc(date.year, date.month, date.day);
  final raw = day.difference(start).inDays + 1;
  final isLeap = DateTime.utc(date.year, 2, 29).month == 2;
  if (isLeap && raw >= 60) {
    // 60 = 2月29日。2月28日(59)と同じにし、3月1日以降は1つ詰める。
    return raw - 1;
  }
  return raw;
}

/// 365問を持ち、日付や id から問いを引く。
class QuestionBank {
  QuestionBank(List<Question> all)
      : _all = List.unmodifiable(all),
        _byDay = {for (final q in all) q.dayOfYear: q},
        _byId = {for (final q in all) q.id: q};

  static const assetPath = 'assets/data/questions_v2.json';

  final List<Question> _all;
  final Map<int, Question> _byDay;
  final Map<String, Question> _byId;

  /// アセットの JSON(`{"status": ..., "questions": [...]}`)から読む。
  static Future<QuestionBank> load() async {
    final raw = await rootBundle.loadString(assetPath);
    return QuestionBank(parse(raw));
  }

  /// JSON の文字列を問いの一覧にする。
  static List<Question> parse(String raw) {
    final json = jsonDecode(raw) as Map<String, dynamic>;
    return (json['questions'] as List)
        .map((e) => Question.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  List<Question> get all => _all;

  /// その日の問い。
  Question forDate(DateTime date) {
    final q = _byDay[questionDayOfYear(date)];
    if (q != null) return q;
    // データに欠けがあっても落ちないよう、番号で巡回して返す。
    return _all[(questionDayOfYear(date) - 1) % _all.length];
  }

  Question? byId(String id) => _byId[id];
}
