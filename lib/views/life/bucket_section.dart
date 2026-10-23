import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/l10n.dart';
import '../../l10n/phrase_break.dart';
import '../../models/bucket_item.dart';
import '../../models/important_person.dart';
import '../../providers/bucket_provider.dart';
import '../../providers/important_person_provider.dart';
import '../../providers/isar_provider.dart';
import '../shared/action_buttons.dart';
import '../shared/app_card.dart';
import '../shared/app_colors.dart';
import '../shared/app_spacing.dart';
import '../shared/app_text_styles.dart';
import '../shared/app_toast.dart';
import '../shared/sheet_handle.dart';

/// バケットリスト(人生のうちに、いつかかなえたいこと)。日々の ToDo ではない
/// - まだのもの(いつか)と、かなえたこと を分けて並べる。かなえたものは消さずに残す(取り消し線も引かない)
/// - 追加は上の欄から。行を押すと、編集・かなえた・削除のシートが開く。左の丸でもかなえたにできる
/// - 通知・期限・達成率は持たない
class BucketSection extends ConsumerStatefulWidget {
  const BucketSection({super.key});

  @override
  ConsumerState<BucketSection> createState() => _BucketSectionState();
}

/// 何もないときに出す例(押すとそのまま追加される)
List<String> _examples(AppLocalizations l) => [
      l.bucketExample1,
      l.bucketExample2,
      l.bucketExample3,
      l.bucketExample4,
    ];

class _BucketSectionState extends ConsumerState<BucketSection> {
  final _input = TextEditingController();
  final _focus = FocusNode();
  int? _personId;

  @override
  void initState() {
    super.initState();
    _input.addListener(() => setState(() {}));
    _focus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _input.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _add([String? text]) async {
    // 例の文言には行を折らせない印が入っているので、記録に残す前に外す
    final title = stripWordJoiners(text ?? _input.text).trim();
    if (title.isEmpty) return;
    final added = await ref
        .read(bucketItemRepositoryProvider)
        .add(title, personId: text == null ? _personId : null);
    if (!mounted) return;
    if (added) {
      if (text == null) {
        _input.clear();
        setState(() => _personId = null);
      }
    } else {
      AppToast.success(context, context.l10n.bucketAlreadyOnList);
    }
  }

  void _openEditor(BucketItem item, List<ImportantPerson> persons) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
      ),
      builder: (_) => _BucketEditor(item: item, persons: persons),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final items = ref.watch(bucketItemsProvider).valueOrNull ?? const [];
    final persons = ref.watch(importantPersonsProvider).valueOrNull ??
        const <ImportantPerson>[];
    final names = {for (final p in persons) p.id: p.nickname};
    final canAdd = _input.text.trim().isNotEmpty;
    final someday = items.where((i) => i.doneAt == null).toList();
    final done = items.where((i) => i.doneAt != null).toList()
      ..sort((a, b) => b.doneAt!.compareTo(a.doneAt!));

