import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/bucket_item.dart';
import '../../models/important_person.dart';
import '../../providers/bucket_provider.dart';
import '../../providers/important_person_provider.dart';
import '../../providers/isar_provider.dart';
import '../shared/app_card.dart';
import '../shared/action_buttons.dart';
import '../shared/app_button.dart';
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
        Text('バケットリスト。人生でいつかやってみたいことを、思いついたときに1行で残しておく場所です。自分ひとりのことでも、家族や友だちとやりたいことでも。',
            style: AppTextStyles.callout
                .copyWith(color: AppColors.textSecondary)),
        const SizedBox(height: AppSpacing.l),
        AppCard(
          // 下は、行の押せる範囲(44)が余白を兼ねるので s にする
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.card, AppSpacing.card, AppSpacing.card, AppSpacing.s),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 足す欄(いちばん上)
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _input,
                      focusNode: _focus,
                      maxLength: 100,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _add(),
                      style: AppTextStyles.callout,
                      // 見た目は AppInput と同じ(bgWarm・角 md・枠なし)
                      decoration: InputDecoration(
                        hintText: items.isEmpty
                            ? '例: 家族で温泉に行く'
                            : 'やりたいことを1行で',
                        hintStyle: AppTextStyles.callout
                            .copyWith(color: AppColors.textDisabled),
                        counterText: '',
                        filled: true,
                        fillColor: AppColors.bgWarm,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.l, vertical: AppSpacing.m),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s),
                  AppButton(
                    onPressed: canAdd ? _add : null,
                    primary: true,
                    expand: false,
                    child: const Text('追加'),
                  ),
                ],
              ),
              // 「誰と」は書き始めたときだけ出す(任意)
              if (canAdd && persons.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.m),
                Wrap(
                  spacing: AppSpacing.s,
                  runSpacing: AppSpacing.xs,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text('誰と(任意)', style: AppTextStyles.captionLabel),
                    for (final p in persons)
                      ChoiceChip(
                        label: Text(p.nickname),
                        selected: _personId == p.id,
                        onSelected: (on) =>
                            setState(() => _personId = on ? p.id : null),
                      ),
                  ],
                ),
              ],
              const SizedBox(height: AppSpacing.s),
              if (items.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.s),
                  child: Text(
                      'たとえば「オーロラを見る」\n今日の問いの答えからも入れられます',
                      style: AppTextStyles.callout
                          .copyWith(color: AppColors.textMuted)),
                )
              else
                for (var i = 0; i < items.length; i++) ...[
                  if (i > 0)
                    const Divider(height: 1, color: AppColors.divider),
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
                  done ? Icons.check_circle : Icons.radio_button_unchecked,
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
            icon: const Icon(Icons.more_horiz, color: AppColors.textMuted),
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
