import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/question_bank_provider.dart';
import '../../providers/today_reload_provider.dart';
import '../../providers/user_settings_provider.dart';
import '../../services/notification_service.dart';
import '../shared/app_colors.dart';
import '../shared/app_spacing.dart';
import '../shared/app_text_styles.dart';
import '../shared/glass_surface.dart';
import '../today/today_page.dart';
import '../record/record_calendar_page.dart';
import '../life/life_tab_page.dart';
import '../my_page/my_page.dart';

/// 4タブのメイン画面（プロトタイプのTabBar再現）
class MainTabView extends ConsumerStatefulWidget {
  const MainTabView({super.key});

  @override
  ConsumerState<MainTabView> createState() => _MainTabViewState();
}

class _MainTabViewState extends ConsumerState<MainTabView> {
  int _currentIndex = 0;
  final _recordKey = GlobalKey<RecordCalendarPageState>();

  static const _tabs = [
    _TabItem(icon: '\u25C9', label: '今日'),    // ◉
    _TabItem(icon: '\u25A6', label: '記録'),    // ▦
    _TabItem(icon: '\u221E', label: '人生'),    // ∞
    _TabItem(icon: '\u25C7', label: 'マイページ'), // ◇
  ];

  late final _pages = [
    const TodayPage(),
    RecordCalendarPage(key: _recordKey),
    const LifeTabPage(),
    const MyPage(),
  ];

  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    // 起動のたびと、アプリに戻ったときに、朝の通知を先の60日分入れ直す
    _refreshNotifications();
    _lifecycle = AppLifecycleListener(onResume: _refreshNotifications);
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  void _refreshNotifications() {
    NotificationService.refresh(
      ref.read(userSettingsProvider),
      ref.read(questionBankProvider),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 通知の時刻・生年月日などを変えたら入れ直す
    ref.listen(userSettingsProvider, (_, _) => _refreshNotifications());
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

  /// 内容の上に浮かぶ、ガラスのカプセル型のタブバー(下の内容が透けて見える)
  Widget _buildTabBar() {
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.only(bottom: AppSpacing.m),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
        child: GlassSurface(
          borderRadius: AppRadius.full,
          padding: const EdgeInsets.all(AppSpacing.xs),
          child: Row(
            children: List.generate(_tabs.length, (i) {
              final tab = _tabs[i];
              final isActive = i == _currentIndex;
              return Expanded(
                child: Semantics(
                  button: true,
                  selected: isActive,
                  label: tab.label,
                  excludeSemantics: true,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      setState(() => _currentIndex = i);
                      if (i == 0) ref.read(todayReloadProvider.notifier).state++;
                      if (i == 1) _recordKey.currentState?.reload();
                    },
                    child: AnimatedContainer(
                      duration: AppMotion.base,
                      curve: Curves.easeOutCubic,
                      padding:
                          const EdgeInsets.symmetric(vertical: AppSpacing.s),
                      decoration: BoxDecoration(
                        // 選んだタブは、ガラスの上に控えめなアクセント色の丸を敷く
                        // (選んでいないときは同じ色の透明度0。途中で灰色にならないように)
                        color: isActive
                            ? AppColors.accentSurface2
                            : AppColors.accentSurface2.withValues(alpha: 0),
                        borderRadius: BorderRadius.circular(AppRadius.full),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            tab.icon,
                            style: AppTextStyles.headline.copyWith(
                              color: isActive
                                  ? AppColors.accent
                                  : AppColors.textMuted,
                            ),
                          ),
                          Text(
                            tab.label,
                            style: AppTextStyles.captionLabel.copyWith(
                              color: isActive
                                  ? AppColors.accent
                                  : AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
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
