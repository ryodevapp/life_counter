import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_counter/views/shared/app_spacing.dart';
import 'package:life_counter/views/shared/readable_width.dart';

/// LC-15: iPad で中身が横に広がりすぎないようにする部品
void main() {
  Future<double> widthOf(WidgetTester tester,
      {required double screenWidth, double textScale = 1}) async {
    const key = Key('child');
    await tester.pumpWidget(MediaQuery(
      data: MediaQueryData(
        size: Size(screenWidth, 1000),
        textScaler: TextScaler.linear(textScale),
      ),
      child: const Directionality(
        textDirection: TextDirection.ltr,
        child: ReadableWidth(child: SizedBox(key: key, height: 10)),
      ),
    ));
    return tester.getSize(find.byKey(key)).width;
  }

  testWidgets('iPhone の幅では横幅いっぱい', (tester) async {
    tester.view.physicalSize = const Size(402, 874);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    expect(await widthOf(tester, screenWidth: 402), 402);
  });

  testWidgets('iPad の幅では既定の文字で readableWidth まで', (tester) async {
    tester.view.physicalSize = const Size(1032, 1376);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    expect(await widthOf(tester, screenWidth: 1032), AppSpacing.readableWidth);
  });

  testWidgets('文字を大きくすると、その分だけ広がる(画面の幅は超えない)', (tester) async {
    tester.view.physicalSize = const Size(1032, 1376);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    expect(await widthOf(tester, screenWidth: 1032, textScale: 1.2),
        closeTo(AppSpacing.readableWidth * 1.2, 0.01));
    expect(await widthOf(tester, screenWidth: 1032, textScale: 3.1), 1032);
  });
}
