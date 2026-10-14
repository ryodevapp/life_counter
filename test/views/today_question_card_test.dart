import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_counter/models/question.dart';
import 'package:life_counter/views/today/today_question_card.dart';

void main() {
  const self = Question(id: 'q1', category: 'self', text: '今日の気分は？', dayOfYear: 1);
  const bucket =
      Question(id: 'q2', category: 'bucket', text: '一度は行ってみたい場所は？', dayOfYear: 2);

  Future<void> pump(
    WidgetTester tester, {
    Question question = self,
    String answer = '',
    String? stamp,
    String? lastYear,
    ValueChanged<String?>? onStamp,
    VoidCallback? onBucket,
  }) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: TodayQuestionCard(
            question: question,
            answerController: TextEditingController(text: answer),
            selectedStampId: stamp,
            lastYearAnswer: lastYear,
            onStamp: onStamp ?? (_) {},
            onAnswerChanged: (_) {},
            onAddToBucket: onBucket,
          ),
        ),
      ),
    ));
  }

  testWidgets('tapping a stamp selects it, tapping the selected one clears it',
      (tester) async {
    final calls = <String?>[];
    await pump(tester, onStamp: calls.add);
    await tester.tap(find.text('😊'));
    await pump(tester, stamp: 'happy', onStamp: calls.add);
    await tester.tap(find.text('😊'));
    expect(calls, ['happy', null]);
  });

  testWidgets('last year answer shows only when present', (tester) async {
    await pump(tester);
    expect(find.textContaining('1年前の今日'), findsNothing);
    await pump(tester, lastYear: '海を見に行った');
    expect(find.textContaining('1年前の今日'), findsOneWidget);
    expect(find.text('海を見に行った'), findsOneWidget);
  });

  testWidgets('bucket button shows only for bucket questions with an answer',
      (tester) async {
    await pump(tester, question: self, answer: '京都', onBucket: () {});
    expect(find.text('やりたいことリストに入れる'), findsNothing);
    await pump(tester, question: bucket, answer: '', onBucket: () {});
    expect(find.text('やりたいことリストに入れる'), findsNothing);
    await pump(tester, question: bucket, answer: '京都', onBucket: () {});
    expect(find.text('やりたいことリストに入れる'), findsOneWidget);
  });

  testWidgets('no streak or count text is shown', (tester) async {
    await pump(tester, stamp: 'calm', lastYear: 'x');
    expect(find.textContaining('連続'), findsNothing);
    expect(find.textContaining('%'), findsNothing);
  });
}
