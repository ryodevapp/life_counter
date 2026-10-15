import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/important_person.dart';
import '../../models/user_settings.dart';
import '../../providers/important_person_provider.dart';
import '../../providers/isar_provider.dart';
import '../../providers/question_bank_provider.dart';
import '../../providers/user_settings_provider.dart';
import '../../services/record_export.dart';
import '../../services/notification_service.dart';
import '../shared/app_colors.dart';
import '../shared/app_spacing.dart';
import '../shared/app_toast.dart';
import '../shared/app_text_styles.dart';
import '../shared/app_card.dart';
import '../shared/page_header.dart';
import '../shared/sheet_handle.dart';

/// この端末に入っているアプリの版(表示とフィードバックのメールで使う)
final Future<PackageInfo> _packageInfo = PackageInfo.fromPlatform();

/// マイページタブ（プロトタイプのMyPageTab再現 + Epic 9 設定編集UI）
class MyPage extends ConsumerWidget {
  const MyPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(userSettingsProvider);
    final bd = settings.birthDate;
    final bdText = bd != null ? '${bd.year}年${bd.month}月${bd.day}日' : '未設定';
    final genText = switch (settings.gender) {
      Gender.male => '男性',
      Gender.female => '女性',
      Gender.unspecified => '答えない',
    };
    final notifText = settings.notificationEnabled
        ? '${settings.notificationHour}:${settings.notificationMinute.toString().padLeft(2, '0')}'
        : 'オフ';
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.screen, AppSpacing.l, AppSpacing.screen, 130),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const PageHeader('設定'),

            AppCard(
              padding: _groupPadding,
              child: Column(
                children: [
                  _row(
                    CupertinoIcons.gift, '生年月日', value: bdText,
                    onTap: () => _editBirthDate(context, ref, settings),
                  ),
                  _divider(),
                  _row(
                    CupertinoIcons.person, '性別', value: genText,
                    onTap: () => _editGender(context, ref, settings),
                  ),
                  _divider(),
                  _row(
                    CupertinoIcons.bell, '朝の通知', value: notifText,
                    onTap: () => _editNotification(context, ref, settings),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            AppCard(
              padding: _groupPadding,
              child: Column(
                children: [
                  _row(CupertinoIcons.square_arrow_up, '記録を書き出す',
                      onTap: () => _exportRecords(context, ref)),
                  _divider(),
                  _row(CupertinoIcons.envelope, 'フィードバックを送る',
                      onTap: () => _sendFeedback(context)),
                  _divider(),
                  _row(CupertinoIcons.lock, 'プライバシーポリシー',
                      onTap: () => _showLegal(context, 'privacy_policy.html',
                          'プライバシーポリシー')),
                  _divider(),
                  _row(CupertinoIcons.doc_text, '利用規約',
                      onTap: () => _showLegal(
                          context, 'terms_of_service.html', '利用規約')),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.section),

            Center(
              child: FutureBuilder<PackageInfo>(
                future: _packageInfo,
                builder: (context, snapshot) => Text(
                  snapshot.hasData
                      ? 'バージョン ${snapshot.data!.version}'
                      : 'LifeCounter',
                  style: AppTextStyles.footnote,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── フィードバック ───

  Future<void> _sendFeedback(BuildContext context) async {
    String version = '';
    try {
      version = ' v${(await _packageInfo).version}';
    } catch (_) {
      // 版が読めなくても、メールは開く
    }
    final uri = Uri(
      scheme: 'mailto',
      path: 'ryo.nakano.biz+lifecounter@gmail.com',
      query: 'subject=LifeCounter フィードバック&body=\n\n---\nLifeCounter$version',
    );
    await launchUrl(uri);
  }

  // ─── 法的ページ ───

  void _showLegal(BuildContext context, String fileName, String title) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _LegalPage(fileName: fileName, title: title),
      ),
    );
  }

  // ─── 設定編集 ───

  void _editBirthDate(
      BuildContext context, WidgetRef ref, UserSettings settings) async {
    final current = settings.birthDate ?? DateTime(1995, 1, 1);
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      await ref
          .read(userSettingsProvider.notifier)
          .setBirthDateAndGender(picked, settings.gender);
    }
  }

  void _editGender(
      BuildContext context, WidgetRef ref, UserSettings settings) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl, AppSpacing.m, AppSpacing.xl, AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SheetHandle(),
              const SizedBox(height: AppSpacing.l),
              Text('性別', style: AppTextStyles.headline),
              const SizedBox(height: AppSpacing.l),
              for (final g in [
                (Gender.male, '男性'),
                (Gender.female, '女性'),
                (Gender.unspecified, '答えない'),
              ])
                ListTile(
                  title: Text(g.$2, style: AppTextStyles.callout),
                  trailing: settings.gender == g.$1
                      ? const Icon(CupertinoIcons.checkmark, color: AppColors.accent)
                      : null,
                  onTap: () async {
                    Navigator.of(ctx).pop();
                    if (settings.birthDate != null) {
                      await ref
                          .read(userSettingsProvider.notifier)
                          .setBirthDateAndGender(settings.birthDate!, g.$1);
                    }
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _editNotification(
      BuildContext context, WidgetRef ref, UserSettings settings) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl, AppSpacing.m, AppSpacing.xl, AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SheetHandle(),
              const SizedBox(height: AppSpacing.l),
              Text('朝の通知', style: AppTextStyles.headline),
              const SizedBox(height: AppSpacing.l),
              SwitchListTile(
                title: Text('朝の通知', style: AppTextStyles.callout),
                value: settings.notificationEnabled,
                activeTrackColor: AppColors.accent,
                onChanged: (v) async {
                  if (v) {
                    await NotificationService.requestPermission();
                  }
                  await ref
                      .read(userSettingsProvider.notifier)
                      .updateNotification(
                        enabled: v,
                        hour: settings.notificationHour,
                        minute: settings.notificationMinute,
                      );
                  if (ctx.mounted) Navigator.of(ctx).pop();
                },
              ),
              ListTile(
                title: Text('時刻', style: AppTextStyles.callout),
                trailing: Text(
                  '${settings.notificationHour}:${settings.notificationMinute.toString().padLeft(2, '0')}',
                  style: AppTextStyles.callout
                      .copyWith(color: AppColors.textMuted),
                ),
                onTap: () async {
                  Navigator.of(ctx).pop();
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay(
                      hour: settings.notificationHour,
                      minute: settings.notificationMinute,
                    ),
                  );
                  if (picked != null) {
                    if (picked.hour < 5 || picked.hour > 11) {
                      if (context.mounted) {
                        AppToast.error(context,
                            '通知は 5:00〜11:00 の間で選べます');
                      }
                      return;
                    }
                    await ref
                        .read(userSettingsProvider.notifier)
                        .updateNotification(
                          enabled: settings.notificationEnabled,
                          hour: picked.hour,
                          minute: picked.minute,
                        );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── UI ───

  /// マイページの行。どの行も「線のアイコン・項目・(値)・›」の同じ形
  static Widget _row(IconData icon, String label,
      {String? value, VoidCallback? onTap}) {
    return Semantics(
      button: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 52),
          child: Row(
            children: [
              // iOS の設定の行と同じ並び: アイコン・項目名・今の値・小さな矢印
              Icon(icon, size: 22, color: AppColors.accent),
              const SizedBox(width: AppSpacing.m),
              Expanded(
                  child: Text(label,
                      style: AppTextStyles.body.copyWith(height: 1.3))),
              if (value != null)
                Text(value,
                    style: AppTextStyles.body
                        .copyWith(height: 1.3, color: AppColors.textMuted)),
              const SizedBox(width: AppSpacing.s),
              const Icon(CupertinoIcons.chevron_right,
                  size: 15, color: AppColors.textDisabled),
            ],
          ),
        ),
      ),
    );
  }

  /// 記録をテキストにして共有シートに渡す(ファイルは作らない)
  static Future<void> _exportRecords(BuildContext context, WidgetRef ref) async {
    final box = context.findRenderObject() as RenderBox?;
    final records = await ref.read(dailyRecordRepositoryProvider).getAll();
    final buckets = await ref.read(bucketItemRepositoryProvider).getAll();
    final persons = ref.read(importantPersonsProvider).valueOrNull ?? const [];
    final text = exportRecordsAsText(
      records,
      buckets,
      ref.read(questionBankProvider),
      personNames: {for (final p in persons) p.id: p.nickname},
    );
    await SharePlus.instance.share(ShareParams(
      text: text,
      subject: 'LifeCounter の記録',
      // iPad は共有の吹き出しの位置が要る
      sharePositionOrigin:
          box == null ? null : box.localToGlobal(Offset.zero) & box.size,
    ));
  }

  // iOS の設定の一覧と同じく、行の上下は詰め、区切り線は文字の頭から
  static const _groupPadding = EdgeInsets.symmetric(
      horizontal: AppSpacing.l, vertical: AppSpacing.xs);

  static Widget _divider() => const Divider(
      height: 1, indent: 22 + AppSpacing.m, color: AppColors.divider);
}

/// 法的ページ（HTML表示）
class _LegalPage extends StatelessWidget {
  const _LegalPage({required this.fileName, required this.title});
  final String fileName;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(title, style: AppTextStyles.headline),
        backgroundColor: AppColors.bg,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.accent),
      ),
      body: FutureBuilder<String>(
        future: DefaultAssetBundle.of(context)
            .loadString('assets/legal/$fileName'),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          // HTMLからbody内テキストをシンプル表示
          final html = snapshot.data!;
          final sections = _parseHtml(html);
          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.screen),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: sections,
            ),
          );
        },
      ),
    );
  }

  List<Widget> _parseHtml(String html) {
    final widgets = <Widget>[];
    // 簡易HTMLパーサー（h2, p, li を抽出）
    final h2Regex = RegExp(r'<h2>(.*?)</h2>');
    final pRegex = RegExp(r'<p(?:\s[^>]*)?>(.*?)</p>', dotAll: true);
    final liRegex = RegExp(r'<li>(.*?)</li>', dotAll: true);

    final lines = html.split('\n');
    for (final line in lines) {
      final h2Match = h2Regex.firstMatch(line);
      if (h2Match != null) {
        widgets.add(const SizedBox(height: AppSpacing.xl));
        widgets.add(Text(
          _stripTags(h2Match.group(1)!),
          style: AppTextStyles.headline.copyWith(color: AppColors.accent),
        ));
        widgets.add(const SizedBox(height: AppSpacing.s));
        continue;
      }
      final pMatch = pRegex.firstMatch(line);
      if (pMatch != null) {
        final text = _stripTags(pMatch.group(1)!).trim();
        if (text.isNotEmpty) {
          widgets.add(Text(
            text,
            style:
                AppTextStyles.callout.copyWith(color: AppColors.textSecondary),
          ));
          widgets.add(const SizedBox(height: AppSpacing.xs));
        }
        continue;
      }
      final liMatch = liRegex.firstMatch(line);
      if (liMatch != null) {
        widgets.add(Padding(
          padding:
              const EdgeInsets.only(left: AppSpacing.l, bottom: AppSpacing.xs),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('・ ',
                  style: AppTextStyles.callout
                      .copyWith(color: AppColors.textSecondary)),
              Expanded(
                child: Text(
                  _stripTags(liMatch.group(1)!).trim(),
                  style: AppTextStyles.callout
                      .copyWith(color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
        ));
      }
    }
    return widgets;
  }

  String _stripTags(String html) {
    return html.replaceAll(RegExp(r'<[^>]*>'), '');
  }
}
