import 'package:flutter/material.dart';
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
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.screen, AppSpacing.l, AppSpacing.screen, 130),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const PageHeader('人生'),
            AppSegmentedControl<_LifeSegment>(
              items: const [
                SegmentItem(value: _LifeSegment.time, label: 'あなた'),
                SegmentItem(value: _LifeSegment.people, label: '大切な人'),
                SegmentItem(value: _LifeSegment.bucket, label: 'バケットリスト'),
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
