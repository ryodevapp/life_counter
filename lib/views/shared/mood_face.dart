import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'mood_shape.dart';

/// 気分の顔(細い線で描く。表情はおもに目で出す)
/// - [tint] があれば、うすい色の丸を敷く。null なら線だけ
class MoodFace extends StatelessWidget {
  const MoodFace({
    super.key,
    required this.moodId,
    this.size = 44,
    this.ink = const Color(0xFF4A4039),
    this.tint,
    this.stroke,
  });

  final String moodId;
  final double size;
  final Color ink;
  final Color? tint;

  /// 線の太さ。null なら大きさに合わせる(44 で 1.6)
  final double? stroke;

  @override
  Widget build(BuildContext context) => CustomPaint(
        size: Size.square(size),
        painter: _FacePainter(
            moodId, ink, tint, stroke ?? (size / 27.5).clamp(1.0, 2.2)),
      );
}

class _FacePainter extends CustomPainter {
  _FacePainter(this.moodId, this.ink, this.tint, this.stroke);

  final String moodId;
  final Color ink;
  final Color? tint;
  final double stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final c = Offset(s / 2, s / 2);
    final r = s / 2 - stroke;
    if (tint != null) {
      canvas.drawCircle(c, r, Paint()..color = tint!);
    }
    final line = Paint()
      ..color = ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    // 輪郭は細く(丸を敷かないときだけ)
    if (tint == null) canvas.drawCircle(c, r, line);
    final dot = Paint()..color = ink;

    // 目の位置と大きさ(顔の大きさに対する割合)
    final ex = s * 0.17, ey = s * 0.42, ew = s * 0.11;
    final le = Offset(c.dx - ex, ey), re = Offset(c.dx + ex, ey);
    final mouthY = s * 0.64;

    void arc(Offset center, double w, double h, {required bool up}) {
      // 上に凸(笑った目・下がった口)か、下に凸(ほほえみ)の弧
      final p = Path()
        ..moveTo(center.dx - w / 2, center.dy)
        ..quadraticBezierTo(
            center.dx, center.dy + (up ? -h : h), center.dx + w / 2, center.dy);
      canvas.drawPath(p, line);
    }

    switch (moodId) {
      case 'happy':
        arc(le, ew * 1.3, s * 0.08, up: true);
        arc(re, ew * 1.3, s * 0.08, up: true);
        arc(Offset(c.dx, mouthY), s * 0.3, s * 0.12, up: false);
      case 'calm':
        // 閉じた、ゆるんだ目
        arc(le, ew * 1.3, s * 0.06, up: false);
        arc(re, ew * 1.3, s * 0.06, up: false);
        arc(Offset(c.dx, mouthY + s * 0.01), s * 0.18, s * 0.05, up: false);
      case 'neutral':
        canvas.drawCircle(le, stroke * 1.15, dot);
        canvas.drawCircle(re, stroke * 1.15, dot);
        canvas.drawLine(Offset(c.dx - s * 0.1, mouthY),
            Offset(c.dx + s * 0.1, mouthY), line);
      case 'tired':
        // 外側に少し下がった、とじかけの目と、小さな波の口(ふてくされた顔に見せない)
        canvas.drawLine(Offset(le.dx - ew * 0.7, le.dy + s * 0.025),
            Offset(le.dx + ew * 0.6, le.dy - s * 0.005), line);
        canvas.drawLine(Offset(re.dx + ew * 0.7, re.dy + s * 0.025),
            Offset(re.dx - ew * 0.6, re.dy - s * 0.005), line);
        final w = s * 0.2, y = mouthY + s * 0.02;
        final mouth = Path()
          ..moveTo(c.dx - w / 2, y)
          ..quadraticBezierTo(c.dx - w / 4, y - s * 0.035, c.dx, y)
          ..quadraticBezierTo(c.dx + w / 4, y + s * 0.035, c.dx + w / 2, y);
        canvas.drawPath(mouth, line);
      case 'sad':
        // 下がった眉と点の目、下がった口(深刻にしすぎない小ささ)
        canvas.drawCircle(Offset(le.dx, le.dy + s * 0.02), stroke * 1.1, dot);
        canvas.drawCircle(Offset(re.dx, re.dy + s * 0.02), stroke * 1.1, dot);
        canvas.drawLine(Offset(le.dx - ew * 0.6, le.dy - s * 0.1),
            Offset(le.dx + ew * 0.5, le.dy - s * 0.13), line);
        canvas.drawLine(Offset(re.dx + ew * 0.6, re.dy - s * 0.1),
            Offset(re.dx - ew * 0.5, re.dy - s * 0.13), line);
        arc(Offset(c.dx, mouthY + s * 0.04), s * 0.22, s * 0.07, up: true);
    }
  }

  @override
  bool shouldRepaint(_FacePainter old) =>
      old.moodId != moodId || old.ink != ink || old.tint != tint;
}

/// アプリで使う気分の顔: 気分の色のうすい丸 + 同じ色系の線(案1)
class MoodBadge extends StatelessWidget {
  const MoodBadge({super.key, required this.moodId, this.size = 20});

  final String moodId;
  final double size;

  @override
  Widget build(BuildContext context) {
    final look = moodLooks[moodId];
    if (look == null) return SizedBox.square(dimension: size);
    return MoodFace(
      moodId: moodId,
      size: size,
      ink: look.ink,
      // 暗い地では薄い色がにごるので、色をそのまま使う
      tint: AppColors.dark ? look.light : look.light.withValues(alpha: 0.6),
    );
  }
}
