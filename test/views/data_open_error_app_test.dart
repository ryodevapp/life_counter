import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_counter/l10n/l10n.dart';
import 'package:life_counter/views/startup/data_open_error_app.dart';

void main() {
  Future<void> hostJa(WidgetTester tester, Future<void> Function() onRetry) =>
      tester.pumpWidget(MaterialApp(
          locale: const Locale('ja'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: DataOpenErrorPage(onRetry: onRetry)));

  testWidgets('explains in Japanese and retries once per tap', (tester) async {
    final done = Completer<void>();
    var calls = 0;
    await hostJa(tester, () {
      calls++;
      return done.future;
    });
    final ja = appLocalizationsFor('ja');
    expect(find.text(ja.dataOpenErrorTitle), findsOneWidget);
    expect(find.text(ja.dataOpenErrorMessage), findsOneWidget);

    await tester.tap(find.text(ja.retry));
    await tester.pump();
    // 試している間は押せない
    await tester.tap(find.text(ja.retry));
    await tester.pump();
    expect(calls, 1);

    done.complete();
    await tester.pumpAndSettle();
    await tester.tap(find.text(ja.retry));
    await tester.pump();
    expect(calls, 2);
  });

  testWidgets('the standalone app shows English on a non-Japanese device',
      (tester) async {
    await tester.pumpWidget(DataOpenErrorApp(onRetry: () async {}));
    await tester.pumpAndSettle();
    final en = appLocalizationsFor('en');
    expect(find.text(en.dataOpenErrorTitle), findsOneWidget);
    expect(find.text(en.retry), findsOneWidget);
  });
}