    Widget list(List<BucketItem> group) => AppCard(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m),
          child: Column(
            children: [
              for (var i = 0; i < group.length; i++) ...[
                if (i > 0)
                  Divider(
                      height: 1,
                      indent: AppSpacing.minTap + AppSpacing.xs,
                      color: AppColors.divider),
                _BucketRow(
                  item: group[i],
                  withName: names[group[i].personId],
                  onToggle: () => ref
                      .read(bucketItemRepositoryProvider)
                      .toggleDone(group[i].id),
                  onOpen: () => _openEditor(group[i], persons),
                ),
              ],
            ],
          ),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l.bucketIntro,
            style: AppTextStyles.callout.copyWith(color: AppColors.textMuted)),
        const SizedBox(height: AppSpacing.l),
        _AddField(
          controller: _input,
          focusNode: _focus,
          canAdd: canAdd,
          onAdd: _add,
        ),
        // 「誰と」は書き始めたときだけ出す
        if (canAdd && persons.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.m),
          _PersonChips(
            persons: persons,
            selectedId: _personId,
            onSelect: (id) => setState(() => _personId = id),
          ),
        ],
        if (items.isEmpty) ...[
          const SizedBox(height: AppSpacing.xl),
          Text(l.forExample, style: AppTextStyles.captionLabel),
          const SizedBox(height: AppSpacing.s),
          Wrap(
            spacing: AppSpacing.s,
            runSpacing: AppSpacing.s,
            children: [
              for (final e in _examples(l))
                _Chip(label: e, icon: CupertinoIcons.add, onTap: () => _add(e)),
            ],
          ),
          const SizedBox(height: AppSpacing.l),
          PhraseText(l.bucketFromAnswers, style: AppTextStyles.footnote),
        ],
        if (someday.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xl),
          _SectionLabel(l.bucketSomeday, count: someday.length),
          list(someday),
        ],
        if (done.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xl),
          _SectionLabel(l.bucketAchieved, count: done.length),
          list(done),
        ],
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text, {required this.count});

  final String text;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
          left: AppSpacing.xs, bottom: AppSpacing.s),
      child: Text('$text  $count', style: AppTextStyles.captionLabel),
    );
  }
}

/// 1件の行。左の丸でかなえた/まだを切り替え、行を押すと編集のシート
class _BucketRow extends StatelessWidget {
  const _BucketRow({
    required this.item,
    required this.withName,
    required this.onToggle,
    required this.onOpen,
  });

  final BucketItem item;
  final String? withName;
  final VoidCallback onToggle;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final done = item.doneAt != null;
    final sub = [
      if (done) l.bucketDoneOn(formatDate(item.doneAt!, l.localeName)),
      if (withName != null) l.bucketWithPerson(withName!),
    ].join(l.subtitleSeparator);
    return Semantics(
      onTapHint: l.edit,
      child: InkWell(
        onTap: onOpen,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 52),
          child: Row(
            children: [
              Semantics(
                container: true,
                button: true,
                checked: done,
                label: done ? l.bucketDone : l.bucketNotDone,
                excludeSemantics: true,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onToggle,
                  child: SizedBox(
                    width: AppSpacing.minTap,
                    height: AppSpacing.minTap,
                    child: AnimatedSwitcher(
                      duration: AppMotion.base,
                      child: Icon(
                        done
                            ? CupertinoIcons.checkmark_seal_fill
                            : CupertinoIcons.circle,
                        key: ValueKey(done),
                        size: 24,
                        color: done ? AppColors.accent : AppColors.textDisabled,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.m),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 利用者の書いた文も、文節の途中で折らない(表示だけ。保存の値と読み上げは元の文)
                      PhraseText(item.title,
                          style: AppTextStyles.body.copyWith(height: 1.4)),
                      if (sub.isNotEmpty)
                        Text(sub, style: AppTextStyles.footnote),
                    ],
                  ),
                ),
              ),
              Icon(CupertinoIcons.chevron_right,
                  size: 15, color: AppColors.textDisabled),
              const SizedBox(width: AppSpacing.xs),
            ],
          ),
        ),
      ),
    );
  }
}

/// 1件を直すシート: 文・誰と・かなえた・削除
class _BucketEditor extends ConsumerStatefulWidget {
  const _BucketEditor({required this.item, required this.persons});

  final BucketItem item;
  final List<ImportantPerson> persons;

  @override
  ConsumerState<_BucketEditor> createState() => _BucketEditorState();
}

class _BucketEditorState extends ConsumerState<_BucketEditor> {
  late final _title = TextEditingController(text: widget.item.title);
  late int? _personId = widget.item.personId;
  late bool _done = widget.item.doneAt != null;

