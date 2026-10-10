import AppIntents
import ImageIO
import SwiftUI
import WidgetKit

// ウィジェット本体と、アプリ内の確認画面(-widgetPreview)の両方で使う

let appGroup = "group.com.lifecounter.lifeCounter"
var sharedDefaults: UserDefaults? { UserDefaults(suiteName: appGroup) }

// MARK: - 色と書体(アプリの AppColors に合わせる)

enum Tone {
    static let bg = Color(red: 0.992, green: 0.984, blue: 0.969)
    static let warm = Color(red: 0.973, green: 0.953, blue: 0.922)
    static let text = Color(red: 0.173, green: 0.145, blue: 0.125)
    static let muted = Color(red: 0.478, green: 0.439, blue: 0.408)
    static let accent = Color(red: 0.722, green: 0.471, blue: 0.306)
}

func number(_ size: CGFloat) -> Font { .system(size: size, weight: .light, design: .serif) }
func label(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font { .system(size: size, weight: weight) }

/// 写真を、ウィジェットの大きさに合わせて縮小して読む(メモリの上限に収めるため)
func loadPhoto(_ name: String?, maxPixel: CGFloat = 800) -> UIImage? {
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

func nextMidnight() -> Date {
    Calendar.current.startOfDay(for: Date().addingTimeInterval(86400))
}

// MARK: - 確認画面では containerBackground が効かないので、ZStack で敷く

private struct PreviewHarnessKey: EnvironmentKey { static let defaultValue = false }
extension EnvironmentValues {
    var widgetPreviewHarness: Bool {
        get { self[PreviewHarnessKey.self] }
        set { self[PreviewHarnessKey.self] = newValue }
    }
}

struct WidgetBG<B: View>: ViewModifier {
    @Environment(\.widgetPreviewHarness) var harness
    let background: B
    func body(content: Content) -> some View {
        if harness {
            ZStack { background; content.padding(16) }
        } else {
            content.containerBackground(for: .widget) { background }
        }
    }
}

extension View {
    func widgetBackground<B: View>(@ViewBuilder _ background: () -> B) -> some View {
        modifier(WidgetBG(background: background()))
    }
}

/// 写真の上の文字を読めるように、下から影を敷く
struct PhotoBackground: View {
    let image: UIImage
    var body: some View {
        ZStack {
            Image(uiImage: image).resizable().scaledToFill()
            LinearGradient(colors: [.clear, .black.opacity(0.55)], startPoint: .center, endPoint: .bottom)
        }
    }
}

// MARK: - アプリから渡される家族の情報

struct Member: Codable {
    let id: Int
    let n: String          // 呼び名
    let p: String?         // 写真のファイル名
    let e: Double?         // 次に会う日(秒)
    let mc: Int            // 今月つながった日
    let my: Int            // 今年会えた日
    let child: Bool        // 一緒に暮らす子ども(つながったボタンは出さない)
}

func loadMembers() -> [Member] {
    guard let json = sharedDefaults?.string(forKey: "members"),
          let data = json.data(using: .utf8),
          let list = try? JSONDecoder().decode([Member].self, from: data)
    else { return [] }
    return list
}

/// 次に会う日までの日数(過ぎていれば nil)
func daysUntil(_ epoch: Double?) -> Int? {
    guard let e = epoch else { return nil }
    let cal = Calendar.current
    let d = cal.dateComponents([.day], from: cal.startOfDay(for: Date()),
                               to: cal.startOfDay(for: Date(timeIntervalSince1970: e))).day ?? -1
    return d >= 0 ? d : nil
}

// MARK: - 家族を選ぶ(ウィジェットの編集画面)

struct FamilyMemberEntity: AppEntity {
    let id: String
    let name: String
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "家族"
    static var defaultQuery = FamilyMemberQuery()
    var displayRepresentation: DisplayRepresentation { DisplayRepresentation(title: "\(name)") }
}

struct FamilyMemberQuery: EntityQuery {
    func entities(for identifiers: [String]) async throws -> [FamilyMemberEntity] {
        loadMembers().filter { identifiers.contains(String($0.id)) }
            .map { FamilyMemberEntity(id: String($0.id), name: $0.n) }
    }
    func suggestedEntities() async throws -> [FamilyMemberEntity] {
        loadMembers().map { FamilyMemberEntity(id: String($0.id), name: $0.n) }
    }
}

struct SelectFamilyIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "家族を選ぶ"
    static var description = IntentDescription("表示する家族を選びます。選ばなければ、次に会う日がいちばん近い家族を表示します。")
    @Parameter(title: "家族") var member: FamilyMemberEntity?
    init() {}
}

// MARK: - ウィジェットから「電話した」などを残す

struct LogContactIntent: AppIntent {
    static var title: LocalizedStringResource = "つながった日を残す"
    static var isDiscoverable = false
    @Parameter(title: "家族") var memberId: Int
    @Parameter(title: "つながり方") var kind: String

    init() {}
    init(memberId: Int, kind: String) {
        self.memberId = memberId
        self.kind = kind
    }

    func perform() async throws -> some IntentResult {
        let d = sharedDefaults
        // アプリが次に開いたとき、この待ち行列を記録に取り込む
        var pending = (try? JSONSerialization.jsonObject(with: Data((d?.string(forKey: "pendingLogs") ?? "[]").utf8))) as? [[String: Any]] ?? []
        pending.append(["id": memberId, "k": kind, "t": Date().timeIntervalSince1970])
        if let data = try? JSONSerialization.data(withJSONObject: pending) {
            d?.set(String(data: data, encoding: .utf8), forKey: "pendingLogs")
        }
        // 表示をすぐ進めるため、今日まだ数えていなければ「今月つながった日」を1つ増やす
        let todayKey = "touched-\(memberId)-\(Calendar.current.startOfDay(for: Date()).timeIntervalSince1970)"
        if d?.bool(forKey: todayKey) != true, d?.bool(forKey: "connectedToday-\(memberId)") != true {
            var list = loadMembers()
            if let i = list.firstIndex(where: { $0.id == memberId }) {
                let m = list[i]
                list[i] = Member(id: m.id, n: m.n, p: m.p, e: m.e, mc: m.mc + 1, my: m.my, child: m.child)
                if let data = try? JSONEncoder().encode(list) { d?.set(String(data: data, encoding: .utf8), forKey: "members") }
            }
            d?.set(true, forKey: todayKey)
        }
        d?.set(memberId, forKey: "lastTappedMember")
        d?.set(kind, forKey: "lastTappedKind")
        d?.set(Date().timeIntervalSince1970, forKey: "lastTappedAt")
        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}

// MARK: - 次に会う日

struct NextEntry: TimelineEntry {
    let date: Date
    let member: Member?
    let days: Int?
    let photo: UIImage?
    let photoLocked: Bool      // 写真を付けているのに未購入
    let choiceLocked: Bool     // 家族を選んだのに未購入
    let hasFamily: Bool
    let justTapped: String?    // いま押したつながり方(押した直後の表示)
}

let meetFormatter: DateFormatter = {
    let f = DateFormatter()
    f.locale = Locale(identifier: "ja_JP")
    f.dateFormat = "M月d日(E)"
    return f
}()

struct ContactButtons: View {
    let member: Member
    let compact: Bool
    private let kinds: [(String, String)] = [("call", "phone"), ("video", "video"), ("message", "message")]
    var body: some View {
        HStack(spacing: compact ? 6 : 8) {
            ForEach(kinds, id: \.0) { k in
                Button(intent: LogContactIntent(memberId: member.id, kind: k.0)) {
                    Image(systemName: k.1)
                        .font(.system(size: compact ? 12 : 14, weight: .medium))
                        .frame(maxWidth: .infinity, minHeight: compact ? 24 : 28)
                }
                .buttonStyle(.plain)
                .foregroundColor(Tone.accent)
                .background(RoundedRectangle(cornerRadius: 8).fill(Tone.accent.opacity(0.12)))
            }
        }
    }
}

struct NextWidgetView: View {
    @Environment(\.widgetFamily) var envFamily
    let entry: NextEntry
    /// 確認画面で大きさを指定するため
    var familyOverride: WidgetFamily? = nil
    private var family: WidgetFamily { familyOverride ?? envFamily }

    var body: some View {
        switch family {
        case .accessoryInline: inline
        case .accessoryRectangular: rectangular
        case .accessoryCircular: circular
        case .systemMedium: medium
        default: small
        }
    }

    private var hint: String? {
        if entry.justTapped != nil { return nil }
        if entry.choiceLocked { return "家族を選ぶのは Pro" }
        if entry.photoLocked { return "写真つきは Pro" }
        return nil
    }

    private var tappedText: String? {
        guard let k = entry.justTapped else { return nil }
        let l = ["call": "電話した", "video": "ビデオ通話", "message": "メッセージ"][k] ?? "つながった"
        return "「\(l)」を残しました"
    }

    // ロック画面
    private var inline: some View {
        Group {
            if let m = entry.member, let d = entry.days {
                Text(d == 0 ? "今日、\(m.n)に会えます" : "\(m.n)まで あと\(d)日")
            } else if let m = entry.member {
                Text("\(m.n)と今月 \(m.mc)日")
            } else {
                Text("LifeCounter")
            }
        }.widgetBackground { Color.clear }
    }

    private var rectangular: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let m = entry.member, let d = entry.days {
                Text(d == 0 ? "今日、会えます" : "\(m.n)まで").font(label(12)).widgetAccentable()
                Text(d == 0 ? m.n : "あと \(d) 日").font(.system(size: 22, weight: .semibold, design: .serif))
            } else if let m = entry.member {
                Text("\(m.n)と今月つながった日").font(label(12)).widgetAccentable()
                Text("\(m.mc) 日").font(.system(size: 22, weight: .semibold, design: .serif))
            } else {
                Text("LifeCounter").font(label(12))
                Text("家族を登録してください").font(label(13))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .widgetBackground { Color.clear }
    }

    private var circular: some View {
        VStack(spacing: -2) {
            Text("\(entry.days ?? entry.member?.mc ?? 0)").font(.system(size: 20, weight: .semibold, design: .serif))
            Text(entry.days != nil ? "日" : "今月").font(label(9))
        }
        .widgetBackground { AccessoryWidgetBackground() }
    }

    // 主役の数字(次に会う日があればカウントダウン、なければ今月つながった日)
    @ViewBuilder
    private func headline(light: Bool, big: CGFloat) -> some View {
        let main = light ? Color.white : Tone.accent
        let sub = light ? Color.white.opacity(0.85) : Tone.muted
        if let m = entry.member {
            if let d = entry.days {
                if d == 0 {
                    Text("今日、\(m.n)に会えます").font(label(16, .semibold)).foregroundColor(light ? .white : Tone.accent)
                } else {
                    Text("\(m.n)に会えるまで").font(label(12)).foregroundColor(sub)
                        .lineLimit(2).minimumScaleFactor(0.8)
                    HStack(alignment: .firstTextBaseline, spacing: 3) {
                        Text("あと").font(label(11)).foregroundColor(sub)
                        Text("\(d)").font(number(big)).foregroundColor(main)
                        Text("日").font(label(12)).foregroundColor(sub)
                    }
                }
            } else {
                // 名前が長くても切れないよう、2行に分ける
                Text("\(m.n)と\n今月つながった日").font(label(12)).foregroundColor(sub)
                    .lineLimit(2).minimumScaleFactor(0.8)
                HStack(alignment: .firstTextBaseline, spacing: 3) {
                    Text("\(m.mc)").font(number(big)).foregroundColor(main)
                    Text("日").font(label(12)).foregroundColor(sub)
                }
            }
        }
    }

    @ViewBuilder
    private var small: some View {
        if let m = entry.member {
            if let photo = entry.photo {
                VStack(alignment: .leading, spacing: 0) {
                    Spacer()
                    headline(light: true, big: 40)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                .widgetBackground { PhotoBackground(image: photo) }
            } else {
                VStack(alignment: .leading, spacing: 2) {
                    headline(light: false, big: 44)
                    Spacer(minLength: 0)
                    if let t = tappedText {
                        Text(t).font(label(10, .semibold)).foregroundColor(Tone.accent)
                    } else if let h = hint {
                        Text(h).font(label(10, .semibold)).foregroundColor(Tone.accent)
                    } else if !m.child {
                        ContactButtons(member: m, compact: true)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .widgetBackground { Tone.bg }
            }
        } else {
            empty
        }
    }

    @ViewBuilder
    private var medium: some View {
        if let m = entry.member {
            HStack(spacing: 14) {
                Group {
                    if let photo = entry.photo {
                        Image(uiImage: photo).resizable().scaledToFill()
                    } else {
                        ZStack {
                            Tone.warm
                            Text(String(m.n.prefix(1))).font(.system(size: 40, weight: .light, design: .serif))
                                .foregroundColor(Tone.accent)
                        }
                    }
                }
                .frame(width: 112, height: 112)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

                VStack(alignment: .leading, spacing: 2) {
                    headline(light: false, big: 42)
                    if let e = m.e, entry.days != nil {
                        Text(meetFormatter.string(from: Date(timeIntervalSince1970: e))).font(label(11)).foregroundColor(Tone.text)
                    }
                    Spacer(minLength: 0)
                    if let t = tappedText {
                        Text(t).font(label(11, .semibold)).foregroundColor(Tone.accent)
                    } else if let h = hint {
                        Text(h).font(label(11, .semibold)).foregroundColor(Tone.accent)
                    } else if !m.child {
                        ContactButtons(member: m, compact: false)
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
            Text("LifeCounter").font(label(12)).foregroundColor(Tone.muted)
            Spacer(minLength: 0)
            Text(entry.hasFamily ? "次に会う日を入れると、ここで数えます" : "家族を登録すると、ここに表示されます")
                .font(label(12)).foregroundColor(Tone.text).lineLimit(3)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .widgetBackground { Tone.bg }
    }
}

/// 表示する家族を決める: 選ばれた家族(Pro) → なければ、次に会う日がいちばん近い家族 → なければ先頭
func makeNextEntry(selectedId: String?) -> NextEntry {
    let d = sharedDefaults
    let isPro = d?.bool(forKey: "isPro") ?? false
    let members = loadMembers()
    var chosen: Member? = nil
    var choiceLocked = false
    if let sid = selectedId, let m = members.first(where: { String($0.id) == sid }) {
        if isPro { chosen = m } else { choiceLocked = true }
    }
    if chosen == nil {
        chosen = members.filter { daysUntil($0.e) != nil }.min { daysUntil($0.e)! < daysUntil($1.e)! }
            ?? members.first
    }
    var photo: UIImage? = nil
    var photoLocked = false
    if let m = chosen, m.p != nil {
        if isPro { photo = loadPhoto(m.p) } else { photoLocked = true }
    }
    // 押した直後の10秒だけ「残しました」を出す
    var tapped: String? = nil
    if let at = d?.object(forKey: "lastTappedAt") as? Double, Date().timeIntervalSince1970 - at < 10,
       d?.integer(forKey: "lastTappedMember") == chosen?.id {
        tapped = d?.string(forKey: "lastTappedKind")
    }
    return NextEntry(date: Date(), member: chosen, days: daysUntil(chosen?.e), photo: photo,
                     photoLocked: photoLocked, choiceLocked: choiceLocked,
                     hasFamily: !members.isEmpty, justTapped: tapped)
}

// MARK: - 思い出(Pro)

struct Memory {
    let photo: UIImage?
    let y: Int, m: Int, d: Int
    let name: String
    let note: String
    let yearsAgo: Int
}

struct MemoryEntry: TimelineEntry {
    let date: Date
    let isPro: Bool
    let memory: Memory?
}

/// 「◯年前の今日」を優先し、なければ日替わりで1枚選ぶ
func makeMemoryEntry() -> MemoryEntry {
    let d = sharedDefaults
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
                // 年に「2,025」のような区切りが付かないよう、数字は文字列にしてから並べる
                Text(verbatim: "\(String(m.y)).\(String(m.m)).\(String(m.d))  \(m.name)").font(label(11)).foregroundColor(.white.opacity(0.85))
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
