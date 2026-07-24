import SwiftUI

/// ホーム画面に並べられるセクションの種類。
enum HomeSectionKind: String, Codable, CaseIterable, Identifiable {
    case todayItems   // 今日の持ち物
    case pinnedKits   // ピン留めセット
    case nextVoyage   // 次の予定(航海)
    case crew         // 乗組員
    case portLog      // 寄港の記録

    var id: String { rawValue }

    var title: String {
        switch self {
        case .todayItems: "今日の持ち物"
        case .pinnedKits: "ピン留めセット"
        case .nextVoyage: "次の予定"
        case .crew: "乗組員"
        case .portLog: "寄港の記録"
        }
    }

    var symbol: String {
        switch self {
        case .todayItems: "checklist"
        case .pinnedKits: "pin"
        case .nextVoyage: "sailboat"
        case .crew: "person.2"
        case .portLog: "clock.arrow.circlepath"
        }
    }

    /// カスタマイズ画面で出す説明
    var detail: String {
        switch self {
        case .todayItems: "全セットの未チェックを抜粋"
        case .pinnedKits: "ピン留めした持ち物セット"
        case .nextVoyage: "直近の旅行・お出かけ予定"
        case .crew: "参加メンバーと準備状況"
        case .portLog: "これまでの記録"
        }
    }
}

/// 1セクションの表示設定。順序は配列で表す。
struct HomeSectionConfig: Codable, Identifiable, Equatable {
    var kind: HomeSectionKind
    var isVisible: Bool
    var id: String { kind.rawValue }

    /// 既定のレイアウト。初期は「今日の持ち物」と「次の予定」だけを表示し、
    /// 他はカスタマイズでオンにできる。
    static var defaultLayout: [HomeSectionConfig] {
        [
            .init(kind: .todayItems, isVisible: true),
            .init(kind: .nextVoyage, isVisible: true),
            .init(kind: .pinnedKits, isVisible: false),
            .init(kind: .crew, isVisible: false),
            .init(kind: .portLog, isVisible: false),
        ]
    }

    /// 保存データに無い種類(将来追加分)を末尾に補完する
    static func reconciled(_ configs: [HomeSectionConfig]) -> [HomeSectionConfig] {
        var result = configs
        let present = Set(result.map(\.kind))
        for kind in HomeSectionKind.allCases where !present.contains(kind) {
            result.append(.init(kind: kind, isVisible: true))
        }
        return result
    }
}
