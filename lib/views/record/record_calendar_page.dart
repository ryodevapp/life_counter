import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../l10n/l10n.dart';
import '../../models/daily_record.dart';
import '../../models/question.dart';
import '../../models/stamp.dart';
import 'reflection_view.dart';
import '../../providers/isar_provider.dart';
import '../../providers/question_bank_provider.dart';
import '../../providers/user_settings_provider.dart';
import '../../services/widget_sync.dart';
import '../../utils/date_only.dart';
import '../shared/action_buttons.dart';
import '../today/today_question_card.dart' show MoodPicker;
import '../shared/app_colors.dart';
import '../shared/app_spacing.dart';
import '../shared/readable_width.dart';
import '../shared/app_text_styles.dart';
import '../shared/mood_face.dart';
import '../shared/mood_shape.dart';
import '../shared/app_card.dart';
import '../shared/app_input.dart';
import '../shared/expandable_text.dart';
import '../shared/app_segmented_control.dart';
import '../shared/page_header.dart';

/// 記録タブ（プロトタイプの RecordsTab 再現）
class RecordCalendarPage extends ConsumerStatefulWidget {
  const RecordCalendarPage({super.key});

  @override
  RecordCalendarPageState createState() => RecordCalendarPageState();
}

enum _RecordView { calendar, list }

class RecordCalendarPageState extends ConsumerState<RecordCalendarPage> {
  _RecordView _view = _RecordView.list;
  DateTime _focusedDay = DateTime.now();
  DailyRecord? _selectedRecord;
  List<DailyRecord> _records = [];
  int? _editingRecordId;

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  /// 外部からデータ再読み込みを呼び出す
  void reload() => _loadRecords();

  Future<void> _loadRecords() async {
    final repo = ref.read(dailyRecordRepositoryProvider);
    final records = await repo.getAll();
    if (mounted) setState(() => _records = records);
  }

