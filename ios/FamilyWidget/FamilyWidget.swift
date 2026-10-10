import WidgetKit
import SwiftUI
import ImageIO

// アプリ(Flutter)が App Group に書いた値と写真を読む
private let appGroup = "group.com.lifecounter.lifeCounter"
private var defaults: UserDefaults? { UserDefaults(suiteName: appGroup) }

// MARK: - 色と書体(アプリの AppColors に合わせる)

private enum Tone {
    static let bg = Color(red: 0.992, green: 0.984, blue: 0.969)      // #FDFBF7
    static let warm = Color(red: 0.973, green: 0.953, blue: 0.922)    // #F8F3EB
    static let text = Color(red: 0.173, green: 0.145, blue: 0.125)    // #2C2520
    static let muted = Color(red: 0.478, green: 0.439, blue: 0.408)   // #7A7068
    static let accent = Color(red: 0.722, green: 0.471, blue: 0.306)  // #B8784E
}

private func number(_ size: CGFloat) -> Font { .system(size: size, weight: .light, design: .serif) }
private func label(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font { .system(size: size, weight: weight) }

/// 写真を、ウィジェットの大きさに合わせて縮小して読む(メモリの上限に収めるため)
private func loadPhoto(_ name: String?, maxPixel: CGFloat = 800) -> UIImage? {
    guard let name = name,
          let base = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroup)
    else { return nil }
    let url = base.appendingPathComponent("photos").appendingPathComponent(name)
    guard let src = CGImageSourceCreateWithURL(url as CFURL, nil) else { return nil }
    let opts: [CFString: Any] = [
        kCGImageSourceCreateThumbnailFromImageAlways: true,
        kCGImageSourceCreateThumbnailWithTransform: true,
        kCGImageSourceThumbnailMaxPixelSize: maxPixel,
    ]
    guard let cg = CGImageSourceCreateThumbnailAtIndex(src, 0, opts as CFDictionary) else { return nil }
    return UIImage(cgImage: cg)
}

private func nextMidnight() -> Date {
    Calendar.current.startOfDay(for: Date().addingTimeInterval(86400))
}

extension View {
    /// iOS 17 以降は containerBackground で全面に敷く。16 では ZStack の後ろに敷く
    @ViewBuilder
    func widgetBackground<B: View>(@ViewBuilder _ background: () -> B) -> some View {
        if #available(iOS 17.0, *) {
            self.containerBackground(for: .widget) { background() }
        } else {
            ZStack { background(); self.padding() }
        }
    }
}

/// 写真の上の文字を読めるように、下から影を敷く
private struct PhotoBackground: View {
    let image: UIImage
    var body: some View {
        ZStack {
            Image(uiImage: image).resizable().scaledToFill()
            LinearGradient(colors: [.clear, .black.opacity(0.55)],
                           startPoint: .center, endPoint: .bottom)
        }
    }
}

// MARK: - 次に会う日

struct NextEntry: TimelineEntry {
    let date: Date
    let name: String?
    let days: Int?
    let meetDate: Date?
    let photo: UIImage?
    let yearCount: Int
    let hasFamily: Bool
}

struct NextProvider: TimelineProvider {
    func placeholder(in context: Context) -> NextEntry {
        NextEntry(date: Date(), name: "お母さん", days: 21, meetDate: nil, photo: nil, yearCount: 3, hasFamily: true)
    }
    func getSnapshot(in context: Context, completion: @escaping (NextEntry) -> Void) {
        completion(context.isPreview ? placeholder(in: context) : read())
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<NextEntry>) -> Void) {
        completion(Timeline(entries: [read()], policy: .after(nextMidnight())))
    }

    private func read() -> NextEntry {
        let d = defaults
        let isPro = d?.bool(forKey: "isPro") ?? false
        var name: String? = nil, days: Int? = nil, meet: Date? = nil, photo: UIImage? = nil
        if let ts = d?.object(forKey: "nextMeetEpoch") as? Double {
            let cal = Calendar.current
            let m = cal.startOfDay(for: Date(timeIntervalSince1970: ts))
            let left = cal.dateComponents([.day], from: cal.startOfDay(for: Date()), to: m).day ?? -1
            if left >= 0 {
                name = d?.string(forKey: "nextMeetName")
                days = left
                meet = m
                if isPro { photo = loadPhoto(d?.string(forKey: "nextMeetPhoto")) }
            }
        }
        return NextEntry(date: Date(), name: name, days: days, meetDate: meet, photo: photo,
                         yearCount: d?.integer(forKey: "yearCount") ?? 0,
                         hasFamily: d?.bool(forKey: "hasFamily") ?? false)
    }
}

private let meetFormatter: DateFormatter = {
    let f = DateFormatter()
    f.locale = Locale(identifier: "ja_JP")
    f.dateFormat = "M月d日(E)"
    return f
}()

struct NextWidgetView: View {
    @Environment(\.widgetFamily) var family
    let entry: NextEntry

