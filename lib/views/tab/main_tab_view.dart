import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/user_settings_provider.dart';
import '../../services/notification_service.dart';
import '../../services/pro_service.dart';
import '../../providers/important_person_provider.dart';
import '../../providers/isar_provider.dart';
import '../../services/widget_sync.dart';
import '../../utils/prefs_keys.dart';
import '../family/family_page.dart';
import '../shared/app_colors.dart';
import '../records/records_page.dart';
import '../my_page/my_page.dart';

/// 3タブのメイン画面（家族・記録・設定）
class MainTabView extends ConsumerStatefulWidget {
  const MainTabView({super.key});

  @override
  ConsumerState<MainTabView> createState() => _MainTabViewState();
}

class _MainTabViewState extends ConsumerState<MainTabView> {
  @override
  void initState() {
    super.initState();
    // 起動のたびに、これから1週間分の通知を入れ直す（日数と問いかけを毎日変えるため）
    NotificationService.refresh(ref.read(userSettingsProvider));
    // 購入の受け取り(ファミリー共有・中断した購入の完了)のため、起動時に Pro の監視を始める
    ref.read(proProvider);
  }

  int _currentIndex = 0;

  static const _tabs = [
    _TabItem(icon: '\u2661', label: '家族'),    // ♡
    _TabItem(icon: '\u25A6', label: '記録'),    // ▦
    _TabItem(icon: '\u25C7', label: '設定'),    // ◇
  ];

  late final _pages = [
    const FamilyPage(),
    const RecordsPage(),
    const MyPage(),
  ];

  @override
  Widget build(BuildContext context) {
    // 家族・記録・見た目が変わったら、ウィジェットを更新する
    void syncWidget() {
      final persons = ref.read(importantPersonsProvider).valueOrNull;
      final logs = ref.read(meetingLogsProvider).valueOrNull;
      if (persons == null || logs == null) return;
      final prefs = ref.read(sharedPreferencesProvider);
      final pro = ref.read(proProvider);
      var style = prefs.getString(PrefsKeys.widgetStyle) ?? 'warm';
      if (!pro.isPro && style != 'warm') style = 'warm';
      WidgetSync.update(persons: persons, logs: logs, style: style);
    }
    ref.listen(importantPersonsProvider, (_, _) => syncWidget());
    ref.listen(meetingLogsProvider, (_, _) => syncWidget());
    ref.listen(proProvider.select((p) => p.isPro), (_, _) => syncWidget());

    // 家族や通知の設定が変わったら、節目の通知を入れ直す
    ref.listen(importantPersonsProvider, (_, next) {
      final persons = next.valueOrNull;
      if (persons != null) {
        NotificationService.refreshMilestones(ref.read(userSettingsProvider), persons);
      }
    });
    ref.listen(userSettingsProvider.select((s) => s.notificationEnabled), (_, _) {
      final persons = ref.read(importantPersonsProvider).valueOrNull;
      if (persons != null) {
        NotificationService.refreshMilestones(ref.read(userSettingsProvider), persons);
      }
    });
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Scaffold(
      backgroundColor: AppColors.bg,
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          Positioned.fill(
            bottom: bottomInset,
            child: IndexedStack(
              index: _currentIndex,
              children: _pages,
            ),
          ),
          if (bottomInset == 0)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildTabBar(),
            ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.bg.withValues(alpha: 0.0),
            AppColors.bg,
          ],
          stops: const [0.0, 0.25],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 30),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
          boxShadow: AppColors.cardShadow,
        ),
        child: Row(
          children: List.generate(_tabs.length, (i) {
            final tab = _tabs[i];
            final isActive = i == _currentIndex;
            return Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => setState(() => _currentIndex = i),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        tab.icon,
                        style: TextStyle(
                          fontSize: 16,
                          color: isActive
                              ? AppColors.accent
                              : AppColors.textDisabled,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        tab.label,
                        style: GoogleFonts.zenKakuGothicNew(
                          fontSize: 11,
                          fontWeight:
                              isActive ? FontWeight.w600 : FontWeight.w400,
                          color: isActive
                              ? AppColors.accent
                              : AppColors.textDisabled,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _TabItem {
  const _TabItem({required this.icon, required this.label});
  final String icon;
  final String label;
}
