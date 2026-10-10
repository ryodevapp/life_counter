import SwiftUI
import WidgetKit

// 開発用: 起動引数 -widgetPreview のときだけ、ウィジェットの見た目を並べて表示する
// (ウィジェットは自動テストでホーム画面に置けないため、ここで撮って確かめる)

private func samplePhoto() -> UIImage {
    if let real = loadPhoto("preview.jpg") { return real }
    let size = CGSize(width: 600, height: 600)
    return UIGraphicsImageRenderer(size: size).image { ctx in
        let colors = [UIColor(red: 0.85, green: 0.70, blue: 0.55, alpha: 1).cgColor,
                      UIColor(red: 0.45, green: 0.55, blue: 0.62, alpha: 1).cgColor] as CFArray
        let g = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: [0, 1])!
        ctx.cgContext.drawLinearGradient(g, start: .zero, end: CGPoint(x: 600, y: 600), options: [])
    }
}

private let mom = Member(id: 1, n: "お母さん", p: "x.jpg",
                         e: Date().addingTimeInterval(86400 * 12).timeIntervalSince1970, mc: 4, my: 2, child: false)
private let dad = Member(id: 2, n: "お父さん", p: nil, e: nil, mc: 1, my: 2, child: false)
private let kid = Member(id: 3, n: "ゆい", p: nil, e: nil, mc: 0, my: 3, child: true)

private func entry(_ m: Member?, photo: Bool = false, locked: Bool = false, choice: Bool = false, tapped: String? = nil) -> NextEntry {
    NextEntry(date: Date(), member: m, days: daysUntil(m?.e), photo: photo ? samplePhoto() : nil,
              photoLocked: locked, choiceLocked: choice, hasFamily: m != nil, justTapped: tapped)
}

private struct Tile<V: View>: View {
    let title: String
    let size: CGSize
    let content: V
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.system(size: 10)).foregroundColor(.gray)
            content
                .environment(\.widgetPreviewHarness, true)
                .frame(width: size.width, height: size.height)
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                .shadow(color: .black.opacity(0.12), radius: 6, y: 2)
        }
    }
}

/// ストア用: ホーム画面にウィジェットを置いた見本(見出しなし)
struct HomeScreenMock: View {
    private func icon(_ c: Color) -> some View {
        RoundedRectangle(cornerRadius: 14, style: .continuous).fill(c.opacity(0.85)).frame(width: 62, height: 62)
    }
    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(red: 0.93, green: 0.80, blue: 0.68), Color(red: 0.55, green: 0.62, blue: 0.72)],
                           startPoint: .top, endPoint: .bottom).ignoresSafeArea()
            VStack(spacing: 22) {
                NextWidgetView(entry: entry(mom, photo: true), familyOverride: .systemMedium)
                    .environment(\.widgetPreviewHarness, true)
                    .frame(width: 338, height: 158)
                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                HStack(spacing: 22) {
                    NextWidgetView(entry: entry(dad), familyOverride: .systemSmall)
                        .environment(\.widgetPreviewHarness, true)
                        .frame(width: 158, height: 158)
                        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                    VStack(spacing: 22) {
                        HStack(spacing: 22) { icon(.white); icon(.orange) }
                        HStack(spacing: 22) { icon(.green); icon(.blue) }
                    }
                }
                MemoryWidgetView(entry: MemoryEntry(date: Date(), isPro: true,
                    memory: Memory(photo: samplePhoto(), y: 2025, m: 10, d: 20, name: "お母さん", note: "母と温泉。よく笑ってた", yearsAgo: 1)))
                    .environment(\.widgetPreviewHarness, true)
                    .frame(width: 338, height: 158)
                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                Spacer()
            }
            .padding(.top, 70)
        }
    }
}

struct WidgetPreviewGrid: View {
    let page: Int
    private let small = CGSize(width: 158, height: 158)
    private let medium = CGSize(width: 338, height: 158)
    private let large = CGSize(width: 338, height: 354)
    private let rect = CGSize(width: 160, height: 72)

    var body: some View {
        if page == 2 { HomeScreenMock() } else { grid }
    }

    private var grid: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                if page == 0 {
                    HStack(spacing: 14) {
                        Tile(title: "小・写真(Pro)", size: small, content: NextWidgetView(entry: entry(mom, photo: true), familyOverride: .systemSmall))
                        Tile(title: "小・文字(無料)", size: small, content: NextWidgetView(entry: entry(dad), familyOverride: .systemSmall))
                    }
                    HStack(spacing: 14) {
                        Tile(title: "小・写真は Pro", size: small, content: NextWidgetView(entry: entry(mom, locked: true), familyOverride: .systemSmall))
                        Tile(title: "小・押した直後", size: small, content: NextWidgetView(entry: entry(dad, tapped: "call"), familyOverride: .systemSmall))
                    }
                    Tile(title: "中・写真(Pro)", size: medium, content: NextWidgetView(entry: entry(mom, photo: true), familyOverride: .systemMedium))
                    Tile(title: "中・文字(無料)", size: medium, content: NextWidgetView(entry: entry(dad), familyOverride: .systemMedium))
                    Tile(title: "中・子ども", size: medium, content: NextWidgetView(entry: entry(kid), familyOverride: .systemMedium))
                } else {
                    Tile(title: "中・家族を選ぶのは Pro", size: medium, content: NextWidgetView(entry: entry(dad, choice: true), familyOverride: .systemMedium))
                    Tile(title: "思い出・大(Pro)", size: large, content: MemoryWidgetView(entry: MemoryEntry(date: Date(), isPro: true,
                        memory: Memory(photo: samplePhoto(), y: 2025, m: 10, d: 20, name: "お母さん", note: "母と温泉。よく笑ってた", yearsAgo: 1))))
                    Tile(title: "思い出・中(未購入)", size: medium, content: MemoryWidgetView(entry: MemoryEntry(date: Date(), isPro: false, memory: nil)))
                    HStack(spacing: 14) {
                        Tile(title: "ロック画面", size: rect, content: NextWidgetView(entry: entry(mom), familyOverride: .accessoryRectangular).foregroundColor(.black))
                        Tile(title: "空(家族なし)", size: small, content: NextWidgetView(entry: entry(nil), familyOverride: .systemSmall))
                    }
                }
            }
            .padding(20)
        }
        .background(Color(red: 0.93, green: 0.92, blue: 0.95))
    }
}