  @override
  void initState() {
    super.initState();
    _title.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final repo = ref.read(bucketItemRepositoryProvider);
    await repo.update(widget.item.id,
        title: _title.text, personId: _personId);
    if (_done != (widget.item.doneAt != null)) {
      await repo.toggleDone(widget.item.id);
    }
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final ok = await showDeleteConfirmation(
      context,
      title: context.l10n.deleteBucketItemTitle(widget.item.title),
    );
    if (!ok) return;
    await ref.read(bucketItemRepositoryProvider).delete(widget.item.id);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final canSave = _title.text.trim().isNotEmpty;
    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom +
              MediaQuery.viewPaddingOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SheetHandle(),
          // iOS のシートと同じ並び: 左にキャンセル、まん中に題、右に完了
          // iOS のナビゲーションバーと同じく、文字の設定を大きくしてもこの列は大きくしない
          MediaQuery.withClampedTextScaling(
            maxScaleFactor: AppTextStyles.barMaxTextScale,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
              child: Row(
                children: [
                  _TextAction(l.cancel,
                      onTap: () => Navigator.of(context).pop()),
                  Expanded(
                    child: Text(l.edit,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.headline),
                  ),
                  _TextAction(l.done,
                      strong: true, onTap: canSave ? _save : null),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.screen,
                AppSpacing.l, AppSpacing.screen, AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppCard(
                  showShadow: false,
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.l, vertical: AppSpacing.xs),
                  child: Column(
                    children: [
                      TextField(
                        controller: _title,
                        maxLength: 100,
                        // 大きい文字では折り返して全文を出す(1行だと途中で切れる)。改行は入れさせない
                        keyboardType: TextInputType.text,
                        minLines: 1,
                        maxLines: AppTextStyles.isAccessibilitySize(context)
                            ? null
                            : 1,
                        style: AppTextStyles.body,
                        cursorColor: AppColors.accent,
                        decoration: const InputDecoration(
                          counterText: '',
                          border: InputBorder.none,
                          contentPadding:
                              EdgeInsets.symmetric(vertical: AppSpacing.m),
                        ),
                      ),
                      Divider(height: 1, color: AppColors.divider),
                      ConstrainedBox(
                        constraints: const BoxConstraints(minHeight: 52),
                        child: Row(
                          children: [
                            Expanded(
                                child: Text(l.bucketDone,
                                    style: AppTextStyles.body)),
                            CupertinoSwitch(
                              value: _done,
                              activeTrackColor: AppColors.accent,
                              onChanged: (v) => setState(() => _done = v),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (widget.persons.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xl),
                  _PersonChips(
                    persons: widget.persons,
                    selectedId: _personId,
                    onSelect: (id) => setState(() => _personId = id),
                  ),
                ],
                const SizedBox(height: AppSpacing.xl),
                Center(
                  child: TextButton.icon(
                    onPressed: _delete,
                    style: TextButton.styleFrom(
                        foregroundColor: AppColors.danger,
                        minimumSize:
                            const Size(AppSpacing.minTap, AppSpacing.minTap)),
                    icon: const Icon(CupertinoIcons.trash, size: 18),
                    label: Text(l.delete,
                        style: AppTextStyles.body
                            .copyWith(color: AppColors.danger)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TextAction extends StatelessWidget {
  const _TextAction(this.label, {required this.onTap, this.strong = false});

  final String label;
  final VoidCallback? onTap;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: onTap != null,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
              minHeight: AppSpacing.minTap, minWidth: AppSpacing.minTap + 20),
          child: Center(
            child: Text(label,
                style: AppTextStyles.body.copyWith(
                  fontWeight: strong ? FontWeight.w600 : FontWeight.w400,
                  color: onTap == null
                      ? AppColors.textDisabled
                      : AppColors.accent,
                )),
          ),
        ),
      ),
    );
  }
}

/// 「誰と(任意)」を選ぶカプセルの並び。もう一度押すと外れる
class _PersonChips extends StatelessWidget {
  const _PersonChips({
    required this.persons,
    required this.selectedId,
    required this.onSelect,
  });

  final List<ImportantPerson> persons;
  final int? selectedId;
  final ValueChanged<int?> onSelect;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.s,
      runSpacing: AppSpacing.s,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(context.l10n.withWhomOptional, style: AppTextStyles.footnote),
        for (final p in persons)
          _Chip(
            label: p.nickname,
            selected: selectedId == p.id,
            onTap: () => onSelect(selectedId == p.id ? null : p.id),
          ),
      ],
    );
  }
}

/// カプセルの入力欄 + 中の丸い追加ボタン(メッセージの送る印と同じ置き方)
class _AddField extends StatelessWidget {
  const _AddField({
    required this.controller,
    required this.focusNode,
    required this.canAdd,
    required this.onAdd,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool canAdd;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final focused = focusNode.hasFocus;
    final large = AppTextStyles.isAccessibilitySize(context);
    return AnimatedContainer(
      duration: AppMotion.base,
      curve: Curves.easeOutCubic,
      // 大きい文字では高さを最低限だけ決め、折り返した分だけ伸ばす(既定の文字では今までどおり固定)
      height: large ? null : AppSpacing.buttonHeight,
      constraints: large
          ? const BoxConstraints(minHeight: AppSpacing.buttonHeight)
          : null,
      decoration: ShapeDecoration(
        color: AppColors.card,
        // 大きい文字で背が伸びたときは、カプセルだと角が大きすぎるので角丸の四角に
        shape: large
            ? RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.field),
                side: BorderSide(
                  color: focused ? AppColors.borderAccent : AppColors.divider,
                ),
              )
            : StadiumBorder(
                side: BorderSide(
                  color: focused ? AppColors.borderAccent : AppColors.divider,
                ),
              ),
      ),
      padding: EdgeInsets.only(
          left: AppSpacing.screen,
          top: large ? AppSpacing.s : 0,
          bottom: large ? AppSpacing.s : 0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              maxLength: 100,
              // 大きい文字では入力と案内の文字を折り返す(1行だと「バケット…」で切れる)
              keyboardType: TextInputType.text,
              minLines: 1,
              maxLines: large ? null : 1,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => onAdd(),
              style: AppTextStyles.body,
              cursorColor: AppColors.accent,
              decoration: InputDecoration(
                // 案内も文節で折る(「バケットリ/ストに追加」と割らない)。読み上げは元の文
                hint: PhraseText(
                  context.l10n.addToBucketList,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.body
                      .copyWith(color: AppColors.textDisabled),
                ),
                counterText: '',
                isCollapsed: true,
                border: InputBorder.none,
              ),
            ),
          ),
          Semantics(
            button: true,
            enabled: canAdd,
            label: context.l10n.add,
            excludeSemantics: true,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: canAdd ? onAdd : null,
              child: SizedBox(
                width: AppSpacing.buttonHeight,
                height: AppSpacing.buttonHeight,
                child: Center(
                  child: AnimatedContainer(
                    duration: AppMotion.base,
                    curve: Curves.easeOutCubic,
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: canAdd ? AppColors.accent : AppColors.bgSub,
                    ),
                    child: Icon(CupertinoIcons.arrow_up,
                        size: 17,
                        color: canAdd ? AppColors.onAccent : AppColors.textDisabled),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// カプセルの札(押せる)
class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.onTap,
    this.selected = false,
    this.icon,
  });

  final String label;
  final bool selected;
  final IconData? icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.onAccent : AppColors.textSecondary;
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: AppMotion.base,
          curve: Curves.easeOutCubic,
          constraints: const BoxConstraints(minHeight: 36),
          // 上下の余白は折り返したときのため(既定の文字では高さ 36 のまま変わらない)
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.m + 2, vertical: AppSpacing.xs),
          decoration: ShapeDecoration(
            color: selected ? AppColors.accent : AppColors.card,
            shape: StadiumBorder(
              side: BorderSide(
                  color: selected ? AppColors.accent : AppColors.divider),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 14, color: AppColors.accent),
                const SizedBox(width: AppSpacing.xs),
              ],
              // 大きい文字では札の中で折り返す(選ぶ文字は切らない)
              Flexible(
                child: Text(label,
                    style: AppTextStyles.callout.copyWith(color: color)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
