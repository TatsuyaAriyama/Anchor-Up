import SwiftUI

/// アプリの状態を保持するストア。
/// 現状は単一の航海をメモリ上で扱う(将来 SwiftData などへ差し替え可能)。
@MainActor
final class AnchorStore: ObservableObject {
    @Published var voyage: Voyage

    /// 「あなた」の乗組員情報
    var me: CrewMember { voyage.crew.first ?? SampleData.you }

    init(voyage: Voyage = SampleData.nextVoyage) {
        self.voyage = voyage
        syncMyProgress()
    }

    // MARK: - 自分の持ち物

    /// タップで状態を1つ進める(未完了→準備中→完了→未完了)
    func advanceStatus(_ item: PackingItem) {
        guard let idx = voyage.myItems.firstIndex(where: { $0.id == item.id }) else { return }
        voyage.myItems[idx].status = voyage.myItems[idx].status.next
        syncMyProgress()
    }

    /// チェック操作: 完了 ⇄ 未完了 をトグル
    func toggleDone(_ item: PackingItem) {
        guard let idx = voyage.myItems.firstIndex(where: { $0.id == item.id }) else { return }
        voyage.myItems[idx].status = voyage.myItems[idx].status == .done ? .notStarted : .done
        syncMyProgress()
    }

    func addMyItem(name: String, category: PackingCategory) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        voyage.myItems.append(PackingItem(name: trimmed, status: .notStarted, category: category))
        syncMyProgress()
    }

    func deleteMyItem(_ item: PackingItem) {
        voyage.myItems.removeAll { $0.id == item.id }
        syncMyProgress()
    }

    func renameMyItem(_ item: PackingItem, to newName: String) {
        let trimmed = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty,
              let idx = voyage.myItems.firstIndex(where: { $0.id == item.id }) else { return }
        voyage.myItems[idx].name = trimmed
    }

    // MARK: - 船倉シェア(共有アイテム)

    /// 担当を自分にする / すでに自分なら担当を外す
    func toggleAssignSelf(_ item: SharedItem) {
        guard let idx = voyage.sharedItems.firstIndex(where: { $0.id == item.id }) else { return }
        if voyage.sharedItems[idx].assignee?.id == me.id {
            voyage.sharedItems[idx].assignee = nil
        } else {
            voyage.sharedItems[idx].assignee = me
        }
    }

    func assign(_ item: SharedItem, to member: CrewMember?) {
        guard let idx = voyage.sharedItems.firstIndex(where: { $0.id == item.id }) else { return }
        voyage.sharedItems[idx].assignee = member
    }

    func addSharedItem(name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        voyage.sharedItems.append(SharedItem(name: trimmed))
    }

    func deleteSharedItem(_ item: SharedItem) {
        voyage.sharedItems.removeAll { $0.id == item.id }
    }

    // MARK: - 内部

    /// 乗組員リスト先頭「あなた」の進捗を、実際の持ち物進捗に同期する
    private func syncMyProgress() {
        guard !voyage.crew.isEmpty else { return }
        voyage.crew[0].progress = voyage.myProgress
    }
}
