import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_counter/models/question.dart';
import 'package:life_counter/models/stamp.dart';
import 'package:life_counter/views/today/today_question_card.dart';

void main() {
  const self = Question(id: 'q1', category: 'self', text: '今日の気分は？', dayOfYear: 1);
  const bucket =
      Question(id: 'q2', category: 'bucket', text: '一度は行ってみたい場所は？', dayOfYear: 2);

  Future<void> host(WidgetTester tester, Widget child) => tester.pumpWidget(
      MaterialApp(home: Scaffold(body: SingleChildScrollView(child: child))));

  group('MoodCard', () {
    testWidgets('asks how the day was and shows every mood with its label',
        (tester) async {
      await host(tester, MoodCard(selectedId: null, onSelect: (_) {}));
      expect(find.text(moodQuestion), findsOneWidget);
      for (final s in stamps) {
        expect(find.text(s.label), findsOneWidget);
      }
      // つらい日にも選べる
      expect(find.text('かなしい'), findsOneWidget);
    });

    testWidgets('tapping selects, tapping the selected one clears', (tester) async {
      final calls = <String?>[];
      await host(tester, MoodCard(selectedId: null, onSelect: calls.add));
      await tester.tap(find.text('うれしい'));
      await host(tester, MoodCard(selectedId: 'happy', onSelect: calls.add));
      await tester.tap(find.text('うれしい'));
      expect(calls, ['happy', null]);
    });
  });

  group('TodayQuestionCard', () {
    Future<void> pump(WidgetTester tester,
            {Question question = self,
            String answer = '',
            String? lastYear,
            VoidCallback? onBucket}) =>
        host(
            tester,
            TodayQuestionCard(
              question: question,
              answerController: TextEditingController(text: answer),
              lastYearAnswer: lastYear,
              onAnswerChanged: (_) {},
              onAddToBucket: onBucket,
            ));

    testWidgets('shows the question text and the mic inside the field',
        (tester) async {
      await pump(tester);
      expect(find.text('今日の気分は？'), findsOneWidget);
      expect(find.bySemanticsLabel('声で入力する'), findsOneWidget);
    });

    testWidgets('last year answer shows only when present', (tester) async {
      await pump(tester);
      expect(find.textContaining('1年前の今日'), findsNothing);
      await pump(tester, lastYear: '海を見に行った');
      expect(find.textContaining('1年前の今日'), findsOneWidget);
    });

    testWidgets('bucket button only for bucket questions with an answer',
        (tester) async {
      await pump(tester, question: self, answer: '京都', onBucket: () {});
      expect(find.textContaining('バケットリスト'), findsNothing);
      await pump(tester, question: bucket, answer: '', onBucket: () {});
      expect(find.textContaining('バケットリスト'), findsNothing);
      await pump(tester, question: bucket, answer: '京都', onBucket: () {});
      expect(find.textContaining('バケットリスト'), findsOneWidget);
    });

    testWidgets('no streak or count text is shown', (tester) async {
      await pump(tester, lastYear: 'x');
      expect(find.textContaining('連続'), findsNothing);
      expect(find.textContaining('%'), findsNothing);
    });
  });
}
