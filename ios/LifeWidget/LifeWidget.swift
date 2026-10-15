import SwiftUI
import WidgetKit

// 1つのウィジェットに役目は1つ。それ以外の情報は載せない
//   小(LifeDaysWidget)     : 人生◯日目だけ
//   中(TodayQuestionWidget): 今日の問い・気分の顔5つ・「書く」(押すとアプリの答えの欄が開く)

struct DayEntry: TimelineEntry {
    let date: Date
    let day: DayInfo?
    let stamp: String?
}

struct DayProvider: TimelineProvider {
    func placeholder(in context: Context) -> DayEntry {
        DayEntry(date: Date(),
                 day: DayInfo(date: ymd(Date()), lifeDays: 12345, question: "最近、時間を忘れて没頭したことは？"),
                 stamp: nil)
    }

    func getSnapshot(in context: Context, completion: @escaping (DayEntry) -> Void) {
        completion(entries(from: Date(), count: 1).first ?? placeholder(in: context))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<DayEntry>) -> Void) {
        // 0時ごとに次の日へ切り替わる。アプリを開かなくても、渡された日数の分だけ続く
        let list = entries(from: Date(), count: 7)
        let after = list.last.map { nextMidnight(after: $0.date) } ?? nextMidnight(after: Date())
        completion(Timeline(entries: list, policy: .after(after)))
    }

    private func entries(from now: Date, count: Int) -> [DayEntry] {
        let days = Dictionary(loadDays().map { ($0.date, $0) }, uniquingKeysWith: { a, _ in a })
        var result: [DayEntry] = []
        var at = now
        for i in 0..<count {
            let key = ymd(at)
            result.append(DayEntry(date: i == 0 ? now : Calendar.current.startOfDay(for: at),
                                   day: days[key],
                                   stamp: currentStamp(for: key)))
            at = nextMidnight(after: at)
        }
        return result
    }
}

// MARK: - 小: 人生◯日目

struct LifeDaysView: View {
    @Environment(\.colorScheme) var scheme
    let entry: DayEntry

    var body: some View {
        VStack(spacing: 4) {
            if let n = entry.day?.lifeDays {
                Text(n.formatted(.number.grouping(.automatic)))
                    .font(.system(size: 34, weight: .light, design: .serif))
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
                    .foregroundStyle(scheme == .dark ? Tone.textDark : Tone.text)
                    // iOS 26 の色合いを付ける表示・透明な表示で、主役の数字として色付けされる
                    .widgetAccentable()
                Text("日目")
                    .font(.system(size: 13, weight: .light))
                    .foregroundStyle(Tone.muted)
            } else {
                Text("アプリを開くと表示されます")
                    .font(.system(size: 12))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Tone.muted)
            }
        }
        .containerBackground(for: .widget) { scheme == .dark ? Tone.bgDark : Tone.bg }
    }
}

// MARK: - 中: 今日の問い + スタンプ

struct TodayQuestionView: View {
    @Environment(\.colorScheme) var scheme
    let entry: DayEntry

    /// 押すと、アプリの答えの欄にキーボードが出た状態で開く(ウィジェットでは文字を入力できないため)
    static let answerURL = URL(string: "lifecounter://answer?homeWidget")!

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let day = entry.day {
                // 問い(理由を聞くもう一歩もつなげた1文)
                Text(day.question)
                    .font(.system(size: 14, weight: .medium))
                    .lineLimit(3)
                    .minimumScaleFactor(0.85)
                    .foregroundStyle(scheme == .dark ? Tone.textDark : Tone.text)
                    .widgetAccentable()
                Spacer(minLength: 0)
                HStack(spacing: 6) {
                    // 気分はその場で押して残せる
                    ForEach(stampDefs, id: \.id) { s in
                        Button(intent: StampIntent(stampId: s.id, date: day.date)) {
                            MoodFaceView(moodId: s.id)
                                .frame(width: 30, height: 30)
                                .overlay(
                                    Circle().stroke(Tone.accent, lineWidth: 1.5)
                                        .padding(-2)
                                        .opacity(entry.stamp == s.id ? 1 : 0)
                                )
                                .opacity(entry.stamp == nil || entry.stamp == s.id ? 1 : 0.4)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(s.label)
                    }
                    Spacer(minLength: 4)
                    // 答えはアプリで書く
                    Link(destination: Self.answerURL) {
                        HStack(spacing: 4) {
                            Image(systemName: "square.and.pencil")
                                .font(.system(size: 12, weight: .semibold))
                            Text("書く")
                                .font(.system(size: 13, weight: .semibold))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .foregroundStyle(.white)
                        .background(Capsule().fill(Tone.accent))
                    }
                    .accessibilityLabel("答えを書く")
                }
            } else {
                Text("アプリを開くと、今日の問いが表示されます")
                    .font(.system(size: 13))
                    .foregroundStyle(Tone.muted)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .widgetURL(Self.answerURL)
        .containerBackground(for: .widget) { scheme == .dark ? Tone.bgDark : Tone.bg }
    }
}

struct LifeDaysWidget: Widget {
    let kind = "LifeDaysWidget"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: DayProvider()) { LifeDaysView(entry: $0) }
            .configurationDisplayName("人生の日数")
            .description("人生◯日目を、静かに表示します。")
            .supportedFamilies([.systemSmall])
    }
}

struct TodayQuestionWidget: Widget {
    let kind = "TodayQuestionWidget"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: DayProvider()) { TodayQuestionView(entry: $0) }
            .configurationDisplayName("今日の記録")
            .description("今日の問いを見て、気分をひと押しで残せます。「書く」から答えも書けます。")
            .supportedFamilies([.systemMedium])
    }
}

@main
struct LifeCounterWidgets: WidgetBundle {
    var body: some Widget {
        LifeDaysWidget()
        TodayQuestionWidget()
    }
}
