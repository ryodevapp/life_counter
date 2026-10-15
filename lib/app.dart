import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'router/app_router.dart';
import 'views/shared/app_colors.dart';
import 'views/shared/app_text_styles.dart';

class LifeCounterApp extends ConsumerWidget {
  const LifeCounterApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'LifeCounter',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: AppColors.bg,
        fontFamilyFallback: AppTextStyles.jpFallback,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.accent,
          surface: AppColors.bg,
        ),
      ),
      routerConfig: router,
    );
  }
}
