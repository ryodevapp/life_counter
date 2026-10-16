import 'package:flutter/material.dart';
import '../../l10n/l10n.dart';
import '../shared/app_segmented_control.dart';
import '../shared/app_spacing.dart';
import '../shared/page_header.dart';
import 'your_time_section.dart';
import 'important_people_section.dart';
import 'bucket_section.dart';

/// 人生タブ（セグメンテッドコントロール付き）
class LifeTabPage extends StatefulWidget {
  const LifeTabPage({super.key});

  @override
  State<LifeTabPage> createState() => _LifeTabPageState();
}

class _LifeTabPageState extends State<LifeTabPage> {
  _LifeSegment _segment = _LifeSegment.time;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return SafeArea(
      child: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.screen, AppSpacing.l, AppSpacing.screen, 130),
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
              onChanged: (v) => setState(() => _segment = v),
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
    );
  }
}

enum _LifeSegment { time, people, bucket }
