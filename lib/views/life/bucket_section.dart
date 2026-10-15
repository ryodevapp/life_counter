import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/bucket_item.dart';
import '../../models/important_person.dart';
import '../../providers/bucket_provider.dart';
import '../../providers/important_person_provider.dart';
import '../../providers/isar_provider.dart';
import '../shared/app_card.dart';
import '../shared/app_colors.dart';

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
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('同じものが、もうリストにあります')));
    }
  }

  Future<void> _confirmDelete(BucketItem item) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        content: Text('「${item.title}」をリストから消しますか？',
            style: GoogleFonts.zenKakuGothicNew(fontSize: 15, height: 1.6)),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('やめる')),
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('消す', style: TextStyle(color: Color(0xFFC0392B)))),
        ],
      ),
    );
    if (ok == true) {
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
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text('やりたいこと',
                style: GoogleFonts.zenKakuGothicNew(
                    fontSize: 17,
                    fontWeight: FontWeight.w500,
                    color: AppColors.text)),
            const SizedBox(width: 8),
            Text('バケットリスト',
                style: GoogleFonts.zenKakuGothicNew(
                    fontSize: 12, color: AppColors.textMuted)),
          ],
        ),
        const SizedBox(height: 6),
        Text('人生でいつかやってみたいことを、思いついたときに1行で残しておく場所です。自分ひとりのことでも、家族や友だちとやりたいことでも。',
            style: GoogleFonts.zenKakuGothicNew(
                fontSize: 13, color: AppColors.textSecondary, height: 1.7)),
        const SizedBox(height: 14),
        AppCard(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
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
                      style: GoogleFonts.zenKakuGothicNew(
                          fontSize: 15, color: AppColors.text),
                      decoration: InputDecoration(
                        hintText: items.isEmpty
                            ? '例: 家族で温泉に行く'
                            : 'やりたいことを1行で',
                        hintStyle: GoogleFonts.zenKakuGothicNew(
                            fontSize: 15, color: AppColors.textDisabled),
                        counterText: '',
                        isDense: true,
                        filled: true,
                        fillColor: AppColors.bgWarm,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: canAdd ? _add : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      disabledBackgroundColor: AppColors.bgSub,
                      foregroundColor: Colors.white,
                      disabledForegroundColor: AppColors.textDisabled,
                      minimumSize: const Size(64, 44),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('追加',
                        style: GoogleFonts.zenKakuGothicNew(
                            fontSize: 14, fontWeight: FontWeight.w500)),
                  ),
                ],
              ),
              // 「誰と」は書き始めたときだけ出す(任意)
              if (canAdd && persons.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text('誰と(任意)',
                        style: GoogleFonts.zenKakuGothicNew(
                            fontSize: 12, color: AppColors.textMuted)),
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
              const SizedBox(height: 6),
              if (items.isEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 10, 4, 10),
                  child: Text(
                      'たとえば「オーロラを見る」「父に昔の話を聞く」\n今日の問いの答えからも入れられます',
                      style: GoogleFonts.zenKakuGothicNew(
                          fontSize: 13,
                          color: AppColors.textMuted,
                          height: 1.8)),
                )
              else
                for (var i = 0; i < items.length; i++) ...[
                  if (i > 0)
                    const Divider(height: 1, color: AppColors.border),
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
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Semantics(
            button: true,
            checked: done,
            label: done ? 'できた。押すと、まだに戻す' : '押すと、できたにする',
            excludeSemantics: true,
            child: InkResponse(
              onTap: onToggle,
              radius: 24,
              child: SizedBox(
                width: 44,
                height: 44,
                child: Icon(
                  done ? Icons.check_circle : Icons.radio_button_unchecked,
                  size: 24,
                  color: done ? AppColors.accent : AppColors.textDisabled,
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title,
                    style: GoogleFonts.zenKakuGothicNew(
                      fontSize: 15,
                      height: 1.5,
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
                      style: GoogleFonts.zenKakuGothicNew(
                          fontSize: 12, color: AppColors.textMuted)),
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
                  child: Text(done ? 'まだにする' : 'できたにする')),
              const PopupMenuItem(
                  value: 'delete',
                  child: Text('消す', style: TextStyle(color: Color(0xFFC0392B)))),
            ],
          ),
        ],
      ),
    );
  }
}
