import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/important_person.dart';
import '../shared/app_button.dart';
import '../shared/app_colors.dart';
import '../shared/app_input.dart';

class BucketFormResult {
  const BucketFormResult(this.title, this.personId);
  final String title;
  final int? personId;
}

/// やりたいことを1件足す(「何を」と、任意で「誰と」)
class BucketFormDialog extends StatefulWidget {
  const BucketFormDialog({super.key, required this.persons});

  final List<ImportantPerson> persons;

  static Future<BucketFormResult?> show(BuildContext context,
      {required List<ImportantPerson> persons}) {
    return showDialog<BucketFormResult>(
      context: context,
      builder: (_) => BucketFormDialog(persons: persons),
    );
  }

  @override
  State<BucketFormDialog> createState() => _BucketFormDialogState();
}

class _BucketFormDialogState extends State<BucketFormDialog> {
  final _title = TextEditingController();
  int? _personId;

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.card,
      title: Text('やりたいこと',
          style: GoogleFonts.zenKakuGothicNew(
              fontSize: 16, fontWeight: FontWeight.w500)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppInput(
            controller: _title,
            placeholder: '例: 家族で温泉に行く',
            maxLength: 100,
            onChanged: (_) => setState(() {}),
          ),
          if (widget.persons.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text('誰と(任意)',
                style: GoogleFonts.zenKakuGothicNew(
                    fontSize: 12, color: AppColors.textMuted)),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              children: [
                for (final p in widget.persons)
                  ChoiceChip(
                    label: Text(p.nickname),
                    selected: _personId == p.id,
                    onSelected: (on) =>
                        setState(() => _personId = on ? p.id : null),
                  ),
              ],
            ),
          ],
        ],
      ),
      actions: [
        AppButton.secondary(
          onPressed: () => Navigator.of(context).pop(),
          label: 'やめる',
        ),
        AppButton.primary(
          onPressed: _title.text.trim().isEmpty
              ? null
              : () => Navigator.of(context)
                  .pop(BucketFormResult(_title.text.trim(), _personId)),
          label: '残す',
        ),
      ],
    );
  }
}
