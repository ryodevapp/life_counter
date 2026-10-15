import 'package:flutter/cupertino.dart';
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
import '../shared/sliding_pill_track.dart';
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
    _TabItem(CupertinoIcons.sun_max, CupertinoIcons.sun_max_fill, '今日'),
    _TabItem(CupertinoIcons.book, CupertinoIcons.book_fill, '記録'),
    _TabItem(CupertinoIcons.heart, CupertinoIcons.heart_fill, '人生'),
    _TabItem(CupertinoIcons.gear_alt, CupertinoIcons.gear_alt_fill, '設定'),
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
              left: _barSide,
              right: _barSide,
              // ホームの印と重ならない高さに浮かべる(iOS 26 のタブバーと同じく下端から 21pt 前後)
              bottom: MediaQuery.viewPaddingOf(context).bottom > 0
                  ? _barBottom
                  : AppSpacing.m,
              child: _buildTabBar(),
            ),
        ],
      ),
    );
  }

  static const _barSide = 21.0;
  static const _barBottom = 21.0;
  static const _barHeight = 62.0;

  void _onTabSelected(int i) {
    if (i != _currentIndex) setState(() => _currentIndex = i);
    if (i == 0) ref.read(todayReloadProvider.notifier).state++;
    if (i == 1) _recordKey.currentState?.reload();
  }

  /// 内容の上に浮かぶ、ガラスのカプセル型のタブバー
  /// 選んだタブの下の明るいカプセルは、ばねで移り、動く間は伸びる。指でなぞっても選べる
  Widget _buildTabBar() {
    return SizedBox(
      height: _barHeight,
      child: GlassSurface(
        borderRadius: AppRadius.full,
        child: SlidingPillTrack(
          count: _tabs.length,
          index: _currentIndex,
          onSelect: _onTabSelected,
          pillDecoration: const ShapeDecoration(
            color: AppColors.glassPill,
            shape: StadiumBorder(
              side: BorderSide(color: AppColors.glassEdge, width: 0.5),
            ),
            shadows: [
              BoxShadow(
                color: Color(0x0F2C2520),
                offset: Offset(0, 1),
                blurRadius: 4,
              ),
            ],
          ),
          itemBuilder: (context, i, t) {
            final tab = _tabs[i];
            final color = Color.lerp(AppColors.textMuted, AppColors.accent, t);
            return Semantics(
              button: true,
              selected: i == _currentIndex,
              label: tab.label,
              excludeSemantics: true,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(t > 0.5 ? tab.activeIcon : tab.icon,
                      size: 24, color: color),
                  const SizedBox(height: 2),
                  Text(tab.label,
                      maxLines: 1, style: AppTextStyles.tab.copyWith(color: color)),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _TabItem {
  const _TabItem(this.icon, this.activeIcon, this.label);
  final IconData icon;
  final IconData activeIcon;
  final String label;
}
