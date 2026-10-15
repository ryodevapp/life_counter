import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:intl/intl.dart';
import '../../models/daily_record.dart';
import '../../models/question.dart';
import '../../providers/isar_provider.dart';
import '../../providers/question_bank_provider.dart';
import '../../providers/today_reload_provider.dart';
import '../../providers/user_settings_provider.dart';
import '../../services/morning_schedule.dart';
import '../../services/widget_sync.dart';
import '../../utils/date_only.dart';
import '../../utils/prefs_keys.dart';
import '../shared/app_colors.dart';
import '../shared/app_spacing.dart';
import '../shared/app_text_styles.dart';
import '../shared/app_toast.dart';
import 'today_question_card.dart';

class TodayPage extends ConsumerStatefulWidget {
  const TodayPage({super.key});

  @override
  ConsumerState<TodayPage> createState() => _TodayPageState();
}

class _TodayPageState extends ConsumerState<TodayPage> {
  final _answerController = TextEditingController();
  final _answerFocus = FocusNode();

  /// 画面に出している日。保存はいつもこの日に付ける(真夜中をまたいでも前日の問いに付く)
  DateTime _date = dateOnly(DateTime.now());
  late Question _question;
  String? _stampId;
  String? _lastYearAnswer;

  /// 答える欄を書き換えて、まだ保存していない
  bool _dirty = false;

  /// 入力中に0時を過ぎたので、欄から離れたら切り替える
  bool _switchPending = false;

  Timer? _idleTimer;
  Timer? _midnightTimer;
  late final AppLifecycleListener _lifecycleListener;

  @override
  void initState() {
    super.initState();
    _question = ref.read(questionBankProvider).forDate(_date);
    _syncWidget();
    _scheduleMidnight();
    _checkReviewTiming();

    // フォーカスが外れた時に保存
    _answerFocus.addListener(() {
      if (_answerFocus.hasFocus) return;
      _saveAnswer();
      if (_switchPending) _switchDayIfNeeded();
    });

    _lifecycleListener = AppLifecycleListener(
      onStateChange: (state) {
        // アプリがバックグラウンドに移行した時に保存
        if (state == AppLifecycleState.inactive ||
            state == AppLifecycleState.paused) {
          _saveAnswer();
        }
        // 戻ってきたら、日付の切り替えと、ウィジェットで押したスタンプを取り込む
        if (state == AppLifecycleState.resumed) {
          _switchDayIfNeeded().then((_) => _syncWidget());
        }
      },
    );
  }

  static bool _hasEntry(DailyRecord r) =>
      r.stamp != null ||
      r.answer != null ||
      r.reflectionGood != null ||
      r.tomorrowMessage != null;

  /// レビュー依頼のタイミングをチェック
  Future<void> _checkReviewTiming() async {
    try {
      final prefs = ref.read(sharedPreferencesProvider);
      final repo = ref.read(dailyRecordRepositoryProvider);

      // 前日に記録があるか確認
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final yesterdayRecord = await repo.getByDate(yesterday);
      if (yesterdayRecord == null || !_hasEntry(yesterdayRecord)) return;

      // 記録がある日数をカウント
      final allRecords = await repo.getAll();
      final eveningDays = allRecords.where(_hasEntry).length;

      final alreadyDay2 = prefs.getBool(PrefsKeys.reviewRequestedDay2) ?? false;
      final alreadyDay7 = prefs.getBool(PrefsKeys.reviewRequestedDay7) ?? false;

      bool shouldRequest = false;

      // Day 2: 記録が2日以上 & まだ表示していない
      if (eveningDays >= 2 && !alreadyDay2) {
        await prefs.setBool(PrefsKeys.reviewRequestedDay2, true);
        shouldRequest = true;
      }
      // Day 7: 記録が7日以上 & まだ表示していない
      else if (eveningDays >= 7 && !alreadyDay7) {
        await prefs.setBool(PrefsKeys.reviewRequestedDay7, true);
        shouldRequest = true;
      }

      if (shouldRequest) {
        final inAppReview = InAppReview.instance;
        if (await inAppReview.isAvailable()) {
          // 少し遅延させて、画面が落ち着いてから表示
          await Future.delayed(const Duration(seconds: 2));
          if (mounted) {
            await inAppReview.requestReview();
          }
        }
      }
    } catch (e) {
      debugPrint('Review check error: $e');
    }
  }

  /// 画面の日の問い・スタンプ・答え・1年前の答えを読む
  Future<void> _loadDay() async {
    try {
      final repo = ref.read(dailyRecordRepositoryProvider);
      final date = _date;
      final record = await repo.getByDate(date);
      final lastYear = await repo.getOneYearAgo(date);
      if (!mounted || date != _date) return;
      setState(() {
        _stampId = record?.stamp;
        // 入力中の文は上書きしない
        if (!_dirty && !_answerFocus.hasFocus) {
          _answerController.text = record?.answer ?? '';
        }
        // 1年前の答えは、同じ問いに答えていたときだけ出す
        _lastYearAnswer = lastYear?.morningQuestionId == _question.id
            ? lastYear?.answer
            : null;
      });
    } catch (e) {
      debugPrint('Today record load error: $e');
    }
  }

  /// ウィジェットで押したスタンプを取り込み、画面とウィジェットを今の状態にそろえる
  Future<void> _syncWidget() async {
    final bank = ref.read(questionBankProvider);
    await WidgetSync.importPending(
      ref.read(dailyRecordRepositoryProvider),
      bank,
    );
    await _loadDay();
    await WidgetSync.update(
      birthDate: ref.read(userSettingsProvider).birthDate,
      bank: bank,
      todayStampId: _stampId,
    );
  }

