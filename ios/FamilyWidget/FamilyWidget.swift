import AppIntents
import SwiftUI
import WidgetKit

// ウィジェットの登録(見た目とデータの扱いは WidgetShared.swift)

struct NextProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> NextEntry {
        NextEntry(date: Date(),
                  member: Member(id: 0, n: "お母さん", p: nil, e: Date().addingTimeInterval(86400 * 21).timeIntervalSince1970, mc: 4, my: 2, child: false),
                  days: 21, photo: nil, photoLocked: false, choiceLocked: false, hasFamily: true, justTapped: nil)
    }
    func snapshot(for configuration: SelectFamilyIntent, in context: Context) async -> NextEntry {
        context.isPreview ? placeholder(in: context) : makeNextEntry(selectedId: configuration.member?.id)
    }
    func timeline(for configuration: SelectFamilyIntent, in context: Context) async -> Timeline<NextEntry> {
        let entry = makeNextEntry(selectedId: configuration.member?.id)
        // 押した直後の「残しました」を10秒後に消す。それ以外は日付が変わったら読み直す
        let next = entry.justTapped != nil ? Date().addingTimeInterval(11) : nextMidnight()
        return Timeline(entries: [entry], policy: .after(next))
    }
}

struct FamilyWidget: Widget {
    // 置き済みのウィジェットが消えないよう、kind は最初の版のまま
    let kind = "FamilyWidget"
    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: SelectFamilyIntent.self, provider: NextProvider()) { entry in
            NextWidgetView(entry: entry)
        }
        .configurationDisplayName("家族")
        .description("次に会う日までの日数と、今月つながった日。電話した日などを、ここから残せます")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryRectangular, .accessoryInline, .accessoryCircular])
    }
}

struct MemoryProvider: TimelineProvider {
    func placeholder(in context: Context) -> MemoryEntry {
        MemoryEntry(date: Date(), isPro: true,
                    memory: Memory(photo: nil, y: 2026, m: 8, d: 14, name: "お母さん", note: "母と温泉。よく笑ってた", yearsAgo: 0))
    }
    func getSnapshot(in context: Context, completion: @escaping (MemoryEntry) -> Void) {
        completion(context.isPreview ? placeholder(in: context) : makeMemoryEntry())
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<MemoryEntry>) -> Void) {
        completion(Timeline(entries: [makeMemoryEntry()], policy: .after(nextMidnight())))
    }
}

struct MemoryWidget: Widget {
    let kind = "MemoryWidget"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: MemoryProvider()) { entry in
            MemoryWidgetView(entry: entry)
        }
        .configurationDisplayName("思い出")
        .description("家族と会えた日の写真を、日替わりで表示します")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}

@main
struct LifeCounterWidgets: WidgetBundle {
    var body: some Widget {
        FamilyWidget()
        MemoryWidget()
    }
}
