import 'package:flutter/material.dart';
import 'app_colors.dart';

/// 気分ごとの色(design/design-system.md の「気分」)。顔は mood_face.dart の MoodFace で描く
/// - 快い気分は暖色・セージ、つかれた・かなしいは藤色・くすんだ青(不快な気持ちも、責めずにきれいな色で受け止める)
/// - 同じ値は iOS のウィジェット(ios/LifeWidget/WidgetShared.swift の moodLooks)にもある。直すときは両方そろえる
class MoodLook {
  const MoodLook({required this.light, required this.deep, required this.ink});

  /// うすい色(顔の丸の塗り)
  final Color light;

  /// 濃い色(小さな印)
  final Color deep;

  /// 同じ色系の濃い色。顔の線と文字に使う(背景に対して 5:1 以上)
  final Color ink;
}

const moodLooks = <String, MoodLook>{
  'happy': MoodLook(light: Color(0xFFF4C48A), deep: Color(0xFFE3914F), ink: Color(0xFF9A5A24)),
  'calm': MoodLook(light: Color(0xFFC3D3AC), deep: Color(0xFF9DB384), ink: Color(0xFF56693F)),
  'neutral': MoodLook(light: Color(0xFFE2D3B5), deep: Color(0xFFC7B28A), ink: Color(0xFF7D6A4F)),
  'tired': MoodLook(light: Color(0xFFC2B8D2), deep: Color(0xFF9C90B0), ink: Color(0xFF625776)),
  'sad': MoodLook(light: Color(0xFFAFC3D3), deep: Color(0xFF86A1B7), ink: Color(0xFF44607A)),
};

/// 気分の名前の文字の色(明るい表示は濃い線の色、暗い表示は明るい色にして読めるように)
Color? moodTextColor(String id) {
  final look = moodLooks[id];
  if (look == null) return null;
  return AppColors.dark ? look.light : look.ink;
}
