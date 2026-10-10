import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/meeting_log.dart';
import '../../providers/important_person_provider.dart';
import '../../providers/isar_provider.dart';
import '../../services/contact_stats.dart';
import '../../services/photo_store.dart';
import '../../services/pro_service.dart';
import '../family/family_avatar.dart';
import '../family/share_card_sheet.dart' show appStoreUrl;
import '../pro/pro_sheet.dart';
import '../shared/app_button.dart';
import '../shared/app_colors.dart';
import '../shared/app_toast.dart';

/// 1年のふりかえり。数字は無料、写真つきの1枚(保存・共有)は Pro
class YearReviewPage extends ConsumerStatefulWidget {
  const YearReviewPage({super.key});

  static Future<void> open(BuildContext context) => Navigator.of(context)
      .push(MaterialPageRoute(builder: (_) => const YearReviewPage()));

  @override
  ConsumerState<YearReviewPage> createState() => _YearReviewPageState();
}

class _YearReviewPageState extends ConsumerState<YearReviewPage> {
  final _key = GlobalKey();
  bool _sharing = false;

  Future<void> _share() async {
    setState(() => _sharing = true);
    try {
      final boundary = _key.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/lifecounter_year.png');
      await file.writeAsBytes(bytes!.buffer.asUint8List());
      if (!mounted) return;
      final box = context.findRenderObject() as RenderBox?;
      await SharePlus.instance.share(ShareParams(
        files: [XFile(file.path, mimeType: 'image/png')],
        text: '家族とつながった1年 — LifeCounter\n$appStoreUrl',
        sharePositionOrigin: box != null ? box.localToGlobal(Offset.zero) & box.size : null,
      ));
    } catch (e) {
      if (mounted) AppToast.error(context, '共有できませんでした');
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final year = DateTime.now().year;
    final persons = ref.watch(importantPersonsProvider).valueOrNull ?? const [];
    final logs = (ref.watch(meetingLogsProvider).valueOrNull ?? const <MeetingLog>[])
        .where((l) => l.date.year == year)
        .toList();
    final isPro = ref.watch(proProvider).isPro;
    final photos = logs.where((l) => PhotoStore.file(l.photoFile) != null).take(9).toList();
    final metDays = ContactStats.familyMetThisYear(logs);
    final connectedDays = logs
        .map((l) => DateTime(l.date.year, l.date.month, l.date.day))
        .toSet()
        .length;

    final card = RepaintBoundary(
      key: _key,
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
        decoration: BoxDecoration(
          color: const Color(0xFFF4E7DC),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('$year年', style: GoogleFonts.zenKakuGothicNew(fontSize: 13, color: AppColors.textMuted)),
          const SizedBox(height: 4),
          Text('家族とつながった日',
              style: GoogleFonts.zenKakuGothicNew(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            _big('$connectedDays', '日'),
            const SizedBox(width: 20),
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text('そのうち会えた日 $metDays日',
                  style: GoogleFonts.zenKakuGothicNew(fontSize: 13, color: AppColors.textSecondary)),
            ),
          ]),
          const SizedBox(height: 12),
          for (final p in persons)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(children: [
                FamilyAvatar(name: p.nickname, photoFile: p.photoFile, size: 30),
                const SizedBox(width: 10),
                Expanded(child: Text(p.nickname, style: GoogleFonts.zenKakuGothicNew(fontSize: 14))),
                Text('会えた ${ContactStats.metThisYear(logs, p.id)}日 ・ つながった ${_daysFor(logs, p.id)}日',
                    style: GoogleFonts.zenKakuGothicNew(fontSize: 12, color: AppColors.textSecondary)),
              ]),
            ),
          if (photos.isNotEmpty) ...[
            const SizedBox(height: 14),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
              children: [
                for (final l in photos)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(PhotoStore.file(l.photoFile)!, fit: BoxFit.cover),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          Text('LifeCounter  家族と過ごせる時間',
              style: GoogleFonts.zenKakuGothicNew(fontSize: 10, letterSpacing: 1, color: AppColors.textMuted)),
        ]),
      ),
    );

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.accent),
        title: Text('$year年のふりかえり',
            style: GoogleFonts.zenKakuGothicNew(fontSize: 16, color: AppColors.text)),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            // 数字は無料。写真を並べた1枚(保存・共有)は Pro
            if (isPro)
              card
            else
              Stack(children: [
                card,
                if (photos.isNotEmpty)
                  Positioned.fill(
                    top: 230,
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
                      child: BackdropFilter(
                        filter: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                        child: Container(color: Colors.white.withValues(alpha: 0.2)),
                      ),
                    ),
                  ),
              ]),
            const SizedBox(height: 20),
            if (isPro)
              AppButton.primary(
                  onPressed: _sharing ? null : _share,
                  label: _sharing ? '準備しています…' : 'この1枚を保存・共有する')
            else ...[
              Text('写真を並べた1枚にして、保存したり、家族に送ったりできます(LifeCounter Pro)',
                  style: GoogleFonts.zenKakuGothicNew(fontSize: 13, height: 1.7, color: AppColors.textSecondary)),
              const SizedBox(height: 12),
              AppButton.primary(onPressed: () => ProSheet.show(context), label: 'LifeCounter Pro を見る'),
            ],
          ],
        ),
      ),
    );
  }

  static int _daysFor(List<MeetingLog> logs, int personId) => logs
      .where((l) => l.personId == personId)
      .map((l) => DateTime(l.date.year, l.date.month, l.date.day))
      .toSet()
      .length;

  static Widget _big(String v, String unit) => Text.rich(TextSpan(children: [
        TextSpan(
            text: v,
            style: GoogleFonts.cormorantGaramond(fontFeatures: const [FontFeature.liningFigures()], 
                fontSize: 64, fontWeight: FontWeight.w300, color: AppColors.accent, height: 1.0)),
        TextSpan(text: ' $unit', style: GoogleFonts.zenKakuGothicNew(fontSize: 16, color: AppColors.textMuted)),
      ]));
}
