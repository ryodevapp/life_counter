/// 「今日はどんな一日だった？」への気分。日替わりの問いへの答えとは別に残す
class Stamp {
  const Stamp({required this.id, required this.emoji, required this.label});

  final String id;
  final String emoji;
  final String label;
}

/// 気分を聞く問い
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
