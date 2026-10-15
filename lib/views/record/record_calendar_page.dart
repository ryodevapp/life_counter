import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../models/daily_record.dart';
import '../../models/stamp.dart';
import 'reflection_view.dart';
import '../../providers/isar_provider.dart';
import '../../providers/question_bank_provider.dart';
import '../shared/app_colors.dart';
import '../shared/app_spacing.dart';
import '../shared/app_text_styles.dart';
import '../shared/mood_face.dart';
import '../shared/mood_shape.dart';
import '../shared/app_card.dart';
import '../shared/app_input.dart';
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
          DateTime(r.date.year, r.date.month, r.date.day): r,
      };

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.screen, AppSpacing.l, AppSpacing.screen, 130),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const PageHeader('記録'),
            AppSegmentedControl<_RecordView>(
              items: const [
                SegmentItem(value: _RecordView.list, label: 'リスト'),
                SegmentItem(value: _RecordView.calendar, label: 'カレンダー'),
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
    );
  }

  /// カレンダーで選択した日の記録カード（インライン表示）
  Widget _buildSelectedRecordCard() {
    final r = _selectedRecord!;
    final isEditing = _editingRecordId == r.id;

    if (isEditing) {
      return _InlineEditCard(
        record: r,
        onSave: (updated) async {
          final repo = ref.read(dailyRecordRepositoryProvider);
          await repo.save(updated);
          setState(() {
            _editingRecordId = null;
            _selectedRecord = updated;
          });
          _loadRecords();
        },
        onCancel: () => setState(() => _editingRecordId = null),
      );
    }

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_formatDate(r.date), style: AppTextStyles.headline),
              _EditIconButton(
                  onTap: () => setState(() => _editingRecordId = r.id)),
            ],
          ),
          const SizedBox(height: AppSpacing.s),
          ..._buildInlineFields(r),
        ],
      ),
    );
  }

  Widget _buildCalendar() {
    return AppCard(
      child: TableCalendar(
        firstDay: DateTime(2020),
        lastDay: DateTime.now(),
        focusedDay: _focusedDay,
        locale: 'ja_JP',
        startingDayOfWeek: StartingDayOfWeek.sunday,
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
          markerDecoration: const BoxDecoration(
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
          '記録はまだありません',
          textAlign: TextAlign.center,
          style: AppTextStyles.callout.copyWith(color: AppColors.textMuted),
        ),
      );
    }
    // 新しい順。月が変わるところに月の見出し(気分の内訳つき)を入れる。いちばん上に1年前の今日
    final children = <Widget>[LastYearCard(records: _records)];
    DateTime? month;
    for (final r in filtered) {
      final m = DateTime(r.date.year, r.date.month);
      if (m != month) {
        if (month != null) {
          children.add(const SizedBox(height: AppSpacing.l));
        }
        month = m;
        children.add(MonthHeader(
          month: m,
          records: filtered
              .where((x) => x.date.year == m.year && x.date.month == m.month)
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

  Widget _listItem(DailyRecord r) {
        final isEditing = _editingRecordId == r.id;
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.cardGap),
          child: isEditing
              ? _InlineEditCard(
                  record: r,
                  onSave: (updated) async {
                    final repo = ref.read(dailyRecordRepositoryProvider);
                    await repo.save(updated);
                    setState(() => _editingRecordId = null);
                    _loadRecords();
                  },
                  onCancel: () => setState(() => _editingRecordId = null),
                )
              : AppCard(
                  // 右上の編集ボタンは押せる範囲 44 の分だけ上と右が膨らむので、そこだけ余白を詰めて上下を揃える
                  padding: const EdgeInsets.fromLTRB(AppSpacing.card,
                      AppSpacing.s, AppSpacing.s, AppSpacing.card),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(_formatDate(r.date),
                              style: AppTextStyles.headline),
                          // その日の気分は、日付の横に小さな札で(問いの文は重ねない)
                          if (stampById(r.stamp) case final mood?) ...[
                            const SizedBox(width: AppSpacing.s),
                            _MoodTag(moodId: mood.id, label: mood.label),
                          ],
                          const Spacer(),
                          _EditIconButton(
                              onTap: () =>
                                  setState(() => _editingRecordId = r.id)),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.s),
                      ..._buildInlineFields(r),
                    ],
                  ),
                ),
        );
  }

  String _formatDate(DateTime date) {
    final weekday = DateFormat.E('ja_JP').format(date);
    return '${date.month}月${date.day}日（$weekday）';
  }

  List<Widget> _buildInlineFields(DailyRecord r) {
    final fields = <(String, String)>[];
    // 今日の問いへの答えは、問いの文を見出しにする(何への答えかが分かるように)
    if (r.answer != null) {
      final q = r.morningQuestionId == null
          ? null
          : ref.read(questionBankProvider).byId(r.morningQuestionId!);
      fields.add((q?.text ?? '今日の問い', r.answer!));
    }
    if (r.gratitude != null) fields.add(('感謝していること', r.gratitude!));
    if (r.todayGoal != null) fields.add(('今日やること', r.todayGoal!));
    if (r.reflectionGood != null) fields.add(('嬉しかったこと', r.reflectionGood!));
    if (r.tomorrowMessage != null) fields.add(('明日の自分へ', r.tomorrowMessage!));
    if (r.reflectionWhy != null) fields.add(('その理由', r.reflectionWhy!));
    if (r.reflectionTomorrow != null) fields.add(('明日の楽しみ', r.reflectionTomorrow!));
    if (r.weeklyReflectionHighlight != null) fields.add(('今週のハイライト', r.weeklyReflectionHighlight!));
    if (r.weeklyReflectionChange != null) fields.add(('来週変えること', r.weeklyReflectionChange!));

    if (fields.isEmpty) {
      return [
        if (r.stamp == null) Text('記録なし', style: AppTextStyles.footnote),
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
            Text(
              entry.value.$2,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.callout,
            ),
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
    required this.onCancel,
  });

  final DailyRecord record;
  final Future<void> Function(DailyRecord) onSave;
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

  /// v1.0 系の4つの欄のどれかがある記録だけ、その欄を編集に出す
  bool get _hasDiaryFields =>
      widget.record.gratitude != null ||
      widget.record.todayGoal != null ||
      widget.record.reflectionGood != null ||
      widget.record.tomorrowMessage != null;

  @override
  void initState() {
    super.initState();
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
            .getByDate(widget.record.date) ??
        widget.record;
    r.morningQuestionId ??= ref.read(questionBankProvider).forDate(r.date).id;
    r.answer = _answerCtrl.text.trim().isNotEmpty ? _answerCtrl.text : null;
    r.gratitude = _gratitudeCtrl.text.isNotEmpty ? _gratitudeCtrl.text : null;
    r.todayGoal = _goalCtrl.text.isNotEmpty ? _goalCtrl.text : null;
    r.reflectionGood = _goodCtrl.text.isNotEmpty ? _goodCtrl.text : null;
    r.tomorrowMessage = _tomorrowMsgCtrl.text.isNotEmpty ? _tomorrowMsgCtrl.text : null;
    await widget.onSave(r);
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.record.date;
    final weekday = DateFormat.E('ja_JP').format(d);
    final dateStr = '${d.month}月${d.day}日（$weekday）';

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(dateStr, style: AppTextStyles.headline),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextButton(
                    onPressed: widget.onCancel,
                    style: _textButtonStyle,
                    child: Text(
                      'キャンセル',
                      style: AppTextStyles.footnote,
                    ),
                  ),
                  TextButton(
                    onPressed: _save,
                    style: _textButtonStyle,
                    child: Text(
                      '保存',
                      style: AppTextStyles.footnote
                          .copyWith(color: AppColors.accent),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s),
          _editField('今日の問い', _answerCtrl),
          if (_hasDiaryFields) ...[
            const SizedBox(height: AppSpacing.m),
            _editField('感謝していること', _gratitudeCtrl),
            const SizedBox(height: AppSpacing.m),
            _editField('今日やること', _goalCtrl),
            const SizedBox(height: AppSpacing.m),
            _editField('嬉しかったこと', _goodCtrl),
            const SizedBox(height: AppSpacing.m),
            _editField('明日の自分へ', _tomorrowMsgCtrl),
          ],
        ],
      ),
    );
  }

  static final _textButtonStyle = TextButton.styleFrom(
    minimumSize: const Size(AppSpacing.minTap, AppSpacing.minTap),
    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s),
  );

  Widget _editField(String label, TextEditingController ctrl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.captionLabel),
        const SizedBox(height: AppSpacing.xs),
        AppInput(
          controller: ctrl,
          maxLength: 200,
          textInputAction: TextInputAction.next,
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
      label: '編集',
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: const SizedBox.square(
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
      decoration: const ShapeDecoration(
        color: AppColors.bgWarm,
        shape: StadiumBorder(),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          MoodBadge(moodId: moodId, size: 18),
          const SizedBox(width: AppSpacing.xs + 2),
          Text(label,
              style: AppTextStyles.footnote
                  .copyWith(color: moodLooks[moodId]?.ink)),
        ],
      ),
    );
  }
}
