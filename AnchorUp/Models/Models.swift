import SwiftUI
import UIKit

// MARK: - 乗組員(乗組員セクションのデモ用。将来の共有機能で本格利用)

struct CrewMember: Identifiable, Equatable {
    let id: UUID
    let name: String
    let initial: String
    let color: Color
    /// 準備の進捗 (0.0 - 1.0)
    var progress: Double

    init(id: UUID = UUID(), name: String, initial: String, color: Color, progress: Double) {
        self.id = id
        self.name = name
        self.initial = initial
        self.color = color
        self.progress = progress
    }
}

/// 誰か一人が持てば足りる共有アイテム(船倉シェア。乗組員セクションのデモ用)
struct SharedItem: Identifiable {
    let id: UUID
    var name: String
    var assignee: CrewMember?

    init(id: UUID = UUID(), name: String, assignee: CrewMember? = nil) {
        self.id = id
        self.name = name
        self.assignee = assignee
    }
}

// MARK: - 予定(航海)

/// 旅行・お出かけの予定。持ち物セットを紐付けて準備状況を測る。
struct Voyage: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var title: String
    var destination: String
    var date: Date
    /// 時刻まで指定しているか
    var hasTime: Bool
    /// 持っていく持ち物セットのID
    var linkedKitIDs: [UUID]
    /// 「Anchor Up」で出航済みにした日時。nil なら未出航
    var completedAt: Date?
    /// 船倉(みんなで分担する共有の持ち物)
    var holdItems: [HoldItem]
    /// 招待した乗組員のID(航海図で色分け表示される)
    var memberIDs: [UUID]

    init(
        id: UUID = UUID(),
        title: String,
        destination: String = "",
        date: Date,
        hasTime: Bool = false,
        linkedKitIDs: [UUID] = [],
        completedAt: Date? = nil,
        holdItems: [HoldItem] = [],
        memberIDs: [UUID] = []
    ) {
        self.id = id
        self.title = title
        self.destination = destination
        self.date = date
        self.hasTime = hasTime
        self.linkedKitIDs = linkedKitIDs
        self.completedAt = completedAt
        self.holdItems = holdItems
        self.memberIDs = memberIDs
    }

    /// 出航まで残り日数(過去なら負、当日は 0)
    var daysUntilDeparture: Int {
        let cal = Calendar.current
        let from = cal.startOfDay(for: Date())
        let to = cal.startOfDay(for: date)
        return cal.dateComponents([.day], from: from, to: to).day ?? 0
    }

    var isPast: Bool { daysUntilDeparture < 0 }

    /// 出航済み or 日付が過ぎた予定は「終わった航海」
    var isFinished: Bool { completedAt != nil || isPast }

    /// 「出航まであと2日」など
    var countdownText: String {
        let days = daysUntilDeparture
        if days < 0 { return "終了しました" }
        if days == 0 { return "本日、出航" }
        if days == 1 { return "明日、出航" }
        return "出航まであと\(days)日"
    }

    /// 「7月26日(土)」+ 時刻(任意)
    var dateText: String {
        let base = date.formatted(
            Date.FormatStyle(locale: .init(identifier: "ja_JP"))
                .month(.wide).day().weekday(.short)
        )
        guard hasTime else { return base }
        let time = date.formatted(
            Date.FormatStyle(locale: .init(identifier: "ja_JP")).hour().minute()
        )
        return "\(base) \(time)"
    }
}

// holdItems は後から追加したため、旧データでも読めるよう明示デコード
extension Voyage {
    enum CodingKeys: String, CodingKey {
        case id, title, destination, date, hasTime, linkedKitIDs, completedAt, holdItems, memberIDs
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        title = try c.decode(String.self, forKey: .title)
        destination = try c.decodeIfPresent(String.self, forKey: .destination) ?? ""
        date = try c.decode(Date.self, forKey: .date)
        hasTime = try c.decodeIfPresent(Bool.self, forKey: .hasTime) ?? false
        linkedKitIDs = try c.decodeIfPresent([UUID].self, forKey: .linkedKitIDs) ?? []
        completedAt = try c.decodeIfPresent(Date.self, forKey: .completedAt)
        holdItems = try c.decodeIfPresent([HoldItem].self, forKey: .holdItems) ?? []
        memberIDs = try c.decodeIfPresent([UUID].self, forKey: .memberIDs) ?? []
    }
}

// MARK: - 船倉(みんなで分担する共有の持ち物)

/// 船倉アイテムの担当
enum HoldAssignee: Codable, Equatable {
    case unassigned  // 未定
    case me          // あなた
    case crew(UUID)  // 乗組員
}

struct HoldItem: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var name: String
    var assignee: HoldAssignee = .unassigned

    var isAssigned: Bool { assignee != .unassigned }
}

// MARK: - 過去の記録(寄港の記録セクションのデモ用)

struct PastVoyage: Identifiable {
    let id = UUID()
    let title: String
    let dateLabel: String
    let symbolName: String
    let tint: Color
}

// MARK: - 乗組員名簿(乗組員タブ・永続化)

/// ローカルに保存する乗組員。配色は Codable にするため番号で持つ。
struct Crewmate: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var name: String
    var colorIndex: Int
    /// メモ(担当・役割など任意)
    var note: String = ""

    var initial: String { String(name.prefix(1)) }
    var color: Color { CrewPalette.color(at: colorIndex) }
}

enum CrewPalette {
    static let all: [Color] = [
        AnchorTheme.tileIndigo, AnchorTheme.tileTerracotta, AnchorTheme.tileMustard,
        AnchorTheme.tileCharcoal, AnchorTheme.hullTan, AnchorTheme.seaShallow,
    ]
    static func color(at index: Int) -> Color {
        all[((index % all.count) + all.count) % all.count]
    }

    /// その配色の上に載せて読みやすい前景色(明るい地は暗い字、暗い地は明るい字)
    static func foreground(at index: Int) -> Color {
        let ui = UIColor(color(at: index))
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        ui.getRed(&r, green: &g, blue: &b, alpha: &a)
        let luminance = 0.299 * r + 0.587 * g + 0.114 * b
        return luminance > 0.58 ? AnchorTheme.seaDeep : AnchorTheme.moonGlow
    }
}

// MARK: - サンプルデータ(デモ用セクション向け)

enum SampleData {
    static let you = CrewMember(name: "あなた", initial: "あ", color: AnchorTheme.tileIndigo, progress: 0.5)
    static let haruka = CrewMember(name: "ハルカ", initial: "ハ", color: AnchorTheme.tileTerracotta, progress: 0.9)
    static let kenta = CrewMember(name: "ケンタ", initial: "ケ", color: AnchorTheme.tileMustard, progress: 0.3)
    static let mio = CrewMember(name: "ミオ", initial: "ミ", color: AnchorTheme.tileCharcoal, progress: 1.0)

    static var crew: [CrewMember] { [you, haruka, kenta, mio] }

    static var sharedItems: [SharedItem] {
        [
            SharedItem(name: "テント", assignee: nil),
            SharedItem(name: "クーラーボックス", assignee: haruka),
        ]
    }

    static let pastVoyages: [PastVoyage] = [
        PastVoyage(title: "江の島 日帰り", dateLabel: "6月14日", symbolName: "sun.haze", tint: AnchorTheme.tileTerracotta),
        PastVoyage(title: "高尾山ハイク", dateLabel: "5月3日", symbolName: "leaf", tint: AnchorTheme.seaShallow),
        PastVoyage(title: "花見ピクニック", dateLabel: "4月5日", symbolName: "camera", tint: AnchorTheme.tileIndigo),
    ]
}
