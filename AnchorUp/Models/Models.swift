import SwiftUI

// MARK: - 乗組員

struct CrewMember: Identifiable, Equatable {
    let id: UUID
    let name: String
    let initial: String
    let color: Color
    /// 持ち物準備の進捗 (0.0 - 1.0)
    var progress: Double

    init(id: UUID = UUID(), name: String, initial: String, color: Color, progress: Double) {
        self.id = id
        self.name = name
        self.initial = initial
        self.color = color
        self.progress = progress
    }
}

// MARK: - 持ち物のカテゴリ

enum PackingCategory: String, CaseIterable, Identifiable {
    case gear = "道具"
    case clothing = "衣類"
    case electronics = "電子機器"
    case food = "食料・水"
    case health = "救急・衛生"
    case other = "その他"

    var id: String { rawValue }

    var symbolName: String {
        switch self {
        case .gear: "backpack"
        case .clothing: "tshirt"
        case .electronics: "bolt.batteryblock"
        case .food: "fork.knife"
        case .health: "cross.case"
        case .other: "shippingbox"
        }
    }

    var tint: Color {
        switch self {
        case .gear: AnchorTheme.hullTan
        case .clothing: AnchorTheme.tileIndigo
        case .electronics: AnchorTheme.tileCharcoal
        case .food: AnchorTheme.tileMustard
        case .health: AnchorTheme.tileTerracotta
        case .other: AnchorTheme.seaShallow
        }
    }
}

// MARK: - 持ち物アイテム

enum PackingStatus {
    case notStarted // 未完了
    case inProgress // 準備中
    case done       // 完了

    /// 信号旗のような色付きドット
    var flagColor: Color {
        switch self {
        case .notStarted: AnchorTheme.tileTerracotta
        case .inProgress: AnchorTheme.tileMustard
        case .done: AnchorTheme.seaShallow
        }
    }

    var label: String {
        switch self {
        case .notStarted: "未完了"
        case .inProgress: "準備中"
        case .done: "完了"
        }
    }

    /// タップで次の状態へ(未完了→準備中→完了→未完了)
    var next: PackingStatus {
        switch self {
        case .notStarted: .inProgress
        case .inProgress: .done
        case .done: .notStarted
        }
    }
}

struct PackingItem: Identifiable {
    let id: UUID
    var name: String
    var status: PackingStatus
    var category: PackingCategory

    init(id: UUID = UUID(), name: String, status: PackingStatus = .notStarted, category: PackingCategory = .other) {
        self.id = id
        self.name = name
        self.status = status
        self.category = category
    }
}

/// 誰か一人が持てば足りる共有アイテム(船倉シェア)
struct SharedItem: Identifiable {
    let id: UUID
    var name: String
    /// 担当者。nil なら未定
    var assignee: CrewMember?

    init(id: UUID = UUID(), name: String, assignee: CrewMember? = nil) {
        self.id = id
        self.name = name
        self.assignee = assignee
    }
}

// MARK: - 航海(予定)

struct Voyage: Identifiable {
    let id: UUID
    var title: String
    var destination: String
    var departureDate: Date
    var crew: [CrewMember]
    var myItems: [PackingItem]
    var sharedItems: [SharedItem]

    init(
        id: UUID = UUID(),
        title: String,
        destination: String,
        departureDate: Date,
        crew: [CrewMember],
        myItems: [PackingItem],
        sharedItems: [SharedItem]
    ) {
        self.id = id
        self.title = title
        self.destination = destination
        self.departureDate = departureDate
        self.crew = crew
        self.myItems = myItems
        self.sharedItems = sharedItems
    }

    /// 出航まで残り日数(当日は 0)
    var daysUntilDeparture: Int {
        let cal = Calendar.current
        let from = cal.startOfDay(for: .now)
        let to = cal.startOfDay(for: departureDate)
        return max(0, cal.dateComponents([.day], from: from, to: to).day ?? 0)
    }

    /// 自分の持ち物準備の進捗 (0.0 - 1.0)
    var myProgress: Double {
        guard !myItems.isEmpty else { return 0 }
        let done = myItems.filter { $0.status == .done }.count
        return Double(done) / Double(myItems.count)
    }

    var doneCount: Int { myItems.filter { $0.status == .done }.count }

    var isReadyToSail: Bool { !myItems.isEmpty && myProgress >= 1.0 }
}

/// 完了した過去の航海
struct PastVoyage: Identifiable {
    let id = UUID()
    let title: String
    let dateLabel: String
    let symbolName: String
    let tint: Color
}

// MARK: - サンプルデータ

enum SampleData {
    // 乗組員のIDを固定して、共有アイテムの担当参照と一致させる
    static let you = CrewMember(name: "あなた", initial: "あ", color: AnchorTheme.tileIndigo, progress: 0.5)
    static let haruka = CrewMember(name: "ハルカ", initial: "ハ", color: AnchorTheme.tileTerracotta, progress: 0.9)
    static let kenta = CrewMember(name: "ケンタ", initial: "ケ", color: AnchorTheme.tileMustard, progress: 0.3)
    static let mio = CrewMember(name: "ミオ", initial: "ミ", color: AnchorTheme.tileCharcoal, progress: 1.0)

    static var crew: [CrewMember] { [you, haruka, kenta, mio] }

    static var nextVoyage: Voyage {
        Voyage(
            title: "沖ノ島キャンプ",
            destination: "千葉・沖ノ島",
            departureDate: Calendar.current.date(byAdding: .day, value: 2, to: .now) ?? .now,
            crew: crew,
            myItems: [
                PackingItem(name: "モバイルバッテリー", status: .notStarted, category: .electronics),
                PackingItem(name: "ヘッドライト", status: .done, category: .electronics),
                PackingItem(name: "レインウェア", status: .inProgress, category: .clothing),
                PackingItem(name: "着替え", status: .done, category: .clothing),
                PackingItem(name: "救急セット", status: .notStarted, category: .health),
                PackingItem(name: "日焼け止め", status: .done, category: .health),
                PackingItem(name: "行動食", status: .notStarted, category: .food),
                PackingItem(name: "シュラフ", status: .inProgress, category: .gear),
            ],
            sharedItems: [
                SharedItem(name: "テント", assignee: nil),
                SharedItem(name: "クーラーボックス", assignee: haruka),
                SharedItem(name: "ランタン", assignee: nil),
            ]
        )
    }

    static let pastVoyages: [PastVoyage] = [
        PastVoyage(title: "江の島 日帰り", dateLabel: "6月14日", symbolName: "sun.haze", tint: AnchorTheme.tileTerracotta),
        PastVoyage(title: "高尾山ハイク", dateLabel: "5月3日", symbolName: "leaf", tint: AnchorTheme.seaShallow),
        PastVoyage(title: "花見ピクニック", dateLabel: "4月5日", symbolName: "camera", tint: AnchorTheme.tileIndigo),
    ]
}