  void _scheduleMidnight() {
    _midnightTimer?.cancel();
    final now = DateTime.now();
    final next = DateTime(now.year, now.month, now.day + 1);
    _midnightTimer = Timer(
      next.difference(now) + const Duration(seconds: 1),
      _switchDayIfNeeded,
    );
  }

  Future<void> _switchDayIfNeeded() async {
    final today = dateOnly(DateTime.now());
    if (today == _date) return;
    // 入力中なら、欄から離れるまで待つ(書いている途中で欄が空にならないように)
    if (_answerFocus.hasFocus) {
      _switchPending = true;
      return;
    }
    _switchPending = false;
    await _saveAnswer();
    if (!mounted) return;
    setState(() {
      _date = today;
      _question = ref.read(questionBankProvider).forDate(today);
      _stampId = null;
      _lastYearAnswer = null;
      _answerController.clear();
    });
    _scheduleMidnight();
    await _loadDay();
  }

  // 入力変更時: 2秒アイドルで保存
  void _onAnswerChanged(String _) {
    _dirty = true;
    _idleTimer?.cancel();
    _idleTimer = Timer(const Duration(milliseconds: 2000), () {
      if (mounted) _saveAnswer();
    });
    setState(() {}); // 「やりたいことリストに入れる」の出し入れのため
  }

  /// 書き換えたときだけ保存する(ほかの画面で直した答えを、古い文で上書きしないように)
  Future<void> _saveAnswer() async {
    _idleTimer?.cancel();
    if (!_dirty) return;
    _dirty = false;
    try {
      await ref
          .read(dailyRecordRepositoryProvider)
          .setAnswer(_date, _answerController.text, questionId: _question.id);
    } catch (e) {
      _dirty = true; // 次の機会にもう一度保存する
      debugPrint('Auto save error: $e');
    }
  }

  Future<void> _onStamp(String? stampId) async {
    setState(() => _stampId = stampId);
    try {
      await ref
          .read(dailyRecordRepositoryProvider)
          .setStamp(_date, stampId, questionId: _question.id);
      await WidgetSync.update(
        birthDate: ref.read(userSettingsProvider).birthDate,
        bank: ref.read(questionBankProvider),
        todayStampId: stampId,
      );
    } catch (e) {
      debugPrint('Stamp save error: $e');
    }
  }

  Future<void> _addToBucket() async {
    final title = _answerController.text.trim();
    if (title.isEmpty) return;
    final added = await ref
        .read(bucketItemRepositoryProvider)
        .add(title, sourceQuestionId: _question.id);
    if (!mounted) return;
    AppToast.success(
      context,
      added ? 'バケットリストに追加しました' : 'もうバケットリストにあります',
    );
  }

  @override
  void dispose() {
    _idleTimer?.cancel();
    _midnightTimer?.cancel();
    _lifecycleListener.dispose();
    _answerFocus.dispose();
    _answerController.dispose();
    super.dispose();
  }

  static final _counterWord =
      AppTextStyles.body.copyWith(color: AppColors.textMuted);

  @override
  Widget build(BuildContext context) {
    // 今日タブに戻ったら、ほかの画面で直した答えを読み直す(入力中は上書きしない)
    ref.listen(todayReloadProvider, (_, _) => _loadDay());
    // ウィジェットの「書く」から開いたら、答えの欄にキーボードを出す
    ref.listen(answerFocusRequestProvider, (_, _) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _answerFocus.requestFocus();
      });
    });
    final settings = ref.watch(userSettingsProvider);
    final birthDate = settings.birthDate;
    if (birthDate == null) {
      return Center(
          child: Text('生年月日を入れると表示されます',
              style: AppTextStyles.callout
                  .copyWith(color: AppColors.textMuted)));
    }

    final lifeDays = lifeDaysOn(birthDate, _date);
    final formatter = NumberFormat('#,###', 'ja_JP');
    final now = _date;
    final dateStr =
        '${now.year}年${now.month}月${now.day}日（${DateFormat.E('ja_JP').format(now)}）';

    return SafeArea(
      child: SingleChildScrollView(
        // 下へなぞるとキーボードが閉じる
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screen,
          AppSpacing.l,
          AppSpacing.screen,
          130,
        ),
        child: Column(
          children: [
            // いちばん上: 人生の日数 + 日付
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xl),
              child: Column(
                children: [
                  // 日付 → 「人生 12,616 日目」(数字の下の線に、前後の言葉を揃える)
                  Text(dateStr, style: AppTextStyles.footnote),
                  const SizedBox(height: AppSpacing.s),
                  Text.rich(
                    TextSpan(children: [
                      TextSpan(text: '人生 ', style: _counterWord),
                      TextSpan(
                          text: formatter.format(lifeDays),
                          style: AppTextStyles.counter),
                      TextSpan(text: ' 日目', style: _counterWord),
                    ]),
                  ),
                ],
              ),
            ),

            MoodCard(selectedId: _stampId, onSelect: _onStamp),
            const SizedBox(height: AppSpacing.cardGap),
            TodayQuestionCard(
              question: _question,
              answerController: _answerController,
              answerFocus: _answerFocus,
              lastYearAnswer: _lastYearAnswer,
              onAnswerChanged: _onAnswerChanged,
              onAddToBucket: _addToBucket,
            ),
          ],
        ),
      ),
    );
  }
}
