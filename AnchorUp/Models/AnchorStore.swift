import SwiftUI

/// アプリの状態を保持するストア。
/// 持ち物セット(日常使い)は端末に永続化する。
/// 航海(ホームのヒーロー)は現状デモ用のメモリ保持。
@MainActor
final class AnchorStore: ObservableObject {
    /// 用途別の持ち物セット。変更のたびに保存する。
    @Published var kits: [PackingKit] { didSet { save() } }

    /// ホーム画面のセクション構成(順序・表示/非表示)
    @Published var homeSections: [HomeSectionConfig] { didSet { saveLayout() } }

    /// 予定(航海)の一覧。変更のたびに保存する。
    @Published var plans: [Voyage] { didSet { savePlans() } }

    private let kitsKey = "anchorup.kits.v1"
    private let layoutKey = "anchorup.homeLayout.v1"
    private let plansKey = "anchorup.plans.v1"

    init() {
        self.kits = Self.load(key: "anchorup.kits.v1") ?? DefaultKits.seed()
        let savedLayout = Self.loadLayout(key: "anchorup.homeLayout.v1")
        self.homeSections = HomeSectionConfig.reconciled(savedLayout ?? HomeSectionConfig.defaultLayout)
        self.plans = Self.loadPlans(key: "anchorup.plans.v1") ?? []
    }

    // MARK: - 予定(航海)

    /// 直近の未来の予定(なければ nil)
    var nextPlan: Voyage? {
        let today = Calendar.current.startOfDay(for: Date())
        return plans
            .filter { Calendar.current.startOfDay(for: $0.date) >= today }
            .sorted { $0.date < $1.date }
            .first
    }

    /// 未来の予定の総数
    var upcomingPlanCount: Int {
        let today = Calendar.current.startOfDay(for: Date())
        return plans.filter { Calendar.current.startOfDay(for: $0.date) >= today }.count
    }

    /// 予定に紐付いた持ち物セット(削除済みのIDは除外)
    func linkedKits(_ plan: Voyage) -> [PackingKit] {
        plan.linkedKitIDs.compactMap { id in kits.first { $0.id == id } }
    }

    /// 紐付いたセットの合計(チェック済み, 総数)
    func planItemCounts(_ plan: Voyage) -> (checked: Int, total: Int) {
        let ks = linkedKits(plan)
        let total = ks.reduce(0) { $0 + $1.items.count }
        let checked = ks.reduce(0) { $0 + $1.checkedCount }
        return (checked, total)
    }

    func planProgress(_ plan: Voyage) -> Double {
        let c = planItemCounts(plan)
        guard c.total > 0 else { return 0 }
        return Double(c.checked) / Double(c.total)
    }

    /// 紐付いた持ち物がすべてチェック済みか(1件以上ある前提)
    func planReady(_ plan: Voyage) -> Bool {
        let c = planItemCounts(plan)
        return c.total > 0 && c.checked == c.total
    }

    @discardableResult
    func addPlan(title: String, destination: String, date: Date, hasTime: Bool, kitIDs: [UUID]) -> Voyage? {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        let plan = Voyage(
            title: trimmed,
            destination: destination.trimmingCharacters(in: .whitespacesAndNewlines),
            date: date,
            hasTime: hasTime,
            linkedKitIDs: kitIDs
        )
        plans.append(plan)
        return plan
    }

    func updatePlan(_ plan: Voyage, title: String, destination: String, date: Date, hasTime: Bool, kitIDs: [UUID]) {
        guard let i = plans.firstIndex(where: { $0.id == plan.id }) else { return }
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty { plans[i].title = trimmed }
        plans[i].destination = destination.trimmingCharacters(in: .whitespacesAndNewlines)
        plans[i].date = date
        plans[i].hasTime = hasTime
        plans[i].linkedKitIDs = kitIDs
    }

    func deletePlan(_ plan: Voyage) {
        plans.removeAll { $0.id == plan.id }
    }

    // MARK: - ホームのレイアウト

    func setSectionVisible(_ kind: HomeSectionKind, _ visible: Bool) {
        guard let i = homeSections.firstIndex(where: { $0.kind == kind }) else { return }
        homeSections[i].isVisible = visible
    }

    func moveSections(fromOffsets: IndexSet, toOffset: Int) {
        homeSections.move(fromOffsets: fromOffsets, toOffset: toOffset)
    }

    func setSectionSize(_ kind: HomeSectionKind, _ size: HomeSectionSize) {
        guard let i = homeSections.firstIndex(where: { $0.kind == kind }) else { return }
        homeSections[i].size = size
    }

    /// 長押しドラッグ用: kind を target の位置へ移動する。
    /// 下方向(from < to)は target の後ろ、上方向は target の前に入れる。
    func moveSection(_ kind: HomeSectionKind, over target: HomeSectionKind) {
        guard kind != target,
              let from = homeSections.firstIndex(where: { $0.kind == kind }),
              let to = homeSections.firstIndex(where: { $0.kind == target }) else { return }
        homeSections.move(fromOffsets: IndexSet(integer: from), toOffset: to > from ? to + 1 : to)
    }

    func resetHomeLayout() {
        homeSections = HomeSectionConfig.defaultLayout
    }

    // MARK: - ピン留め

    var pinnedKits: [PackingKit] { kits.filter(\.isPinned) }

    func togglePin(_ kit: PackingKit) {
        guard let i = kits.firstIndex(where: { $0.id == kit.id }) else { return }
        kits[i].isPinned.toggle()
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

    private func saveLayout() {
        guard let data = try? JSONEncoder().encode(homeSections) else { return }
        UserDefaults.standard.set(data, forKey: layoutKey)
    }

    private static func loadLayout(key: String) -> [HomeSectionConfig]? {
        guard let data = UserDefaults.standard.data(forKey: key),
              let layout = try? JSONDecoder().decode([HomeSectionConfig].self, from: data) else { return nil }
        return layout
    }

    private func savePlans() {
        guard let data = try? JSONEncoder().encode(plans) else { return }
        UserDefaults.standard.set(data, forKey: plansKey)
    }

    private static func loadPlans(key: String) -> [Voyage]? {
        guard let data = UserDefaults.standard.data(forKey: key),
              let plans = try? JSONDecoder().decode([Voyage].self, from: data) else { return nil }
        return plans
    }
}