    var body: some View {
        switch family {
        case .accessoryInline: inline
        case .accessoryRectangular: rectangular
        case .accessoryCircular: circular
        case .systemMedium: medium
        default: small
        }
    }

    // ロック画面
    private var inline: some View {
        Group {
            if let n = entry.name, let d = entry.days {
                Text(d == 0 ? "今日、\(n)に会えます" : "\(n)まで あと\(d)日")
            } else {
                Text("今年会えた日 \(entry.yearCount)日")
            }
        }.widgetBackground { Color.clear }
    }

    private var rectangular: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let n = entry.name, let d = entry.days {
                Text(d == 0 ? "今日、会えます" : "\(n)まで").font(label(12)).widgetAccentable()
                Text(d == 0 ? n : "あと \(d) 日").font(.system(size: 22, weight: .semibold, design: .serif))
            } else {
                Text("今年、家族と会えた日").font(label(12)).widgetAccentable()
                Text("\(entry.yearCount) 日").font(.system(size: 22, weight: .semibold, design: .serif))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .widgetBackground { Color.clear }
    }

    private var circular: some View {
        VStack(spacing: -2) {
            Text("\(entry.days ?? entry.yearCount)").font(.system(size: 20, weight: .semibold, design: .serif))
            Text(entry.days != nil ? "日" : "会えた").font(label(9))
        }
        .widgetBackground { AccessoryWidgetBackground() }
    }

    // ホーム画面(小)
    @ViewBuilder
    private var small: some View {
        if let n = entry.name, let d = entry.days {
            if let photo = entry.photo {
                VStack(alignment: .leading, spacing: 0) {
                    Spacer()
                    Text(d == 0 ? "今日、会えます" : "\(n)まで").font(label(12, .medium)).foregroundColor(.white.opacity(0.9))
                    if d > 0 {
                        HStack(alignment: .firstTextBaseline, spacing: 3) {
                            Text("あと").font(label(11)).foregroundColor(.white.opacity(0.85))
                            Text("\(d)").font(number(44)).foregroundColor(.white)
                            Text("日").font(label(12)).foregroundColor(.white.opacity(0.85))
                        }
                    } else {
                        Text(n).font(label(20, .semibold)).foregroundColor(.white)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                .widgetBackground { PhotoBackground(image: photo) }
            } else {
                VStack(alignment: .leading, spacing: 2) {
                    Text(d == 0 ? "今日、" : "\(n)に")
                        .font(label(12)).foregroundColor(Tone.muted)
                    Text(d == 0 ? "\(n)に会えます" : "会えるまで")
                        .font(label(12)).foregroundColor(Tone.muted)
                    Spacer(minLength: 0)
                    if d > 0 {
                        HStack(alignment: .firstTextBaseline, spacing: 3) {
                            Text("あと").font(label(11)).foregroundColor(Tone.muted)
                            Text("\(d)").font(number(48)).foregroundColor(Tone.accent)
                            Text("日").font(label(12)).foregroundColor(Tone.muted)
                        }
                    }
                    if let m = entry.meetDate {
                        Text(meetFormatter.string(from: m)).font(label(11)).foregroundColor(Tone.text)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .widgetBackground { Tone.bg }
            }
        } else {
            empty
        }
    }

    // ホーム画面(中)
    @ViewBuilder
    private var medium: some View {
        if let n = entry.name, let d = entry.days {
            HStack(spacing: 14) {
                Group {
                    if let photo = entry.photo {
                        Image(uiImage: photo).resizable().scaledToFill()
                    } else {
                        ZStack {
                            Tone.warm
                            Text(String(n.prefix(1))).font(.system(size: 40, weight: .light, design: .serif))
                                .foregroundColor(Tone.accent)
                        }
                    }
                }
                .frame(width: 118, height: 118)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

                VStack(alignment: .leading, spacing: 2) {
                    Text("次に会う日").font(label(11)).foregroundColor(Tone.muted)
                    Text(n).font(label(16, .semibold)).foregroundColor(Tone.text).lineLimit(1)
                    Spacer(minLength: 0)
                    if d == 0 {
                        Text("今日、会えます").font(label(18, .semibold)).foregroundColor(Tone.accent)
                    } else {
                        HStack(alignment: .firstTextBaseline, spacing: 3) {
                            Text("あと").font(label(12)).foregroundColor(Tone.muted)
                            Text("\(d)").font(number(46)).foregroundColor(Tone.accent)
                            Text("日").font(label(13)).foregroundColor(Tone.muted)
                        }
                    }
                    if let m = entry.meetDate {
                        Text(meetFormatter.string(from: m)).font(label(12)).foregroundColor(Tone.text)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
            .widgetBackground { Tone.bg }
        } else {
            empty
        }
    }

    private var empty: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(entry.hasFamily ? "今年、家族と会えた日" : "LifeCounter")
                .font(label(12)).foregroundColor(Tone.muted)
            if entry.hasFamily {
                HStack(alignment: .firstTextBaseline, spacing: 3) {
                    Text("\(entry.yearCount)").font(number(44)).foregroundColor(Tone.accent)
                    Text("日").font(label(12)).foregroundColor(Tone.muted)
                }
            }
            Spacer(minLength: 0)
            Text(entry.hasFamily ? "次に会う日を入れると、ここで数えます" : "家族を登録すると、ここに表示されます")
                .font(label(11)).foregroundColor(Tone.text).lineLimit(2)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .widgetBackground { Tone.bg }
    }
}

struct FamilyWidget: Widget {
    // 置き済みのウィジェットが消えないよう、kind は最初の版のまま
    let kind = "FamilyWidget"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: NextProvider()) { entry in
            NextWidgetView(entry: entry)
        }
        .configurationDisplayName("次に会う日")
        .description("次に家族に会える日まで、あと何日かを数えます")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryRectangular, .accessoryInline, .accessoryCircular])
    }
}

// MARK: - 思い出(Pro)

struct Memory {
    let photo: UIImage?
    let y: Int, m: Int, d: Int
    let name: String
    let note: String
    let yearsAgo: Int   // 「◯年前の今日」なら 1 以上
}

struct MemoryEntry: TimelineEntry {
    let date: Date
    let isPro: Bool
    let memory: Memory?
}

struct MemoryProvider: TimelineProvider {
    func placeholder(in context: Context) -> MemoryEntry {
        MemoryEntry(date: Date(), isPro: true,
                    memory: Memory(photo: nil, y: 2026, m: 8, d: 14, name: "お母さん", note: "母と温泉。よく笑ってた", yearsAgo: 0))
    }
    func getSnapshot(in context: Context, completion: @escaping (MemoryEntry) -> Void) {
        completion(context.isPreview ? placeholder(in: context) : read())
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<MemoryEntry>) -> Void) {
        completion(Timeline(entries: [read()], policy: .after(nextMidnight())))
    }

    /// 「◯年前の今日」を優先し、なければ日替わりで1枚選ぶ
    private func read() -> MemoryEntry {
        let d = defaults
        let isPro = d?.bool(forKey: "isPro") ?? false
        guard isPro,
              let json = d?.string(forKey: "memories"),
              let data = json.data(using: .utf8),
              let list = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]],
              !list.isEmpty
        else { return MemoryEntry(date: Date(), isPro: isPro, memory: nil) }

