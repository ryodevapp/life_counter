import AppIntents
import SwiftUI
import WidgetKit

// アプリ(Flutter 側の lib/services/widget_sync.dart)と、App Group の UserDefaults でやりとりする
//   days        : [{"d": "yyyy-MM-dd", "n": 人生の日数, "q": その日の問い}](アプリが先の60日分を書く)
//   todayStamp  : {"d": "yyyy-MM-dd", "s": スタンプの id か ""}(アプリが書く)
//   pendingStamps: [{"d": "yyyy-MM-dd", "s": id か "", "t": 押した時刻(秒)}](ウィジェットが書き、アプリが取り込んで空にする)
// 答えの文など個人的な内容は、ここには置かない

let appGroup = "group.com.lifecounter.lifeCounter"
var sharedDefaults: UserDefaults? { UserDefaults(suiteName: appGroup) }

// MARK: - 色(アプリの AppColors に合わせる)

enum Tone {
    static let bg = Color(red: 0.992, green: 0.984, blue: 0.969)
    static let bgDark = Color(red: 0.13, green: 0.12, blue: 0.11)
    static let text = Color(red: 0.173, green: 0.145, blue: 0.125)
    static let textDark = Color(red: 0.95, green: 0.93, blue: 0.90)
    static let muted = Color(red: 0.478, green: 0.439, blue: 0.408)
    static let accent = Color(red: 0.722, green: 0.471, blue: 0.306)
}

// MARK: - スタンプ(lib/models/stamp.dart と同じ並びと id)

struct StampDef {
    let id: String
    let emoji: String
    let ja: String
    let en: String
    var label: String { L10n.isJapanese ? ja : en }
}

/// ウィジェットの言葉(端末の言語が日本語なら日本語、それ以外は英語。アプリの切り替えと同じ決まり)
enum L10n {
    static var isJapanese: Bool {
        (Locale.preferredLanguages.first ?? "ja").hasPrefix("ja")
    }
    static func t(_ ja: String, _ en: String) -> String { isJapanese ? ja : en }
}

let stampDefs: [StampDef] = [
    StampDef(id: "happy", emoji: "😊", ja: "うれしい", en: "Happy"),
    StampDef(id: "calm", emoji: "😌", ja: "おだやか", en: "Calm"),
    StampDef(id: "neutral", emoji: "😐", ja: "ふつう", en: "Okay"),
    StampDef(id: "tired", emoji: "😩", ja: "つかれた", en: "Tired"),
    StampDef(id: "sad", emoji: "😢", ja: "かなしい", en: "Sad"),
]

// MARK: - 気分の顔(lib/views/shared/mood_face.dart の MoodBadge と同じ描き方・同じ色。直すときは両方そろえる)

struct MoodLook {
    let light: Color
    let ink: Color
}

private func rgb(_ hex: UInt32) -> Color {
    Color(red: Double((hex >> 16) & 0xFF) / 255,
          green: Double((hex >> 8) & 0xFF) / 255,
          blue: Double(hex & 0xFF) / 255)
}

let moodLooks: [String: MoodLook] = [
    "happy": MoodLook(light: rgb(0xF4C48A), ink: rgb(0x9A5A24)),
    "calm": MoodLook(light: rgb(0xC3D3AC), ink: rgb(0x56693F)),
    "neutral": MoodLook(light: rgb(0xE2D3B5), ink: rgb(0x7D6A4F)),
    "tired": MoodLook(light: rgb(0xC2B8D2), ink: rgb(0x625776)),
    "sad": MoodLook(light: rgb(0xAFC3D3), ink: rgb(0x44607A)),
]

/// 顔の線(ウィジェットでは Canvas が使えないので、Shape で描く。lib/views/shared/mood_face.dart と同じ形)
struct MoodFaceLines: Shape {
    let moodId: String

    func path(in rect: CGRect) -> Path {
        let s = min(rect.width, rect.height)
        let c = CGPoint(x: rect.minX + s / 2, y: rect.minY + s / 2)
        let ex = s * 0.17, ey = rect.minY + s * 0.42, ew = s * 0.11
        let le = CGPoint(x: c.x - ex, y: ey), re = CGPoint(x: c.x + ex, y: ey)
        let mouthY = rect.minY + s * 0.64
        var p = Path()
        func line(_ a: CGPoint, _ b: CGPoint) { p.move(to: a); p.addLine(to: b) }
        func arc(_ center: CGPoint, _ w: Double, _ h: Double, up: Bool) {
            p.move(to: CGPoint(x: center.x - w / 2, y: center.y))
            p.addQuadCurve(to: CGPoint(x: center.x + w / 2, y: center.y),
                           control: CGPoint(x: center.x, y: center.y + (up ? -h : h)))
        }
        switch moodId {
        case "happy":
            arc(le, ew * 1.3, s * 0.08, up: true)
            arc(re, ew * 1.3, s * 0.08, up: true)
            arc(CGPoint(x: c.x, y: mouthY), s * 0.3, s * 0.12, up: false)
        case "calm":
            arc(le, ew * 1.3, s * 0.06, up: false)
            arc(re, ew * 1.3, s * 0.06, up: false)
            arc(CGPoint(x: c.x, y: mouthY + s * 0.01), s * 0.18, s * 0.05, up: false)
        case "neutral":
            line(CGPoint(x: c.x - s * 0.1, y: mouthY), CGPoint(x: c.x + s * 0.1, y: mouthY))
        case "tired":
            line(CGPoint(x: le.x - ew * 0.7, y: le.y + s * 0.025), CGPoint(x: le.x + ew * 0.6, y: le.y - s * 0.005))
            line(CGPoint(x: re.x + ew * 0.7, y: re.y + s * 0.025), CGPoint(x: re.x - ew * 0.6, y: re.y - s * 0.005))
            let w = s * 0.2, y = mouthY + s * 0.02
            p.move(to: CGPoint(x: c.x - w / 2, y: y))
            p.addQuadCurve(to: CGPoint(x: c.x, y: y), control: CGPoint(x: c.x - w / 4, y: y - s * 0.035))
            p.addQuadCurve(to: CGPoint(x: c.x + w / 2, y: y), control: CGPoint(x: c.x + w / 4, y: y + s * 0.035))
        case "sad":
            line(CGPoint(x: le.x - ew * 0.6, y: le.y - s * 0.1), CGPoint(x: le.x + ew * 0.5, y: le.y - s * 0.13))
            line(CGPoint(x: re.x + ew * 0.6, y: re.y - s * 0.1), CGPoint(x: re.x - ew * 0.5, y: re.y - s * 0.13))
            arc(CGPoint(x: c.x, y: mouthY + s * 0.04), s * 0.22, s * 0.07, up: true)
        default:
            break
        }
        return p
    }
}

