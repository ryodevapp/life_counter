import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:life_counter/app.dart';
import 'package:life_counter/providers/user_settings_provider.dart';

void main() {
  testWidgets('App starts and shows onboarding for new user',
      (WidgetTester tester) async {
    // iPhone SE相当のサイズに設定
    tester.view.physicalSize = const Size(750, 1334);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() => tester.view.resetPhysicalSize());
    // 端末の言語を日本語にする(画面の言葉を日本語で確かめる)
    tester.platformDispatcher.localesTestValue = const [Locale('ja', 'JP')];
    tester.platformDispatcher.localeTestValue = const Locale('ja', 'JP');
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    addTearDown(tester.platformDispatcher.clearLocaleTestValue);

    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const LifeCounterApp(),
      ),
    );
    await tester.pump();

    expect(find.text('はじめる'), findsOneWidget);
    expect(find.text('LIFE COUNTER'), findsOneWidget);
  });

  testWidgets('English on a device in any language other than Japanese',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(750, 1334);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() => tester.view.resetPhysicalSize());
    tester.platformDispatcher.localesTestValue = const [Locale('fr', 'FR')];
    tester.platformDispatcher.localeTestValue = const Locale('fr', 'FR');
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    addTearDown(tester.platformDispatcher.clearLocaleTestValue);

    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const LifeCounterApp(),
      ),
    );
    await tester.pump();

    expect(find.text('Get Started'), findsOneWidget);
    expect(find.text('はじめる'), findsNothing);
  });
}