  /// 記録がある日 → その日の記録
  Map<DateTime, DailyRecord> get _recordsByDate => {
        for (final r in _records.where(_hasContent))
          r.day: r,
      };

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return SafeArea(
      child: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.screen, AppSpacing.l, AppSpacing.screen, 130),
        child: ReadableWidth(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PageHeader(l.tabJournal),
              AppSegmentedControl<_RecordView>(
                items: [
                  SegmentItem(value: _RecordView.list, label: l.viewList),
                  SegmentItem(value: _RecordView.calendar, label: l.viewCalendar),
                ],
                selectedValue: _view,
                onChanged: (v) => setState(() => _view = v),
              ),
              const SizedBox(height: AppSpacing.xl),
              if (_view == _RecordView.calendar) ...[
                _buildCalendar(),
                if (_selectedRecord != null) ...[
                  const SizedBox(height: AppSpacing.cardGap),
                  _buildSelectedRecordCard(),
                ],
              ] else
                _buildList(),
            ],
          ),
        ),
      ),
    );
  }

  /// カレンダーで選択した日の記録カード(一覧と同じカード・同じ編集)
  Widget _buildSelectedRecordCard() => _recordCard(_selectedRecord!, inCalendar: true);

  /// 記録を書き換えたあと: 一覧を読み直し、今日の分ならウィジェットにも伝える
  Future<void> _afterChange(DailyRecord? updated, DateTime date) async {
    if (dateOnly(date) == dateOnly(DateTime.now())) {
      await WidgetSync.update(
        birthDate: ref.read(userSettingsProvider).birthDate,
        bank: ref.read(questionBankProvider),
        todayStampId: updated?.stamp,
      );
    }
    await _loadRecords();
  }

  /// 一覧とカレンダーで共通の、1日分のカード(見るとき・直すとき)
  Widget _recordCard(DailyRecord r, {bool inCalendar = false}) {
    if (_editingRecordId == r.id) {
      return _InlineEditCard(
        record: r,
        onSave: (updated) async {
          await ref.read(dailyRecordRepositoryProvider).save(updated);
          if (!mounted) return;
          setState(() {
            _editingRecordId = null;
            if (inCalendar) _selectedRecord = updated;
          });
          await _afterChange(updated, updated.day);
        },
        onDelete: () async {
          await ref.read(dailyRecordRepositoryProvider).delete(r.id);
          if (!mounted) return;
          setState(() {
            _editingRecordId = null;
            if (inCalendar) _selectedRecord = null;
          });
          await _afterChange(null, r.day);
        },
        onCancel: () => setState(() => _editingRecordId = null),
      );
    }
    return AppCard(
      // 右上の編集ボタンは押せる範囲 44 の分だけ上と右が膨らむので、そこだけ余白を詰めて上下を揃える
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.card, AppSpacing.s, AppSpacing.s, AppSpacing.card),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ..._buildCardHeader(r),
          const SizedBox(height: AppSpacing.s),
          ..._buildInlineFields(r),
        ],
      ),
    );
  }

  /// カードの頭: 日付・その日の気分の札・編集のボタン
  /// 大きい文字では横に入らないので、日付と編集を1行目、気分の札を2行目に積む
  List<Widget> _buildCardHeader(DailyRecord r) {
    final date = Text(_formatDate(r.day), style: AppTextStyles.headline);
    final edit =
        _EditIconButton(onTap: () => setState(() => _editingRecordId = r.id));
    // その日の気分は、日付の横に小さな札で(問いの文は重ねない)
    final mood = stampById(r.stamp);
    final tag = mood == null
        ? null
        : _MoodTag(moodId: mood.id, label: moodLabel(context, mood.id));
    if (AppTextStyles.isAccessibilitySize(context)) {
      return [
        Row(children: [Expanded(child: date), edit]),
        ?tag,
      ];
    }
    return [
      Row(
        children: [
          date,
          if (tag != null) ...[const SizedBox(width: AppSpacing.s), tag],
          const Spacer(),
          edit,
        ],
      ),
    ];
  }

  Widget _buildCalendar() {
    return AppCard(
      // 日付の並びは枠の大きさが決まっていて、本文と同じ3倍では数字が割れて読めない。
      // iOS のカレンダーと同じく、並びの文字は大きくしすぎない(1.3倍まで)
      child: MediaQuery.withClampedTextScaling(
        maxScaleFactor: 1.3,
        child: TableCalendar(
        firstDay: DateTime(2020),
        lastDay: DateTime.now(),
        focusedDay: _focusedDay,
        locale: intlLocaleOf(context.l10n.localeName),
        startingDayOfWeek: StartingDayOfWeek.sunday,
        // 曜日の行の高さは決まった値(16)なので、文字を大きくすると下が欠ける。倍率に合わせて伸ばす
        daysOfWeekHeight: MediaQuery.textScalerOf(context)
            .clamp(maxScaleFactor: 1.3)
            .scale(20),
        headerStyle: HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          titleTextStyle: AppTextStyles.headline,
        ),
        calendarStyle: CalendarStyle(
          outsideDaysVisible: false,
          todayDecoration: BoxDecoration(
            color: AppColors.accentSurface2,
            shape: BoxShape.circle,
          ),
          todayTextStyle:
              AppTextStyles.footnote.copyWith(color: AppColors.accent),
          defaultTextStyle:
              AppTextStyles.footnote.copyWith(color: AppColors.text),
          weekendTextStyle:
              AppTextStyles.footnote.copyWith(color: AppColors.text),
          markerDecoration: BoxDecoration(
            color: AppColors.accent,
            shape: BoxShape.circle,
          ),
          markerSize: 5,
          markersMaxCount: 1,
        ),
        daysOfWeekStyle: DaysOfWeekStyle(
          weekdayStyle: AppTextStyles.captionLabel,
          weekendStyle: AppTextStyles.captionLabel,
        ),
        eventLoader: (day) {
          final normalized = DateTime(day.year, day.month, day.day);
          final r = _recordsByDate[normalized];
          return r == null ? [] : [r];
        },
        calendarBuilders: CalendarBuilders(
          // スタンプがある日はその絵、ない日は点
          markerBuilder: (context, day, events) {
            if (events.isEmpty) return null;
            final stamp = stampById((events.first as DailyRecord).stamp);
            if (stamp == null) return null;
            return Positioned(
              bottom: 0,
              // 気分は、日付の下の小さな色の点で(この大きさでは顔は読めないので)
              child: Container(
                width: 7,
                height: 7,
                margin: const EdgeInsets.only(bottom: 4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: moodLooks[stamp.id]?.deep,
                ),
              ),
            );
          },
        ),
        onDaySelected: (selected, focused) async {
          final repo = ref.read(dailyRecordRepositoryProvider);
          final record = await repo.getOrCreate(selected);
          if (mounted) {
            setState(() {
              _selectedRecord = record;
              _editingRecordId = null;
            });
          }
        },
        onPageChanged: (focused) => _focusedDay = focused,
        ),
      ),
    );
  }

  bool _hasContent(DailyRecord r) {
    return r.stamp != null ||
        r.answer != null ||
        r.gratitude != null ||
        r.todayGoal != null ||
        r.reflectionGood != null ||
        r.tomorrowMessage != null ||
        r.reflectionWhy != null ||
        r.reflectionTomorrow != null ||
        r.weeklyReflectionHighlight != null ||
        r.weeklyReflectionChange != null;
  }

  Widget _buildList() {
    final filtered = _records.where((r) => _hasContent(r)).toList();
    if (filtered.isEmpty) {
      return AppCard(
        child: Text(
          context.l10n.noEntriesYet,
          textAlign: TextAlign.center,
          style: AppTextStyles.callout.copyWith(color: AppColors.textMuted),
        ),
      );
    }
    // 新しい順。月が変わるところに月の見出し(気分の内訳つき)を入れる。いちばん上に1年前の今日
    final children = <Widget>[LastYearCard(records: _records)];
    DateTime? month;
    for (final r in filtered) {
      final m = DateTime(r.day.year, r.day.month);
      if (m != month) {
        if (month != null) {
          children.add(const SizedBox(height: AppSpacing.l));
        }
        month = m;
        children.add(MonthHeader(
          month: m,
          records: filtered
              .where((x) => x.day.year == m.year && x.day.month == m.month)
              .toList(),
        ));
      }
      children.add(_listItem(r));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
  }

  /// 一覧の1日分。左へスワイプすると消せる(確かめてから。編集中は動かさない)
  Widget _listItem(DailyRecord r) {
    final l = context.l10n;
    final card = Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.cardGap),
      child: _recordCard(r),
    );
    if (_editingRecordId == r.id) return card;
    return Dismissible(
      key: ValueKey('record-${r.id}'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => showDeleteConfirmation(
        context,
        title: l.deleteDayTitle(_formatDate(r.day)),
      ),
      onDismissed: (_) async {
        setState(() => _records.removeWhere((x) => x.id == r.id));
        await ref.read(dailyRecordRepositoryProvider).delete(r.id);
        await _afterChange(null, r.day);
      },
      background: Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.cardGap),
        child: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: AppSpacing.xl),
          decoration: BoxDecoration(
            color: AppColors.danger,
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: Icon(CupertinoIcons.trash, color: AppColors.onAccent),
        ),
      ),
      child: card,
    );
  }

  String _formatDate(DateTime date) =>
      formatMonthDayWeekday(date, context.l10n.localeName);

  List<Widget> _buildInlineFields(DailyRecord r) {
    final l = context.l10n;
    final fields = <(String, String)>[];
    // 今日の問いへの答えは、問いの文を見出しにする(何への答えかが分かるように)
    if (r.answer != null) {
      final q = r.morningQuestionId == null
          ? null
          : ref.read(questionBankProvider).byId(r.morningQuestionId!);
      fields.add((q == null ? l.todaysQuestion : questionWithFollowUp(q), r.answer!));
    }
    if (r.gratitude != null) fields.add((l.fieldGratitude, r.gratitude!));
    if (r.todayGoal != null) fields.add((l.fieldTodayPlan, r.todayGoal!));
    if (r.reflectionGood != null) fields.add((l.fieldGoodThing, r.reflectionGood!));
    if (r.tomorrowMessage != null) fields.add((l.fieldTomorrowMessage, r.tomorrowMessage!));
    if (r.reflectionWhy != null) fields.add((l.fieldReason, r.reflectionWhy!));
    if (r.reflectionTomorrow != null) fields.add((l.fieldTomorrowJoy, r.reflectionTomorrow!));
    if (r.weeklyReflectionHighlight != null) fields.add((l.fieldWeeklyHighlight, r.weeklyReflectionHighlight!));
    if (r.weeklyReflectionChange != null) fields.add((l.fieldWeeklyChange, r.weeklyReflectionChange!));

    if (fields.isEmpty) {
      return [
        if (r.stamp == null) Text(l.noEntry, style: AppTextStyles.footnote),
      ];
    }

    return [
      ...fields.asMap().entries.map((entry) {
      final isLast = entry.key == fields.length - 1;
      return Padding(
        padding: EdgeInsets.only(bottom: isLast ? 0 : AppSpacing.m),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(entry.value.$1, style: AppTextStyles.captionLabel),
            const SizedBox(height: AppSpacing.xs),
            // 長い答えは5行まで。続きはその場で全文に広げて読める(省略したまま読めない作りにしない)
            ExpandableText(entry.value.$2, style: AppTextStyles.callout),
          ],
        ),
      );
    }),
    ];
  }
}

