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
import 'bucket_form_dialog.dart';

/// やりたいことリスト。通知・期限・達成率は持たない
class BucketSection extends ConsumerWidget {
  const BucketSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(bucketItemsProvider).valueOrNull ?? const [];
    final persons =
        ref.watch(importantPersonsProvider).valueOrNull ?? const <ImportantPerson>[];
    final names = {for (final p in persons) p.id: p.nickname};

    Future<void> add() async {
      final result = await BucketFormDialog.show(context, persons: persons);
      if (result == null) return;
      await ref
          .read(bucketItemRepositoryProvider)
          .add(result.title, personId: result.personId);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text('やりたいこと',
                  style: GoogleFonts.zenKakuGothicNew(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: AppColors.text)),
            ),
            IconButton(
              onPressed: add,
              tooltip: 'やりたいことを足す',
              icon: const Icon(Icons.add, color: AppColors.accent),
            ),
          ],
        ),
        const SizedBox(height: 8),
        AppCard(
          child: items.isEmpty
              ? Text('思いついたら、ここに残せます',
                  style: GoogleFonts.zenKakuGothicNew(
                      fontSize: 13, color: AppColors.textMuted))
              : Column(
                  children: [
                    for (final item in items)
                      _BucketRow(
                        item: item,
                        withName: names[item.personId],
                        onToggle: () => ref
                            .read(bucketItemRepositoryProvider)
                            .toggleDone(item.id),
                        onDelete: () => ref
                            .read(bucketItemRepositoryProvider)
                            .delete(item.id),
                      ),
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
    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          content: Text('「${item.title}」を消しますか？'),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('やめる')),
            TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('消す')),
          ],
        ),
      ),
      onDismissed: (_) => onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: const Icon(Icons.delete_outline, color: AppColors.textMuted),
      ),
      child: Opacity(
        // できたものも消さず、薄くして残す
        opacity: done ? 0.45 : 1,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              IconButton(
                onPressed: onToggle,
                tooltip: done ? 'まだにする' : 'できた',
                icon: Icon(
                  done ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: AppColors.accent,
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.title,
                        style: GoogleFonts.zenKakuGothicNew(
                            fontSize: 14,
                            color: AppColors.text,
                            height: 1.5)),
                    if (withName != null)
                      Text('$withNameと',
                          style: GoogleFonts.zenKakuGothicNew(
                              fontSize: 12, color: AppColors.textMuted)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
