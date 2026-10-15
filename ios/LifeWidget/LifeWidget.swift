import SwiftUI
import WidgetKit

// 1つのウィジェットに役目は1つ。それ以外の情報は載せない
//   小(LifeDaysWidget)     : 人生◯日目だけ
//   中(TodayQuestionWidget): 今日の問いと、スタンプ5つだけ

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

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let day = entry.day {
                Text(day.question)
                    .font(.system(size: 14, weight: .medium))
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                    .foregroundStyle(scheme == .dark ? Tone.textDark : Tone.text)
                    .widgetAccentable()
                Spacer(minLength: 0)
                // 気分は問いへの答えではないので、見出しを付けて分ける
                Text("今日の気分")
                    .font(.system(size: 10))
                    .foregroundStyle(Tone.muted)
                HStack {
                    ForEach(stampDefs, id: \.id) { s in
                        Button(intent: StampIntent(stampId: s.id, date: day.date)) {
                            Text(s.emoji)
                                .font(.system(size: 24))
                                .frame(maxWidth: .infinity)
                                .opacity(entry.stamp == nil || entry.stamp == s.id ? 1 : 0.3)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(s.label)
                    }
                }
            } else {
                Text("アプリを開くと、今日の問いが表示されます")
                    .font(.system(size: 13))
                    .foregroundStyle(Tone.muted)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
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
            .configurationDisplayName("今日の問い")
            .description("今日の問いを見て、今日の気分をひと押しで残せます。")
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
