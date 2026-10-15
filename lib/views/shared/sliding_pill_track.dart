import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';
import 'app_spacing.dart';

/// 項目を均等の幅に並べ、選んだ項目の下にカプセルの印を敷く(下のタブと上の切り替えで共通)
/// - 印はばねで移る。動いている間は進む向きに少し伸びる(iOS 26 の Liquid Glass と同じ考え方)
/// - 指でなぞって選べる。なぞっている間は印が少し浮く
/// - 「視差効果を減らす」がオンのときは、伸び・浮きをやめて、すぐ移す
class SlidingPillTrack extends StatefulWidget {
  const SlidingPillTrack({
    super.key,
    required this.count,
    required this.index,
    required this.onSelect,
    required this.itemBuilder,
    required this.pillDecoration,
    this.pillInset = 4,
  });

  final int count;
  final int index;
  final ValueChanged<int> onSelect;

  /// [selectedness] は 0(選んでいない)〜1(選んでいる)。印が動く途中は間の値になる
  final Widget Function(BuildContext context, int i, double selectedness)
      itemBuilder;
  final Decoration pillDecoration;
  final double pillInset;

  @override
  State<SlidingPillTrack> createState() => _SlidingPillTrackState();
}

class _SlidingPillTrackState extends State<SlidingPillTrack>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pos =
      AnimationController.unbounded(vsync: this, value: widget.index.toDouble());
  bool _dragging = false;
  double _segment = 1;

  bool get _reduceMotion => MediaQuery.disableAnimationsOf(context);

  @override
  void didUpdateWidget(SlidingPillTrack old) {
    super.didUpdateWidget(old);
    if (widget.index != old.index && !_dragging) _moveTo(widget.index);
  }

  @override
  void dispose() {
    _pos.dispose();
    super.dispose();
  }

  void _moveTo(int target, {double velocity = 0}) {
    if (_reduceMotion) {
      _pos.value = target.toDouble();
      return;
    }
    _pos.animateWith(SpringSimulation(
        AppMotion.spring, _pos.value, target.toDouble(), velocity));
  }

  void _select(int i) {
    if (i != widget.index) {
      HapticFeedback.selectionClick();
      widget.onSelect(i);
    } else {
      // 同じ項目を押したときも知らせる(もう一度押すと最新にする、などに使う)
      widget.onSelect(i);
      _moveTo(i);
    }
  }

  int _indexAt(double dx) =>
      (dx / _segment).floor().clamp(0, widget.count - 1);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      _segment = constraints.maxWidth / widget.count;
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapUp: (d) => _select(_indexAt(d.localPosition.dx)),
        onHorizontalDragStart: (d) {
          _pos.stop();
          setState(() => _dragging = true);
        },
        onHorizontalDragUpdate: (d) {
          _pos.value = (_pos.value + d.delta.dx / _segment)
              .clamp(0.0, widget.count - 1.0);
        },
        onHorizontalDragEnd: (d) {
          final v = d.velocity.pixelsPerSecond.dx / _segment;
          // 勢いよく払ったら、その向きに1つ進める
          final projected = _pos.value + (v * 0.08).clamp(-0.6, 0.6);
          final target = projected.round().clamp(0, widget.count - 1);
          setState(() => _dragging = false);
          _moveTo(target, velocity: v);
          if (target != widget.index) {
            HapticFeedback.selectionClick();
            widget.onSelect(target);
          }
        },
        onHorizontalDragCancel: () {
          setState(() => _dragging = false);
          _moveTo(widget.index);
        },
        child: AnimatedBuilder(
          animation: _pos,
          builder: (context, _) {
            final p = _pos.value;
            // 動きの速さに合わせて横に伸び、少しだけ縦に縮む(最大 18%)
            final stretch = _reduceMotion
                ? 0.0
                : (_pos.velocity.abs() * 0.035).clamp(0.0, 0.18);
            final lift = _dragging && !_reduceMotion ? 1.0 : 0.0;
            final inset = widget.pillInset;
            final baseW = _segment - inset * 2;
            final w = baseW * (1 + stretch);
            final hShrink = constraints.maxHeight * stretch * 0.25;
            return Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left: p * _segment + inset - (w - baseW) / 2,
                  width: w,
                  top: inset + hShrink / 2,
                  bottom: inset + hShrink / 2,
                  child: AnimatedScale(
                    scale: 1 + 0.06 * lift,
                    duration: AppMotion.fast,
                    curve: Curves.easeOutCubic,
                    child: DecoratedBox(decoration: widget.pillDecoration),
                  ),
                ),
                Row(
                  children: [
                    for (var i = 0; i < widget.count; i++)
                      Expanded(
                        child: widget.itemBuilder(
                          context,
                          i,
                          (1 - (p - i).abs()).clamp(0.0, 1.0),
                        ),
                      ),
                  ],
                ),
              ],
            );
          },
        ),
      );
    });
  }
}