        let cal = Calendar.current
        let now = cal.dateComponents([.year, .month, .day], from: Date())
        var pick = list.first { ($0["m"] as? Int) == now.month && ($0["d"] as? Int) == now.day && ($0["y"] as? Int ?? 0) < (now.year ?? 0) }
        var yearsAgo = 0
        if let p = pick { yearsAgo = (now.year ?? 0) - (p["y"] as? Int ?? 0) }
        if pick == nil {
            let day = cal.ordinality(of: .day, in: .year, for: Date()) ?? 0
            pick = list[day % list.count]
        }
        let p = pick!
        return MemoryEntry(date: Date(), isPro: true, memory: Memory(
            photo: loadPhoto(p["f"] as? String, maxPixel: 1000),
            y: p["y"] as? Int ?? 0, m: p["m"] as? Int ?? 0, d: p["d"] as? Int ?? 0,
            name: p["n"] as? String ?? "", note: p["t"] as? String ?? "", yearsAgo: yearsAgo))
    }
}

struct MemoryWidgetView: View {
    let entry: MemoryEntry

    var body: some View {
        if let m = entry.memory, let photo = m.photo {
            VStack(alignment: .leading, spacing: 4) {
                if m.yearsAgo > 0 {
                    Text("\(m.yearsAgo)年前の今日")
                        .font(label(11, .semibold)).foregroundColor(.white)
                        .padding(.horizontal, 8).padding(.vertical, 3)
                        .background(Capsule().fill(Color.black.opacity(0.35)))
                }
                Spacer()
                Text("\(m.y).\(m.m).\(m.d)  \(m.name)").font(label(11)).foregroundColor(.white.opacity(0.85))
                if !m.note.isEmpty {
                    Text(m.note).font(label(15, .medium)).foregroundColor(.white).lineLimit(2)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .widgetBackground { PhotoBackground(image: photo) }
        } else {
            VStack(alignment: .leading, spacing: 8) {
                Text("思い出").font(label(12)).foregroundColor(Tone.muted)
                Spacer(minLength: 0)
                Text(entry.isPro ? "会えた日の記録に写真を添えると、\nここに思い出として表示されます"
                                 : "会えた日の写真が、\nここに思い出として表示されます")
                    .font(label(13)).foregroundColor(Tone.text).lineSpacing(3)
                if !entry.isPro {
                    Text("LifeCounter Pro").font(label(11, .semibold)).foregroundColor(Tone.accent)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .widgetBackground { Tone.warm }
        }
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
