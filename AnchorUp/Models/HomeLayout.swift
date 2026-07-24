import SwiftUI

/// ホーム画面に並べられるセクションの種類。
enum HomeSectionKind: String, Codable, CaseIterable, Identifiable {
    case todayItems   // 持ち物リスト
    case pinnedKits   // ピン留めセット
    case nextVoyage   // 次の予定(航海)
    case crew         // 乗組員
    case portLog      // 寄港の記録

    var id: String { rawValue }

    var title: String {
        switch self {
        case .todayItems: "持ち物リスト"
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

/// セクションの大きさ。全幅カードか、半分幅のタイルか。
enum HomeSectionSize: String, Codable, CaseIterable {
    case full // 全幅
    case half // 半分(横に2つ並ぶ)

    var label: String {
        switch self {
        case .full: "全幅"
        case .half: "半分"
        }
    }

    var symbol: String {
        switch self {
        case .full: "rectangle.fill"
        case .half: "rectangle.lefthalf.filled"
        }
    }
}

/// 1セクションの表示設定。順序は配列で表す。
struct HomeSectionConfig: Codable, Identifiable, Equatable, Hashable {
    var kind: HomeSectionKind
    var isVisible: Bool
    var size: HomeSectionSize = .full
    var id: String { kind.rawValue }

    enum CodingKeys: String, CodingKey {
        case kind, isVisible, size
    }

    init(kind: HomeSectionKind, isVisible: Bool, size: HomeSectionSize = .full) {
        self.kind = kind
        self.isVisible = isVisible
        self.size = size
    }

    // sizeは後から追加したため、旧データ(キー無し)でも読めるようにする
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        kind = try c.decode(HomeSectionKind.self, forKey: .kind)
        isVisible = try c.decode(Bool.self, forKey: .isVisible)
        size = try c.decodeIfPresent(HomeSectionSize.self, forKey: .size) ?? .full
    }

    /// 既定のレイアウト。初期は「持ち物リスト」と「次の予定」だけを表示し、
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
