import WidgetKit
import SwiftUI

// アプリ(Flutter)が App Group に書いた値を表示する
private let appGroup = "group.com.lifecounter.lifeCounter"

struct FamilyEntry: TimelineEntry {
    let date: Date
    let label: String
    let value: String
    let unit: String
    let sub: String
    let style: String
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> FamilyEntry {
        FamilyEntry(date: Date(), label: "お母さんに会えるまで", value: "12", unit: "日",
                    sub: "今年会えた日 3日", style: "warm")
    }

    func getSnapshot(in context: Context, completion: @escaping (FamilyEntry) -> Void) {
        completion(read())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<FamilyEntry>) -> Void) {
        // 日付が変わったら「あと◯日」を進めるため、翌日0時にもう一度読む
        let next = Calendar.current.startOfDay(for: Date().addingTimeInterval(86400))
        completion(Timeline(entries: [read()], policy: .after(next)))
    }

    private func read() -> FamilyEntry {
        let d = UserDefaults(suiteName: appGroup)
        var value = d?.string(forKey: "value") ?? ""
        var label = d?.string(forKey: "label") ?? "家族を登録すると、ここに表示されます"
        // 次に会う日があれば、ウィジェット側で日数を数える(アプリを開かなくても進む)
        if let ts = d?.object(forKey: "nextMeetEpoch") as? Double, let name = d?.string(forKey: "nextMeetName") {
            let meet = Calendar.current.startOfDay(for: Date(timeIntervalSince1970: ts))
            let today = Calendar.current.startOfDay(for: Date())
            let days = Calendar.current.dateComponents([.day], from: today, to: meet).day ?? 0
            if days > 0 {
                label = "\(name)に会えるまで、あと"
                value = "\(days)"
            } else if days == 0 {
                label = "今日、\(name)に会えます"
                value = ""
            }
        }
        return FamilyEntry(
            date: Date(),
            label: label,
            value: value,
            unit: value.isEmpty ? "" : (d?.string(forKey: "unit") ?? "日"),
            sub: d?.string(forKey: "sub") ?? "",
            style: d?.string(forKey: "style") ?? "warm"
        )
    }
}

struct Palette {
    let bg: Color
    let fg: Color
    let accent: Color
    let muted: Color

    static func of(_ style: String) -> Palette {
        switch style {
        case "night":
            return Palette(bg: Color(red: 0.13, green: 0.12, blue: 0.11), fg: Color(red: 0.95, green: 0.92, blue: 0.89),
                           accent: Color(red: 0.84, green: 0.60, blue: 0.43), muted: Color(red: 0.66, green: 0.62, blue: 0.58))
        case "sakura":
            return Palette(bg: Color(red: 0.99, green: 0.93, blue: 0.93), fg: Color(red: 0.24, green: 0.18, blue: 0.18),
                           accent: Color(red: 0.80, green: 0.42, blue: 0.48), muted: Color(red: 0.55, green: 0.45, blue: 0.46))
        case "sea":
            return Palette(bg: Color(red: 0.91, green: 0.95, blue: 0.97), fg: Color(red: 0.14, green: 0.20, blue: 0.25),
                           accent: Color(red: 0.25, green: 0.47, blue: 0.62), muted: Color(red: 0.42, green: 0.50, blue: 0.56))
        default:
            return Palette(bg: Color(red: 0.99, green: 0.98, blue: 0.97), fg: Color(red: 0.17, green: 0.15, blue: 0.13),
                           accent: Color(red: 0.72, green: 0.47, blue: 0.31), muted: Color(red: 0.48, green: 0.44, blue: 0.41))
        }
    }
}

struct FamilyWidgetView: View {
    var entry: FamilyEntry

    var body: some View {
        let p = Palette.of(entry.style)
        VStack(alignment: .leading, spacing: 4) {
            Text(entry.label)
                .font(.system(size: 12))
                .foregroundColor(p.muted)
                .lineLimit(2)
            if !entry.value.isEmpty {
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text(entry.value)
                        .font(.system(size: 40, weight: .light, design: .serif))
                        .foregroundColor(p.accent)
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                    Text(entry.unit)
                        .font(.system(size: 13))
                        .foregroundColor(p.muted)
                }
            }
            Spacer(minLength: 0)
            if !entry.sub.isEmpty {
                Text(entry.sub)
                    .font(.system(size: 11))
                    .foregroundColor(p.fg)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .widgetBackground(p.bg)
    }
}

extension View {
    // iOS 17 以降は containerBackground が必要。16 では従来どおり背景を敷く
    @ViewBuilder
    func widgetBackground(_ color: Color) -> some View {
        if #available(iOS 17.0, *) {
            self.containerBackground(color, for: .widget)
        } else {
            self.padding().background(color)
        }
    }
}

@main
struct FamilyWidget: Widget {
    let kind = "FamilyWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            FamilyWidgetView(entry: entry)
        }
        .configurationDisplayName("家族と過ごせる時間")
        .description("次に会う日や、今年会えた日を表示します")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