/// 顔の点の目(ふつう・かなしい)
struct MoodFaceDots: Shape {
    let moodId: String

    func path(in rect: CGRect) -> Path {
        let s = min(rect.width, rect.height)
        let stroke = min(max(s / 27.5, 1.0), 2.2)
        let c = CGPoint(x: rect.minX + s / 2, y: rect.minY + s / 2)
        let ex = s * 0.17, ey = rect.minY + s * 0.42
        var p = Path()
        func dot(_ x: Double, _ y: Double, _ r: Double) {
            p.addEllipse(in: CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2))
        }
        switch moodId {
        case "neutral":
            dot(c.x - ex, ey, stroke * 1.15); dot(c.x + ex, ey, stroke * 1.15)
        case "sad":
            dot(c.x - ex, ey + s * 0.02, stroke * 1.1); dot(c.x + ex, ey + s * 0.02, stroke * 1.1)
        default:
            break
        }
        return p
    }
}

/// うすい色の丸 + 細い線の顔(表情はおもに目で出す)
struct MoodFaceView: View {
    let moodId: String

    var body: some View {
        GeometryReader { geo in
            let s = min(geo.size.width, geo.size.height)
            let lw = min(max(s / 27.5, 1.0), 2.2)
            if let look = moodLooks[moodId] {
                ZStack {
                    Circle().fill(look.light.opacity(0.6)).padding(lw)
                    MoodFaceLines(moodId: moodId)
                        .stroke(look.ink, style: StrokeStyle(lineWidth: lw, lineCap: .round))
                    MoodFaceDots(moodId: moodId).fill(look.ink)
                }
                .frame(width: s, height: s)
            }
        }
    }
}

// MARK: - データ

struct DayInfo {
    let date: String
    let lifeDays: Int
    let question: String
}

func ymd(_ date: Date) -> String {
    let c = Calendar.current.dateComponents([.year, .month, .day], from: date)
    return String(format: "%04d-%02d-%02d", c.year ?? 0, c.month ?? 0, c.day ?? 0)
}

func loadDays() -> [DayInfo] {
    guard let raw = sharedDefaults?.string(forKey: "days"),
          let data = raw.data(using: .utf8),
          let list = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]]
    else { return [] }
    return list.compactMap { e in
        guard let d = e["d"] as? String, let n = e["n"] as? Int, let q = e["q"] as? String
        else { return nil }
        return DayInfo(date: d, lifeDays: n, question: q)
    }
}

private func loadPending() -> [[String: Any]] {
    guard let raw = sharedDefaults?.string(forKey: "pendingStamps"),
          let data = raw.data(using: .utf8),
          let list = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]]
    else { return [] }
    return list
}

/// その日のスタンプ。ウィジェットで押した最新のものを優先し、なければアプリが書いたもの
func currentStamp(for date: String) -> String? {
    if let last = loadPending().last(where: { ($0["d"] as? String) == date }) {
        let s = last["s"] as? String ?? ""
        return s.isEmpty ? nil : s
    }
    guard let raw = sharedDefaults?.string(forKey: "todayStamp"),
          let data = raw.data(using: .utf8),
          let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
          (obj["d"] as? String) == date
    else { return nil }
    let s = obj["s"] as? String ?? ""
    return s.isEmpty ? nil : s
}

func nextMidnight(after date: Date) -> Date {
    Calendar.current.startOfDay(for: date.addingTimeInterval(86400))
}

// MARK: - スタンプを押す(iOS 17 の押せるウィジェット)

struct StampIntent: AppIntent {
    static var title: LocalizedStringResource = "今日の気分を残す"
    static var isDiscoverable: Bool = false

    @Parameter(title: "スタンプ") var stampId: String
    @Parameter(title: "日付") var date: String

    init() {}
    init(stampId: String, date: String) {
        self.stampId = stampId
        self.date = date
    }

    func perform() async throws -> some IntentResult {
        // 同じものをもう一度押したら取り消し
        let next = currentStamp(for: date) == stampId ? "" : stampId
        var list = loadPending()
        list.append(["d": date, "s": next, "t": Date().timeIntervalSince1970])
        // 取り込まれないまま溜まり続けないよう、新しい50件だけ残す
        if list.count > 50 { list = Array(list.suffix(50)) }
        if let data = try? JSONSerialization.data(withJSONObject: list),
           let raw = String(data: data, encoding: .utf8) {
            sharedDefaults?.set(raw, forKey: "pendingStamps")
        }
        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}
