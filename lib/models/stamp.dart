/// 今日の問いに、言葉のかわりに答えるスタンプ
class Stamp {
  const Stamp({required this.id, required this.emoji, required this.label});

  final String id;
  final String emoji;
  final String label;
}

/// 並び順は画面とウィジェットで共通。id は保存に使うので変えない
const stamps = <Stamp>[
  Stamp(id: 'calm', emoji: '😌', label: 'おだやか'),
  Stamp(id: 'smile', emoji: '🙂', label: 'にっこり'),
  Stamp(id: 'happy', emoji: '😊', label: 'うれしい'),
  Stamp(id: 'warm', emoji: '🥰', label: 'あたたかい'),
  Stamp(id: 'spark', emoji: '✨', label: 'わくわく'),
];

Stamp? stampById(String? id) {
  if (id == null) return null;
  for (final s in stamps) {
    if (s.id == id) return s;
  }
  return null;
}
