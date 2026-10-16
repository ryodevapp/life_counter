import 'package:flutter/widgets.dart';
import '../l10n/l10n.dart';

/// 「今日はどんな一日だった？」への気分。日替わりの問いへの答えとは別に残す
class Stamp {
  const Stamp({required this.id, required this.emoji, required this.label});

  final String id;
  final String emoji;
  final String label;
}

/// 気分を聞く問い(日本語の元の文。画面では AppLocalizations.moodQuestion を使う)
const moodQuestion = '今日はどんな一日だった？';

/// 前向き2・ふつう1・後ろ向き2。つらい日にも選べるように。
/// 並び順は画面とウィジェットで共通。id は保存に使うので変えない
const stamps = <Stamp>[
  Stamp(id: 'happy', emoji: '😊', label: 'うれしい'),
  Stamp(id: 'calm', emoji: '😌', label: 'おだやか'),
  Stamp(id: 'neutral', emoji: '😐', label: 'ふつう'),
  Stamp(id: 'tired', emoji: '😩', label: 'つかれた'),
  Stamp(id: 'sad', emoji: '😢', label: 'かなしい'),
];

Stamp? stampById(String? id) {
  if (id == null) return null;
  for (final s in stamps) {
    if (s.id == id) return s;
  }
  return null;
}

/// 気分の名前を、いまの言語で(id は保存に使うので変えない)
String moodLabelOf(AppLocalizations l, String id) => switch (id) {
      'happy' => l.moodHappy,
      'calm' => l.moodCalm,
      'neutral' => l.moodNeutral,
      'tired' => l.moodTired,
      'sad' => l.moodSad,
      _ => stampById(id)?.label ?? id,
    };

/// 画面用: 気分の名前を、端末の言語で
String moodLabel(BuildContext context, String id) =>
    moodLabelOf(AppLocalizations.of(context), id);
