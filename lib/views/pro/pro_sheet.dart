import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/pro_service.dart';
import '../shared/app_button.dart';
import '../shared/app_colors.dart';
import '../shared/app_toast.dart';

/// Pro の案内（家族の4人目を登録しようとしたとき、設定から開く）
class ProSheet extends ConsumerWidget {
  const ProSheet({super.key, this.reachedLimit = false, this.afterMemory = false});

  /// 家族の上限に当たって開いたか
  final bool reachedLimit;

  /// 写真つきの思い出を残した直後に開いたか
  final bool afterMemory;

  static Future<void> show(BuildContext context,
      {bool reachedLimit = false, bool afterMemory = false}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => ProSheet(reachedLimit: reachedLimit, afterMemory: afterMemory),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pro = ref.watch(proProvider);
    final notifier = ref.read(proProvider.notifier);

    ref.listen(proProvider, (prev, next) {
      if (prev?.isPro == false && next.isPro) {
        Navigator.of(context).maybePop();
        AppToast.success(context, 'Pro になりました。ありがとうございます');
      }
    });

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 28, 28, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('LifeCounter Pro',
                style: GoogleFonts.zenKakuGothicNew(
                    fontSize: 20, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(
              reachedLimit
                  ? '無料で登録できる家族は$freeFamilyLimit人までです。\n両親、義理の両親、子どもたち。家族みんなを登録できます。'
                  : afterMemory
                      ? 'いま残した思い出を、ホーム画面に。\n毎日、家族の写真が目に入ります。'
                      : '家族みんなを登録して、一緒に過ごせる時間を大切に。',
              style: GoogleFonts.zenKakuGothicNew(
                  fontSize: 14, height: 1.8, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
            _point('家族を4人以上登録できます'),
            _point('家族の写真が、ホーム画面に表示されます'),
            _point('会えた日の写真が、思い出として並びます'),
            _point('1年のふりかえりを、写真つきの1枚にできます'),
            _point('購入した人の家族も使えます'),
            _point('買い切りです。毎月の支払いはありません'),
            const SizedBox(height: 24),
            if (pro.isPro)
              Text('Pro を使っています。ありがとうございます',
                  style: GoogleFonts.zenKakuGothicNew(
                      fontSize: 14, color: AppColors.accent))
            else ...[
              AppButton.primary(
                onPressed: pro.busy
                    ? null
                    : () async {
                        final ok = await notifier.buy();
                        if (!ok && context.mounted && pro.price == null) {
                          AppToast.error(context,
                              'いまはストアにつながりません。時間をおいてお試しください');
                        }
                      },
                label: pro.busy
                    ? '処理しています…'
                    : pro.price != null
                        ? '${pro.price}で購入する'
                        : '購入する',
              ),
              const SizedBox(height: 4),
              Center(
                child: TextButton(
                  onPressed: pro.busy ? null : notifier.restore,
                  child: Text('購入を復元する',
                      style: GoogleFonts.zenKakuGothicNew(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static Widget _point(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(Icons.check, size: 18, color: AppColors.accent),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text,
                style: GoogleFonts.zenKakuGothicNew(fontSize: 14, height: 1.6)),
          ),
        ]),
      );
}
