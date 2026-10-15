import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/bucket_item.dart';
import '../../models/important_person.dart';
import '../../providers/bucket_provider.dart';
import '../../providers/important_person_provider.dart';
import '../../providers/isar_provider.dart';
import '../shared/app_card.dart';
import '../shared/action_buttons.dart';
import '../shared/app_colors.dart';
import '../shared/app_spacing.dart';
import '../shared/app_text_styles.dart';
import '../shared/app_toast.dart';

/// やりたいこと(バケットリスト)。通知・期限・達成率は持たない
/// 足すのはリストの上の欄から(小窓を開かない)。消すのは各行の「…」から(横にずらす操作は使わない)
class BucketSection extends ConsumerStatefulWidget {
  const BucketSection({super.key});

  @override
  ConsumerState<BucketSection> createState() => _BucketSectionState();
}

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

  Future<void> _add() async {
    final title = _input.text.trim();
    if (title.isEmpty) return;
    final added = await ref
        .read(bucketItemRepositoryProvider)
        .add(title, personId: _personId);
    if (!mounted) return;
    if (added) {
      _input.clear();
      setState(() => _personId = null);
    } else {
      AppToast.success(context, '同じものが、もうリストにあります');
    }
  }

  Future<void> _confirmDelete(BucketItem item) async {
    final ok = await showDeleteConfirmation(
      context,
      title: '「${item.title}」をリストから消しますか？',
    );
    if (ok) {
      await ref.read(bucketItemRepositoryProvider).delete(item.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(bucketItemsProvider).valueOrNull ?? const [];
    final persons = ref.watch(importantPersonsProvider).valueOrNull ??
        const <ImportantPerson>[];
    final names = {for (final p in persons) p.id: p.nickname};
    final canAdd = _input.text.trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 題(人生)と切り替え(やりたいこと)があるので、見出しは重ねない
        Text('いつかやってみたいことを、1行で。ひとりでも、家族や友だちとでも。',
            style: AppTextStyles.callout.copyWith(color: AppColors.textMuted)),
        const SizedBox(height: AppSpacing.l),
        // 足す欄: カプセルの欄の中に、丸い「+」(メッセージの送る印と同じ置き方)
        _AddField(
          controller: _input,
          focusNode: _focus,
          hint: items.isEmpty ? '例: 家族で温泉に行く' : 'やりたいことを足す',
          canAdd: canAdd,
          onAdd: _add,
        ),
        // 「誰と」は書き始めたときだけ出す(任意)
        if (canAdd && persons.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.m),
          Wrap(
            spacing: AppSpacing.s,
            runSpacing: AppSpacing.s,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text('誰と', style: AppTextStyles.footnote),
              for (final p in persons)
                _Chip(
                  label: p.nickname,
                  selected: _personId == p.id,
                  onTap: () => setState(
                      () => _personId = _personId == p.id ? null : p.id),
                ),
            ],
          ),
        ],
        const SizedBox(height: AppSpacing.xl),
        if (items.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
            child: Text('たとえば「オーロラを見る」。今日の問いの答えからも入れられます。',
                style: AppTextStyles.footnote),
          )
        else
          AppCard(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.m, vertical: AppSpacing.xs),
            child: Column(
              children: [
                for (var i = 0; i < items.length; i++) ...[
                  if (i > 0)
                    const Divider(
                        height: 1,
                        indent: AppSpacing.minTap + AppSpacing.xs,
                        color: AppColors.divider),
                  _BucketRow(
                    item: items[i],
                    withName: names[items[i].personId],
                    onToggle: () => ref
                        .read(bucketItemRepositoryProvider)
                        .toggleDone(items[i].id),
                    onDelete: () => _confirmDelete(items[i]),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

/// カプセルの入力欄 + 中の丸いボタン
class _AddField extends StatelessWidget {
  const _AddField({
    required this.controller,
    required this.focusNode,
    required this.hint,
    required this.canAdd,
    required this.onAdd,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String hint;
  final bool canAdd;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final focused = focusNode.hasFocus;
    return AnimatedContainer(
      duration: AppMotion.base,
      curve: Curves.easeOutCubic,
      decoration: ShapeDecoration(
        color: AppColors.card,
        shape: StadiumBorder(
          side: BorderSide(
            color: focused ? AppColors.borderAccent : AppColors.border,
          ),
        ),
        shadows: AppColors.cardShadow,
      ),
      padding: const EdgeInsets.only(left: AppSpacing.l + AppSpacing.xs),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              maxLength: 100,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => onAdd(),
              style: AppTextStyles.body,
              cursorColor: AppColors.accent,
              decoration: InputDecoration(
                hintText: hint,
                hintStyle:
                    AppTextStyles.body.copyWith(color: AppColors.textDisabled),
                counterText: '',
                isCollapsed: true,
                border: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: AppSpacing.l),
              ),
            ),
          ),
          Semantics(
            button: true,
            enabled: canAdd,
            label: 'リストに足す',
            excludeSemantics: true,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: canAdd ? onAdd : null,
              child: SizedBox(
                width: AppSpacing.minTap + AppSpacing.s,
                height: AppSpacing.minTap + AppSpacing.s,
                child: Center(
                  child: AnimatedContainer(
                    duration: AppMotion.base,
                    curve: Curves.easeOutCubic,
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: canAdd ? AppColors.accent : AppColors.bgSub,
                    ),
                    child: Icon(CupertinoIcons.arrow_up,
                        size: 18,
                        color: canAdd ? Colors.white : AppColors.textDisabled),
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

/// 「誰と」を選ぶカプセル
class _Chip extends StatelessWidget {
  const _Chip(
      {required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: AppMotion.base,
          curve: Curves.easeOutCubic,
          constraints: const BoxConstraints(minHeight: 36),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m + 2),
          decoration: ShapeDecoration(
            color: selected ? AppColors.accent : AppColors.card,
            shape: StadiumBorder(
              side: BorderSide(
                  color: selected ? AppColors.accent : AppColors.divider),
            ),
          ),
          child: Center(
            widthFactor: 1,
            child: Text(label,
                style: AppTextStyles.callout.copyWith(
                    color: selected ? Colors.white : AppColors.textSecondary)),
          ),
        ),
      ),
    );
  }
}

class _BucketRow extends StatelessWidget {
  const _BucketRow({
    required this.item,
    required this.withName,
    required this.onToggle,
    required this.onDelete,
  });

  final BucketItem item;
  final String? withName;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final done = item.doneAt != null;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Semantics(
            button: true,
            checked: done,
            label: done ? 'できた。押すと、まだに戻す' : '押すと、できたにする',
            excludeSemantics: true,
            child: InkResponse(
              onTap: onToggle,
              radius: AppSpacing.minTap / 2,
              child: SizedBox(
                width: AppSpacing.minTap,
                height: AppSpacing.minTap,
                child: Icon(
                  done
                      ? CupertinoIcons.checkmark_circle_fill
                      : CupertinoIcons.circle,
                  size: 24,
                  color: done ? AppColors.accent : AppColors.textMuted,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title,
                    style: AppTextStyles.callout.copyWith(
                      color: done ? AppColors.textMuted : AppColors.text,
                      decoration: done ? TextDecoration.lineThrough : null,
                      decorationColor: AppColors.textMuted,
                    )),
                if (withName != null || done)
                  Text(
                      [
                        if (withName != null) '$withNameと',
                        if (done)
                          'できた日 ${item.doneAt!.year}/${item.doneAt!.month}/${item.doneAt!.day}',
                      ].join('・'),
                      style: AppTextStyles.footnote),
              ],
            ),
          ),
          PopupMenuButton<String>(
            tooltip: 'そのほかの操作',
            icon: const Icon(CupertinoIcons.ellipsis, color: AppColors.textMuted),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.field)),
            color: AppColors.card,
            onSelected: (v) {
              if (v == 'toggle') onToggle();
              if (v == 'delete') onDelete();
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                  value: 'toggle',
                  child: Text(done ? 'まだにする' : 'できたにする',
                      style: AppTextStyles.callout)),
              PopupMenuItem(
                  value: 'delete',
                  child: Text('消す',
                      style: AppTextStyles.callout
                          .copyWith(color: AppColors.danger))),
            ],
          ),
        ],
      ),
    );
  }
}
