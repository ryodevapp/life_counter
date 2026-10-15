/// 「今日の問い」1問ぶん。`assets/data/questions_v2.json` の1件に対応する。
class Question {
  /// 問いの id。いまの25問は昔の id(`p1` など)をそのまま使う。
  final String id;

  /// 分類: `self`・`people`・`life`・`bucket` のどれか。
  final String category;

  /// 問いの文。
  final String text;

  /// 1〜365。この問いを出す日(`questionDayOfYear` の値)。
  final int dayOfYear;

  /// もう一歩の問い。答えを書いたあとにだけ、小さく出す(「なぜ」ではなく「何が・どんな」で深める)
  final String? followUp;

  const Question({
    required this.id,
    required this.category,
    required this.text,
    required this.dayOfYear,
    this.followUp,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id'] as String,
      category: json['category'] as String,
      text: json['text'] as String,
      dayOfYear: json['dayOfYear'] as int,
      followUp: json['followUp'] as String?,
    );
  }

  /// やりたいことリストにつながる問いかどうか。
  bool get isBucket => category == 'bucket';
}

/// 問いと、理由を聞くもう一歩を1つの文にする(「没頭したいことは？ それに惹かれるのは、なぜ？」)
String questionWithFollowUp(Question q) =>
    q.followUp == null ? q.text : '${q.text} ${q.followUp}';
