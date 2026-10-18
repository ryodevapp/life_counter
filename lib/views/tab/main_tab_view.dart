import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';
import '../../l10n/l10n.dart';
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

  static List<_TabItem> _tabs(AppLocalizations l) => [
        _TabItem(CupertinoIcons.sun_max, CupertinoIcons.sun_max_fill, l.tabToday),
        _TabItem(CupertinoIcons.book, CupertinoIcons.book_fill, l.tabJournal),
        _TabItem(CupertinoIcons.heart, CupertinoIcons.heart_fill, l.tabLife),
        _TabItem(
            CupertinoIcons.gear_alt, CupertinoIcons.gear_alt_fill, l.tabSettings),
      ];

  late final _pages = [
    const TodayPage(),
    RecordCalendarPage(key: _recordKey),
    const LifeTabPage(),
    const MyPage(),
  ];

  late final AppLifecycleListener _lifecycle;

  /// 通知の題に使う言語(画面と同じ)
  String? _languageCode;

  @override
  void initState() {
    super.initState();
    // 起動のたび(didChangeDependencies)と、アプリに戻ったときに、朝の通知を先の60日分入れ直す
    _lifecycle = AppLifecycleListener(onResume: _refreshNotifications);
    // ウィジェットから開いたとき(lifecounter://answer?homeWidget)
    HomeWidget.initiallyLaunchedFromHomeWidget().then(_onWidgetLink);
    _widgetLinks = HomeWidget.widgetClicked.listen(_onWidgetLink);
  }

  StreamSubscription<Uri?>? _widgetLinks;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 言語が決まったら(と、端末の言語が変わったら)通知を入れ直す
    final code = Localizations.localeOf(context).languageCode;
    if (code != _languageCode) {
      _languageCode = code;
      _refreshNotifications();
    }
  }

  void _onWidgetLink(Uri? uri) {
    if (!mounted || uri == null || uri.host != 'answer') return;
    setState(() => _currentIndex = 0);
    ref.read(answerFocusRequestProvider.notifier).state++;
  }

  @override
  void dispose() {
    _widgetLinks?.cancel();
    _lifecycle.dispose();
    super.dispose();
  }

  void _refreshNotifications() {
    NotificationService.refresh(
      ref.read(userSettingsProvider),
      ref.read(questionBankProvider),
      languageCode: _languageCode ?? 'ja',
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
            // キーボードが出ている間は、その上の「完了」の帯の分も空ける
            bottom: bottomInset > 0 ? bottomInset + _doneBarHeight : 0,
            child: IndexedStack(
              index: _currentIndex,
              children: _pages,
            ),
          ),
          // キーボードを閉じる「完了」(iOS の入力欄の上に出る帯と同じ形)。複数行の欄は改行キーで閉じられないため
          if (bottomInset > 0)
            Positioned(
              left: 0,
              right: 0,
              bottom: bottomInset,
              child: const _KeyboardDoneBar(height: _doneBarHeight),
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

  static const _doneBarHeight = 44.0;
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
    final tabs = _tabs(context.l10n);
    // iOS のタブバーと同じく、文字の設定を大きくしてもタブの文字は大きくしない
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: AppTextStyles.tabMaxTextScale,
      child: SizedBox(
        height: _barHeight,
        child: GlassSurface(
          borderRadius: AppRadius.full,
          child: SlidingPillTrack(
            count: tabs.length,
            index: _currentIndex,
            onSelect: _onTabSelected,
            pillDecoration: ShapeDecoration(
              color: AppColors.glassPill,
              shape: StadiumBorder(
                side: BorderSide(color: AppColors.glassEdge, width: 0.5),
              ),
              shadows: [
                BoxShadow(
                  color: AppColors.faintShadow,
                  offset: Offset(0, 1),
                  blurRadius: 4,
                ),
              ],
            ),
            itemBuilder: (context, i, t) {
              final tab = tabs[i];
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

class _KeyboardDoneBar extends StatelessWidget {
  const _KeyboardDoneBar({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: AppColors.bgSub,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s),
      alignment: Alignment.centerRight,
      child: Semantics(
        button: true,
        label: context.l10n.hideKeyboard,
        excludeSemantics: true,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.m, vertical: AppSpacing.s),
            child: Text(context.l10n.done,
                style: AppTextStyles.headline.copyWith(color: AppColors.accent)),
          ),
        ),
      ),
    );
  }
}
