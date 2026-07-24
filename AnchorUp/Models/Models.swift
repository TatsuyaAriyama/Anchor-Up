import SwiftUI

// MARK: - 乗組員

struct CrewMember: Identifiable {
    let id = UUID()
    let name: String
    let initial: String
    let color: Color
    /// 持ち物準備の進捗 (0.0 - 1.0)
    let progress: Double
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
}

struct PackingItem: Identifiable {
    let id = UUID()
    let name: String
    let status: PackingStatus
}

/// 誰か一人が持てば足りる共有アイテム(船倉シェア)
struct SharedItem: Identifiable {
    let id = UUID()
    let name: String
    /// 担当者。nil なら未定
    let assignee: CrewMember?
}

// MARK: - 航海(予定)

struct Voyage: Identifiable {
    let id = UUID()
    let title: String
    let destination: String
    let departureDate: Date
    let crew: [CrewMember]
    let myItems: [PackingItem]
    let sharedItems: [SharedItem]

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

    var isReadyToSail: Bool { myProgress >= 1.0 }
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
    static let crew: [CrewMember] = [
        CrewMember(name: "あなた", initial: "あ", color: AnchorTheme.tileIndigo, progress: 0.6),
        CrewMember(name: "ハルカ", initial: "ハ", color: AnchorTheme.tileTerracotta, progress: 0.9),
        CrewMember(name: "ケンタ", initial: "ケ", color: AnchorTheme.tileMustard, progress: 0.3),
        CrewMember(name: "ミオ", initial: "ミ", color: AnchorTheme.tileCharcoal, progress: 1.0),
    ]

    static var nextVoyage: Voyage {
        Voyage(
            title: "沖ノ島キャンプ",
            destination: "千葉・沖ノ島",
            departureDate: Calendar.current.date(byAdding: .day, value: 2, to: .now) ?? .now,
            crew: crew,
            myItems: [
                PackingItem(name: "モバイルバッテリー", status: .notStarted),
                PackingItem(name: "レインウェア", status: .inProgress),
                PackingItem(name: "救急セット", status: .notStarted),
                PackingItem(name: "ヘッドライト", status: .done),
                PackingItem(name: "着替え", status: .done),
                PackingItem(name: "日焼け止め", status: .done),
            ],
            sharedItems: [
                SharedItem(name: "テント", assignee: nil),
                SharedItem(name: "クーラーボックス", assignee: crew[1]),
            ]
        )
    }

    static let pastVoyages: [PastVoyage] = [
        PastVoyage(title: "江の島 日帰り", dateLabel: "6月14日", symbolName: "sun.haze", tint: AnchorTheme.tileTerracotta),
        PastVoyage(title: "高尾山ハイク", dateLabel: "5月3日", symbolName: "leaf", tint: AnchorTheme.seaShallow),
        PastVoyage(title: "花見ピクニック", dateLabel: "4月5日", symbolName: "camera", tint: AnchorTheme.tileIndigo),
    ]
}
