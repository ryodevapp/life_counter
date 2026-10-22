import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/isar_provider.dart';
import '../../l10n/l10n.dart';
import '../shared/app_segmented_control.dart';
import '../shared/app_spacing.dart';
import '../shared/readable_width.dart';
import '../shared/page_header.dart';
import 'your_time_section.dart';
import 'important_people_section.dart';
import 'bucket_section.dart';

/// 人生タブ（セグメンテッドコントロール付き）
class LifeTabPage extends ConsumerStatefulWidget {
  const LifeTabPage({super.key});

  @override
  ConsumerState<LifeTabPage> createState() => _LifeTabPageState();
}

class _LifeTabPageState extends ConsumerState<LifeTabPage> {
  _LifeSegment _segment = _LifeSegment.time;
  bool _chosen = false;

  @override
  void initState() {
    super.initState();
    // まだ誰も登録していなければ「大切な人」から見せる(家族と過ごす時間が、このアプリの軸なので)
    ref.read(importantPersonRepositoryProvider).getAll().then((people) {
      if (mounted && !_chosen && people.isEmpty) {
        setState(() => _segment = _LifeSegment.people);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return SafeArea(
      child: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.screen, AppSpacing.l, AppSpacing.screen, 130),
        child: ReadableWidth(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PageHeader(l.tabLife),
              AppSegmentedControl<_LifeSegment>(
                items: [
                  SegmentItem(value: _LifeSegment.time, label: l.segmentYou),
                  SegmentItem(value: _LifeSegment.people, label: l.segmentPeople),
                  SegmentItem(
                      value: _LifeSegment.bucket, label: l.segmentBucketList),
                ],
                selectedValue: _segment,
                onChanged: (v) => setState(() {
                  _chosen = true;
                  _segment = v;
                }),
              ),
              const SizedBox(height: AppSpacing.xl),
              switch (_segment) {
                _LifeSegment.time => const YourTimeSection(),
                _LifeSegment.people => const ImportantPeopleSection(),
                _LifeSegment.bucket => const BucketSection(),
              },
            ],
          ),
        ),
      ),
    );
  }
}

enum _LifeSegment { time, people, bucket }