/// カード内インライン編集ウィジェット
class _InlineEditCard extends ConsumerStatefulWidget {
  const _InlineEditCard({
    required this.record,
    required this.onSave,
    required this.onDelete,
    required this.onCancel,
  });

  final DailyRecord record;
  final Future<void> Function(DailyRecord) onSave;
  final Future<void> Function() onDelete;
  final VoidCallback onCancel;

  @override
  ConsumerState<_InlineEditCard> createState() => _InlineEditCardState();
}

class _InlineEditCardState extends ConsumerState<_InlineEditCard> {
  late final TextEditingController _answerCtrl;
  late final TextEditingController _gratitudeCtrl;
  late final TextEditingController _goalCtrl;
  late final TextEditingController _goodCtrl;
  late final TextEditingController _tomorrowMsgCtrl;
  /// 編集中の気分(押したらここだけ変わり、保存で書く)
  String? _stampId;

  /// v1.0 系の4つの欄のどれかがある記録だけ、その欄を編集に出す
  bool get _hasDiaryFields =>
      widget.record.gratitude != null ||
      widget.record.todayGoal != null ||
      widget.record.reflectionGood != null ||
      widget.record.tomorrowMessage != null;

  @override
  void initState() {
    super.initState();
    _stampId = widget.record.stamp;
    _answerCtrl = TextEditingController(text: widget.record.answer ?? '');
    _gratitudeCtrl = TextEditingController(text: widget.record.gratitude ?? '');
    _goalCtrl = TextEditingController(text: widget.record.todayGoal ?? '');
    _goodCtrl = TextEditingController(text: widget.record.reflectionGood ?? '');
    _tomorrowMsgCtrl = TextEditingController(text: widget.record.tomorrowMessage ?? '');
  }

