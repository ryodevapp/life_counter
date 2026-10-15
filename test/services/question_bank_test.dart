import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_counter/models/question.dart';
import 'package:life_counter/services/question_bank.dart';

const _legacyIds = [
  'p1', 'p2', 'p3', 'p4', 'p5',
  'e1', 'e2', 'e3', 'e4', 'e5',
  'r1', 'r2', 'r3', 'r4', 'r5',
  'm1', 'm2', 'm3', 'm4',
  'a1', 'a2', 'a3', 'a4', 'a5',
];

const _forbiddenWords = ['余命', '寿命', '死ぬまで', 'あと何日', '死'];

List<Question> _loadFromFile() {
  final raw = File('assets/data/questions_v2.json').readAsStringSync();
  final json = jsonDecode(raw) as Map<String, dynamic>;
  return (json['questions'] as List)
      .map((e) => Question.fromJson(e as Map<String, dynamic>))
      .toList();
}

void main() {
  group('questionDayOfYear', () {
    test('1月1日は1', () {
      expect(questionDayOfYear(DateTime(2026, 1, 1)), 1);
    });

    test('2月29日は2月28日と同じ', () {
      expect(questionDayOfYear(DateTime(2028, 2, 29)),
          questionDayOfYear(DateTime(2027, 2, 28)));
    });

    test('うるう年の3月1日は平年の3月1日と同じ', () {
      expect(questionDayOfYear(DateTime(2028, 3, 1)),
          questionDayOfYear(DateTime(2027, 3, 1)));
    });

    test('12月31日は常に365', () {
      expect(questionDayOfYear(DateTime(2028, 12, 31)), 365);
      expect(questionDayOfYear(DateTime(2027, 12, 31)), 365);
    });
  });

  group('questions_v2.json', () {
    final questions = _loadFromFile();

    test('365件', () {
      expect(questions.length, 365);
    });

    test('dayOfYear が 1..365 を1回ずつ', () {
      final days = questions.map((q) => q.dayOfYear).toList()..sort();
      expect(days, List.generate(365, (i) => i + 1));
    });

    test('id が重複しない', () {
      final ids = questions.map((q) => q.id).toSet();
      expect(ids.length, questions.length);
    });

    test('category は4種だけ', () {
      final cats = questions.map((q) => q.category).toSet();
      expect(cats, {'self', 'people', 'life', 'bucket'});
    });

    test('分類ごとの数', () {
      int count(String c) => questions.where((q) => q.category == c).length;
      expect(count('self'), 146);
      expect(count('people'), 110);
      expect(count('life'), 73);
      expect(count('bucket'), 36);
    });

    test('禁止語を含まない', () {
      for (final q in questions) {
        for (final w in _forbiddenWords) {
          expect(q.text.contains(w), isFalse, reason: '${q.id}: ${q.text}');
        }
      }
    });

    test('いまの25問のうち、外した m5 以外の id をすべて含む', () {
      final ids = questions.map((q) => q.id).toSet();
      for (final id in _legacyIds) {
        expect(ids.contains(id), isTrue, reason: id);
      }
    });

    test('文が空でない', () {
      for (final q in questions) {
        expect(q.text.trim(), isNotEmpty, reason: q.id);
      }
    });
  });

  group('QuestionBank', () {
    final bank = QuestionBank(_loadFromFile());

    test('同じ月日なら年が違っても同じ問い', () {
      expect(bank.forDate(DateTime(2026, 10, 15)).id,
          bank.forDate(DateTime(2027, 10, 15)).id);
    });

    test('2月29日は2月28日と同じ問い', () {
      expect(bank.forDate(DateTime(2028, 2, 29)).id,
          bank.forDate(DateTime(2027, 2, 28)).id);
    });

    test('forDate は dayOfYear の合う問いを返す', () {
      final q = bank.forDate(DateTime(2026, 1, 1));
      expect(q.dayOfYear, 1);
      expect(bank.forDate(DateTime(2026, 12, 31)).dayOfYear, 365);
    });

    test('byId', () {
      expect(bank.byId('p1')?.id, 'p1');
      expect(bank.byId('no-such-id'), isNull);
    });

    test('all は365件', () {
      expect(bank.all.length, 365);
    });
  });

  test('すべての問いに、もう一歩の問いがある(短く、命令せず、「なぜ」で問わない)', () {
    for (final q in _loadFromFile()) {
      final f = q.followUp;
      expect(f, isNotNull, reason: q.id);
      expect(f!.endsWith('？'), isTrue, reason: '${q.id}: $f');
      expect(f.characters.length, lessThanOrEqualTo(30), reason: '${q.id}: $f');
      for (final w in [
        ..._forbiddenWords,
        'なぜ', 'どうして', 'してください', 'しましょう', '最期', '後悔'
      ]) {
        expect(f.contains(w), isFalse, reason: '${q.id}: $f');
      }
      expect(f, isNot(q.text), reason: q.id);
    }
  });
}
