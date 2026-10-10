import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/important_person.dart';
import '../../services/family_time.dart';
import '../shared/app_button.dart';
import '../shared/app_colors.dart';
import '../shared/app_toast.dart';
import 'next_meet_row.dart';

const appStoreUrl = 'https://apps.apple.com/jp/app/id6761015343';

/// 家族ひとりぶんを、共有できる画像にする
class ShareCardSheet extends StatefulWidget {
  const ShareCardSheet({
    super.key,
    required this.person,
    required this.time,
    required this.metThisYear,
  });

  final ImportantPerson person;
  final FamilyTime time;
  final int metThisYear;

  static Future<void> show(
    BuildContext context, {
    required ImportantPerson person,
    required FamilyTime time,
    required int metThisYear,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) =>
          ShareCardSheet(person: person, time: time, metThisYear: metThisYear),
    );
  }

  @override
  State<ShareCardSheet> createState() => _ShareCardSheetState();
}

class _ShareCardSheetState extends State<ShareCardSheet> {
  final _key = GlobalKey();
  bool _sharing = false;

  /// 画像のいちばん大きな数字（増えていく数字を優先する）
  (String, String, String) _headline() {
    final p = widget.person;
    final days = NextMeetRow.daysUntil(p);
    if (widget.metThisYear > 0) {
      return ('${p.nickname}と、今年会えた日', '${widget.metThisYear}', '日');
    }
    if (days != null && days > 0) {
      return ('${p.nickname}に会えるまで、あと', '$days', '日');
    }
    if (p.relation == Relation.child && widget.time.summersAtHome != null) {
      return (
        '${p.nickname}と一緒に暮らす夏休みは、これから',
        '${widget.time.summersAtHome}',
        '回',
      );
    }
    return ('${p.nickname}と、これから会えるのは 約', '${widget.time.meetCount}', '回');
  }

  Future<void> _share() async {
    setState(() => _sharing = true);
    try {
      final boundary =
          _key.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/lifecounter_share.png');
      await file.writeAsBytes(bytes!.buffer.asUint8List());
      if (!mounted) return;
      final box = context.findRenderObject() as RenderBox?;
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: 'image/png')],
          text: '家族と過ごせる時間を、数えて残すアプリ LifeCounter\n$appStoreUrl',
          sharePositionOrigin: box != null
              ? box.localToGlobal(Offset.zero) & box.size
              : null,
        ),
      );
    } catch (e) {
      debugPrint('Share error: $e');
      if (mounted) AppToast.error(context, '共有できませんでした');
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final (label, value, unit) = _headline();
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RepaintBoundary(
              key: _key,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(28, 36, 28, 24),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4E7DC),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  children: [
                    Text(
                      label,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.zenKakuGothicNew(
                        fontSize: 15,
                        color: AppColors.textSecondary,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: value,
                            style: GoogleFonts.cormorantGaramond(
                              fontSize: 88,
                              fontWeight: FontWeight.w300,
                              color: AppColors.accent,
                              height: 1.1,
                            ),
                          ),
                          TextSpan(
                            text: ' $unit',
                            style: GoogleFonts.zenKakuGothicNew(
                              fontSize: 18,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    Text(
                      'LifeCounter  家族と過ごせる時間',
                      style: GoogleFonts.zenKakuGothicNew(
                        fontSize: 11,
                        letterSpacing: 1,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            AppButton.primary(
              onPressed: _sharing ? null : _share,
              label: _sharing ? '準備しています…' : '画像を共有する',
            ),
          ],
        ),
      ),
    );
  }
}
