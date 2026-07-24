import SwiftUI

/// アプリの状態を保持するストア。
/// 持ち物セット(日常使い)は端末に永続化する。
/// 航海(ホームのヒーロー)は現状デモ用のメモリ保持。
@MainActor
final class AnchorStore: ObservableObject {
    /// 用途別の持ち物セット。変更のたびに保存する。
    @Published var kits: [PackingKit] { didSet { save() } }

    /// ホームのヒーローに出す航海(旅行の予定)
    @Published var voyage: Voyage

    private let kitsKey = "anchorup.kits.v1"

    var me: CrewMember { voyage.crew.first ?? SampleData.you }

    init(voyage: Voyage = SampleData.nextVoyage) {
        self.voyage = voyage
        self.kits = Self.load(key: "anchorup.kits.v1") ?? DefaultKits.seed()
    }

    // MARK: - 全体の集計(ホーム用)

    /// 全セットを通した「今日の準備」進捗
    var overallProgress: Double {
        let total = kits.reduce(0) { $0 + $1.items.count }
        guard total > 0 else { return 0 }
        let done = kits.reduce(0) { $0 + $1.checkedCount }
        return Double(done) / Double(total)
    }

    var totalItemCount: Int { kits.reduce(0) { $0 + $1.items.count } }
    var checkedItemCount: Int { kits.reduce(0) { $0 + $1.checkedCount } }

    /// まだチェックしていない持ち物(ホームの抜粋用)。セット情報を添える。
    func remainingPreview(limit: Int) -> [(kit: PackingKit, item: KitItem)] {
        var result: [(PackingKit, KitItem)] = []
        for kit in kits {
            for item in kit.remaining {
                result.append((kit, item))
                if result.count >= limit { return result }
            }
        }
        return result
    }

    // MARK: - セット操作

    func addKit(name: String, symbolName: String, color: KitColor) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        kits.append(PackingKit(name: trimmed, symbolName: symbolName, color: color, items: []))
    }

    func deleteKit(_ kit: PackingKit) {
        kits.removeAll { $0.id == kit.id }
    }

    func updateKit(_ kit: PackingKit, name: String, symbolName: String, color: KitColor) {
        guard let idx = kits.firstIndex(where: { $0.id == kit.id }) else { return }
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty { kits[idx].name = trimmed }
        kits[idx].symbolName = symbolName
        kits[idx].color = color
    }

    // MARK: - セット内の持ち物操作

    func addItem(to kit: PackingKit, name: String) {
        guard let idx = kits.firstIndex(where: { $0.id == kit.id }) else { return }
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        kits[idx].items.append(KitItem(name: trimmed))
    }

    func toggleItem(in kit: PackingKit, item: KitItem) {
        guard let kIdx = kits.firstIndex(where: { $0.id == kit.id }),
              let iIdx = kits[kIdx].items.firstIndex(where: { $0.id == item.id }) else { return }
        kits[kIdx].items[iIdx].isChecked.toggle()
    }

    func deleteItem(in kit: PackingKit, item: KitItem) {
        guard let kIdx = kits.firstIndex(where: { $0.id == kit.id }) else { return }
        kits[kIdx].items.removeAll { $0.id == item.id }
    }

    func renameItem(in kit: PackingKit, item: KitItem, to newName: String) {
        guard let kIdx = kits.firstIndex(where: { $0.id == kit.id }),
              let iIdx = kits[kIdx].items.firstIndex(where: { $0.id == item.id }) else { return }
        let trimmed = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        kits[kIdx].items[iIdx].name = trimmed
    }

    /// セットのチェックをすべて外す(翌日また使うためのリセット)
    func resetChecks(in kit: PackingKit) {
        guard let kIdx = kits.firstIndex(where: { $0.id == kit.id }) else { return }
        for i in kits[kIdx].items.indices {
            kits[kIdx].items[i].isChecked = false
        }
    }

    /// セットの持ち物をすべてチェック(まとめて準備OK)
    func checkAll(in kit: PackingKit) {
        guard let kIdx = kits.firstIndex(where: { $0.id == kit.id }) else { return }
        for i in kits[kIdx].items.indices {
            kits[kIdx].items[i].isChecked = true
        }
    }

    /// セット内の持ち物を並び替える
    func moveItems(in kit: PackingKit, fromOffsets: IndexSet, toOffset: Int) {
        guard let kIdx = kits.firstIndex(where: { $0.id == kit.id }) else { return }
        kits[kIdx].items.move(fromOffsets: fromOffsets, toOffset: toOffset)
    }

    /// セット自体を並び替える
    func moveKits(fromOffsets: IndexSet, toOffset: Int) {
        kits.move(fromOffsets: fromOffsets, toOffset: toOffset)
    }

    /// 現在のkitsからライブな値を取り出す(詳細画面で最新を参照するため)
    func kit(withID id: UUID) -> PackingKit? {
        kits.first { $0.id == id }
    }

    // MARK: - 永続化

    private func save() {
        guard let data = try? JSONEncoder().encode(kits) else { return }
        UserDefaults.standard.set(data, forKey: kitsKey)
    }

    private static func load(key: String) -> [PackingKit]? {
        guard let data = UserDefaults.standard.data(forKey: key),
              let kits = try? JSONDecoder().decode([PackingKit].self, from: data) else { return nil }
        return kits
    }
}