  @override
  void dispose() {
    _answerCtrl.dispose();
    _gratitudeCtrl.dispose();
    _goalCtrl.dispose();
    _goodCtrl.dispose();
    _tomorrowMsgCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    // 開いてからほかの画面やウィジェットで変わった項目(スタンプなど)を消さないよう、読み直してから書く
    final r = await ref
            .read(dailyRecordRepositoryProvider)
            .getByDate(widget.record.day) ??
        widget.record;
    r.morningQuestionId ??= ref.read(questionBankProvider).forDate(r.day).id;
    if (_stampId != r.stamp) {
      r.stamp = _stampId;
      // ウィジェットで押した気分と比べるときの時刻(あとで直したほうを残す)
      r.stampAt = DateTime.now();
    }
    r.answer = _answerCtrl.text.trim().isNotEmpty ? _answerCtrl.text : null;
    r.gratitude = _gratitudeCtrl.text.isNotEmpty ? _gratitudeCtrl.text : null;
    r.todayGoal = _goalCtrl.text.isNotEmpty ? _goalCtrl.text : null;
    r.reflectionGood = _goodCtrl.text.isNotEmpty ? _goodCtrl.text : null;
    r.tomorrowMessage = _tomorrowMsgCtrl.text.isNotEmpty ? _tomorrowMsgCtrl.text : null;
    await widget.onSave(r);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final dateStr = formatMonthDayWeekday(widget.record.day, l.localeName);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 大きい文字では日付とボタンが横に入らないので、日付の下にボタンを置く
          Flex(
            direction: AppTextStyles.isAccessibilitySize(context)
                ? Axis.vertical
                : Axis.horizontal,
            // 縦のときは高さを中身に合わせる(カードの Column の中で高さが決まらないため)
            mainAxisSize: AppTextStyles.isAccessibilitySize(context)
                ? MainAxisSize.min
                : MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: AppTextStyles.isAccessibilitySize(context)
                ? CrossAxisAlignment.start
                : CrossAxisAlignment.center,
            children: [
              Text(dateStr, style: AppTextStyles.headline),
              Wrap(
                children: [
                  TextButton(
                    onPressed: widget.onCancel,
                    style: _textButtonStyle,
                    child: Text(
                      l.cancel,
                      style: AppTextStyles.footnote,
                    ),
                  ),
                  TextButton(
                    onPressed: _save,
                    style: _textButtonStyle,
                    child: Text(
                      l.save,
                      style: AppTextStyles.footnote
                          .copyWith(color: AppColors.accent),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s),
          // 気分(今日の画面と同じ顔。同じ顔をもう一度押すと取り消し)
          Text(l.editMood,
              style:
                  AppTextStyles.callout.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: AppSpacing.s),
          MoodPicker(
            selectedId: _stampId,
            onSelect: (id) => setState(() => _stampId = id),
          ),
          const SizedBox(height: AppSpacing.l),
          // 何への答えかが分かるように、その日の問いの文そのものを見出しにする
          _editField(_questionText(), _answerCtrl),
          if (_hasDiaryFields) ...[
            const SizedBox(height: AppSpacing.m),
            _editField(l.fieldGratitude, _gratitudeCtrl),
            const SizedBox(height: AppSpacing.m),
            _editField(l.fieldTodayPlan, _goalCtrl),
            const SizedBox(height: AppSpacing.m),
            _editField(l.fieldGoodThing, _goodCtrl),
            const SizedBox(height: AppSpacing.m),
            _editField(l.fieldTomorrowMessage, _tomorrowMsgCtrl),
          ],
          // 記録ごと消すのはまれなので、目立たせず右下に小さなゴミ箱だけ置く(確かめてから消す)
          Align(
            alignment: Alignment.centerRight,
            child: Semantics(
              button: true,
              label: l.deleteDay,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () async {
                  final ok = await showDeleteConfirmation(
                    context,
                    title: l.deleteDayTitle(dateStr),
                  );
                  if (ok) await widget.onDelete();
                },
                child: SizedBox.square(
                  dimension: AppSpacing.minTap,
                  child: Align(
                    alignment: Alignment.bottomRight,
                    child: Icon(CupertinoIcons.trash,
                        size: 18, color: AppColors.textMuted),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static final _textButtonStyle = TextButton.styleFrom(
    minimumSize: const Size(AppSpacing.minTap, AppSpacing.minTap),
    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s),
  );

  /// その日の問い(もう一歩の問いもつなげる)
  String _questionText() {
    final bank = ref.read(questionBankProvider);
    final id = widget.record.morningQuestionId;
    final q = (id == null ? null : bank.byId(id)) ??
        bank.forDate(widget.record.day);
    return questionWithFollowUp(q);
  }

  /// 見出し + 書いた量に合わせて縦に広がる欄
  Widget _editField(String label, TextEditingController ctrl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style:
                AppTextStyles.callout.copyWith(color: AppColors.textSecondary)),
        const SizedBox(height: AppSpacing.s),
        AppInput(
          controller: ctrl,
          maxLength: 1000,
          minLines: 2,
          maxLines: null,
          textInputAction: TextInputAction.newline,
        ),
      ],
    );
  }
}

/// 記録の編集アイコン(見た目は 16、押せる範囲は 44)
class _EditIconButton extends StatelessWidget {
  const _EditIconButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: context.l10n.edit,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox.square(
          dimension: AppSpacing.minTap,
          child: Align(
            alignment: Alignment.centerRight,
            child: Icon(
              CupertinoIcons.pencil,
              size: 16,
              color: AppColors.textMuted,
            ),
          ),
        ),
      ),
    );
  }
}

/// 一覧の日付の横に出す、その日の気分の札
class _MoodTag extends StatelessWidget {
  const _MoodTag({required this.moodId, required this.label});

  final String moodId;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.s, AppSpacing.xs / 2, AppSpacing.m, AppSpacing.xs / 2),
      decoration: ShapeDecoration(
        color: AppColors.bgWarm,
        shape: StadiumBorder(),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          MoodBadge(moodId: moodId, size: 18),
          const SizedBox(width: AppSpacing.xs + 2),
          Flexible(
            child: Text(label,
                style: AppTextStyles.footnote
                    .copyWith(color: moodTextColor(moodId))),
          ),
        ],
      ),
    );
  }
}
