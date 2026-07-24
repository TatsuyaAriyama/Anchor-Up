import SwiftUI

// MARK: - セットの配色(Codableにするため列挙で持つ)

enum KitColor: String, Codable, CaseIterable, Identifiable {
    case indigo, terracotta, charcoal, mustard, tan, teal
    var id: String { rawValue }

    var color: Color {
        switch self {
        case .indigo: AnchorTheme.tileIndigo
        case .terracotta: AnchorTheme.tileTerracotta
        case .charcoal: AnchorTheme.tileCharcoal
        case .mustard: AnchorTheme.tileMustard
        case .tan: AnchorTheme.hullTan
        case .teal: AnchorTheme.seaShallow
        }
    }
}

// MARK: - 持ち物1件

struct KitItem: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var name: String
    var isChecked: Bool = false
}

// MARK: - 持ち物セット(用途別の再利用リスト)

struct PackingKit: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var name: String
    var symbolName: String
    var color: KitColor
    var items: [KitItem]
    /// ホームにピン留めしているか
    var isPinned: Bool = false

    var checkedCount: Int { items.filter(\.isChecked).count }
    var progress: Double { items.isEmpty ? 0 : Double(checkedCount) / Double(items.count) }
    var isComplete: Bool { !items.isEmpty && checkedCount == items.count }
    var remaining: [KitItem] { items.filter { !$0.isChecked } }
}

extension PackingKit {
    enum CodingKeys: String, CodingKey {
        case id, name, symbolName, color, items, isPinned
    }

    // isPinnedは後から追加したため、旧データ(キー無し)でも読めるようにする
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        name = try c.decode(String.self, forKey: .name)
        symbolName = try c.decode(String.self, forKey: .symbolName)
        color = try c.decode(KitColor.self, forKey: .color)
        items = try c.decode([KitItem].self, forKey: .items)
        isPinned = try c.decodeIfPresent(Bool.self, forKey: .isPinned) ?? false
    }
}

// MARK: - アイコン候補(セット作成・編集で使う)

enum KitSymbols {
    static let all: [String] = [
        "briefcase", "sun.max", "figure.run", "backpack",
        "laptopcomputer", "camera", "book", "cup.and.saucer",
        "key", "cross.case", "bag", "umbrella",
    ]
}

// MARK: - 既定のセット(初回起動時に用意する例)

enum DefaultKits {
    static func seed() -> [PackingKit] {
        [
            PackingKit(
                name: "仕事",
                symbolName: "briefcase",
                color: .charcoal,
                items: [
                    KitItem(name: "社員証"),
                    KitItem(name: "ノートPC"),
                    KitItem(name: "財布"),
                    KitItem(name: "スマホ"),
                    KitItem(name: "名刺入れ"),
                ]
            ),
            PackingKit(
                name: "毎日の持ち物",
                symbolName: "sun.max",
                color: .tan,
                items: [
                    KitItem(name: "鍵"),
                    KitItem(name: "財布"),
                    KitItem(name: "スマホ"),
                    KitItem(name: "イヤホン"),
                    KitItem(name: "モバイルバッテリー"),
                ]
            ),
            PackingKit(
                name: "ジム",
                symbolName: "figure.run",
                color: .terracotta,
                items: [
                    KitItem(name: "ウェア"),
                    KitItem(name: "タオル"),
                    KitItem(name: "シューズ"),
                    KitItem(name: "水筒"),
                ]
            ),
        ]
    }
}
