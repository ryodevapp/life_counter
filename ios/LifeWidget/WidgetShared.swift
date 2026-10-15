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
    let label: String
}

let stampDefs: [StampDef] = [
    StampDef(id: "happy", emoji: "😊", label: "うれしい"),
    StampDef(id: "calm", emoji: "😌", label: "おだやか"),
    StampDef(id: "neutral", emoji: "😐", label: "ふつう"),
    StampDef(id: "tired", emoji: "😩", label: "つかれた"),
    StampDef(id: "sad", emoji: "😢", label: "かなしい"),
]

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
