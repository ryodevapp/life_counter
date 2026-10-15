import 'package:flutter/material.dart';
import '../../services/great_person_service.dart';
import '../shared/app_colors.dart';
import '../shared/app_spacing.dart';
import '../shared/app_text_styles.dart';
import '../shared/app_card.dart';
import '../shared/pill_label.dart';

/// 今日の偉人カード（プロトタイプにはないがPRD Epic 4に基づく実装）
class GreatPersonCard extends StatefulWidget {
  const GreatPersonCard({super.key, required this.userAge});
  final int userAge;

  @override
  State<GreatPersonCard> createState() => _GreatPersonCardState();
}

class _GreatPersonCardState extends State<GreatPersonCard> {
  Map<String, dynamic>? _episode;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final ep = await GreatPersonService.todayEpisode(widget.userAge);
    if (mounted) setState(() => _episode = ep);
  }

  @override
  Widget build(BuildContext context) {
    if (_episode == null) return const SizedBox.shrink();
    final ep = _episode!;

    return AppCard(
      onTap: () => _showDetail(context, ep),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              PillLabel(text: _typeEmoji(ep['type'] as String)),
              const SizedBox(width: AppSpacing.s),
              Text('今日の偉人', style: AppTextStyles.captionLabel),
            ],
          ),
          const SizedBox(height: AppSpacing.m),
          Text(
            '${ep['achieveAge']}歳の時、${ep['name']}は${ep['text']}',
            style: AppTextStyles.callout,
          ),
        ],
      ),
    );
  }

  String _typeEmoji(String type) {
    switch (type) {
      case '奮起':
        return '\u{1F525}'; // 🔥
      case '勇気':
        return '\u{1F981}'; // 🦁
      case '気づき':
        return '\u{1F4A1}'; // 💡
      case '発奮':
        return '\u2B50'; // ⭐
      default:
        return '\u2728';
    }
  }

  void _showDetail(BuildContext context, Map<String, dynamic> ep) {
    final achievements = List<Map<String, dynamic>>.from(
      ep['achievements'] ?? [],
    );
    final birth = ep['birth'];
    final death = ep['death'];
    final lifespan = death != null ? '$birth - $death' : '$birth -';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.75,
        ),
        decoration: const BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.sheet),
          ),
        ),
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.bgSub,
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(ep['name'] as String, style: AppTextStyles.title),
              const SizedBox(height: AppSpacing.xs),
              Text(lifespan, style: AppTextStyles.footnote),
              const SizedBox(height: AppSpacing.l),
              // 業績リスト
              for (final a in achievements) ...[
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.m),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${a['age']}歳',
                        style: AppTextStyles.headline.copyWith(
                          color: AppColors.accent,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.l),
                      Expanded(
                        child: Text(
                          a['text'] as String,
                          style: AppTextStyles.callout,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (ep['quote'] != null) ...[
                const SizedBox(height: AppSpacing.l),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.l),
                  decoration: BoxDecoration(
                    color: AppColors.bgWarm,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Text(
                    '「${ep['quote']}」',
                    style: AppTextStyles.callout.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
