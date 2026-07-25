import SwiftUI
import FirebaseFirestore

/// 共有航海の船倉アイテム。担当は実在ユーザーのuidで持つ。
struct SharedHoldItem: Identifiable, Equatable {
    var id: String = UUID().uuidString
    var name: String
    /// 担当者のuid。nil なら未定
    var assigneeUid: String?

    var isAssigned: Bool { assigneeUid != nil }

    var dict: [String: Any] {
        var d: [String: Any] = ["id": id, "name": name]
        if let assigneeUid { d["assigneeUid"] = assigneeUid }
        return d
    }

    init(id: String = UUID().uuidString, name: String, assigneeUid: String? = nil) {
        self.id = id
        self.name = name
        self.assigneeUid = assigneeUid
    }

    init?(dict: [String: Any]) {
        guard let id = dict["id"] as? String, let name = dict["name"] as? String else { return nil }
        self.id = id
        self.name = name
        self.assigneeUid = dict["assigneeUid"] as? String
    }
}

/// 仲間と共有している航海。Firestoreの voyages コレクションに置かれ、
/// メンバー全員の端末にリアルタイムで同期される。
struct SharedVoyage: Identifiable, Equatable {
    var id: String
    var title: String
    var destination: String
    var date: Date
    var hasTime: Bool
    var ownerUid: String
    /// 参加者(作成者を含む)のuid
    var memberUids: [String]
    /// 表示用のスナップショット(uid -> 名前 / 配色)
    var memberNames: [String: String]
    var memberColors: [String: Int]
    var holdItems: [SharedHoldItem]
    var completedAt: Date?

    // MARK: - 表示ヘルパー(ローカルのVoyageと揃える)

    var daysUntilDeparture: Int {
        let cal = Calendar.current
        return cal.dateComponents([.day],
                                  from: cal.startOfDay(for: Date()),
                                  to: cal.startOfDay(for: date)).day ?? 0
    }

    var isPast: Bool { daysUntilDeparture < 0 }
    var isFinished: Bool { completedAt != nil || isPast }

    var countdownText: String {
        let days = daysUntilDeparture
        if days < 0 { return "終了しました" }
        if days == 0 { return "本日、出航" }
        if days == 1 { return "明日、出航" }
        return "出航まであと\(days)日"
    }

    var dateText: String {
        let base = date.formatted(
            Date.FormatStyle(locale: .init(identifier: "ja_JP")).month(.wide).day().weekday(.short)
        )
        guard hasTime else { return base }
        let time = date.formatted(Date.FormatStyle(locale: .init(identifier: "ja_JP")).hour().minute())
        return "\(base) \(time)"
    }

    func name(of uid: String) -> String { memberNames[uid] ?? "船長" }
    func color(of uid: String) -> Color { CrewPalette.color(at: memberColors[uid] ?? 0) }

    /// 自分以外の参加者
    func others(excluding uid: String) -> [String] {
        memberUids.filter { $0 != uid }
    }

    // MARK: - Firestore 変換

    var dict: [String: Any] {
        var d: [String: Any] = [
            "title": title,
            "destination": destination,
            "date": Timestamp(date: date),
            "hasTime": hasTime,
            "ownerUid": ownerUid,
            "memberUids": memberUids,
            "memberNames": memberNames,
            "memberColors": memberColors,
            "holdItems": holdItems.map(\.dict),
        ]
        if let completedAt { d["completedAt"] = Timestamp(date: completedAt) }
        return d
    }

    init(
        id: String = UUID().uuidString,
        title: String,
        destination: String = "",
        date: Date,
        hasTime: Bool = false,
        ownerUid: String,
        memberUids: [String],
        memberNames: [String: String] = [:],
        memberColors: [String: Int] = [:],
        holdItems: [SharedHoldItem] = [],
        completedAt: Date? = nil
    ) {
        self.id = id
        self.title = title
        self.destination = destination
        self.date = date
        self.hasTime = hasTime
        self.ownerUid = ownerUid
        self.memberUids = memberUids
        self.memberNames = memberNames
        self.memberColors = memberColors
        self.holdItems = holdItems
        self.completedAt = completedAt
    }

    init?(id: String, dict: [String: Any]) {
        guard let title = dict["title"] as? String,
              let ts = dict["date"] as? Timestamp,
              let ownerUid = dict["ownerUid"] as? String,
              let memberUids = dict["memberUids"] as? [String] else { return nil }
        self.id = id
        self.title = title
        self.destination = dict["destination"] as? String ?? ""
        self.date = ts.dateValue()
        self.hasTime = dict["hasTime"] as? Bool ?? false
        self.ownerUid = ownerUid
        self.memberUids = memberUids
        self.memberNames = dict["memberNames"] as? [String: String] ?? [:]
        self.memberColors = dict["memberColors"] as? [String: Int] ?? [:]
        self.holdItems = (dict["holdItems"] as? [[String: Any]] ?? []).compactMap(SharedHoldItem.init(dict:))
        self.completedAt = (dict["completedAt"] as? Timestamp)?.dateValue()
    }
}

/// 共有航海のリアルタイム同期。メンバーに含まれる航海だけを購読する。
@MainActor
final class VoyageShareService: ObservableObject {
    @Published private(set) var voyages: [SharedVoyage] = []

    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?
    private(set) var uid: String?

    func start(uid: String) {
        self.uid = uid
        listener?.remove()
        listener = db.collection("voyages")
            .whereField("memberUids", arrayContains: uid)
            .addSnapshotListener { [weak self] snapshot, _ in
                guard let self, let docs = snapshot?.documents else { return }
                self.voyages = docs
                    .compactMap { SharedVoyage(id: $0.documentID, dict: $0.data()) }
                    .sorted { $0.date < $1.date }
            }
    }

    /// 直近の未完了の共有航海
    var nextVoyage: SharedVoyage? {
        voyages.filter { !$0.isFinished }.sorted { $0.date < $1.date }.first
    }

    func voyages(on day: Date) -> [SharedVoyage] {
        let cal = Calendar.current
        return voyages.filter { cal.isDate($0.date, inSameDayAs: day) }
    }

    // MARK: - 書き込み

    func save(_ voyage: SharedVoyage) {
        db.collection("voyages").document(voyage.id).setData(voyage.dict)
    }

    func delete(_ voyage: SharedVoyage) {
        db.collection("voyages").document(voyage.id).delete()
    }

    func addHoldItem(to voyage: SharedVoyage, name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        var v = voyage
        v.holdItems.append(SharedHoldItem(name: trimmed))
        save(v)
    }

    func deleteHoldItem(in voyage: SharedVoyage, item: SharedHoldItem) {
        var v = voyage
        v.holdItems.removeAll { $0.id == item.id }
        save(v)
    }

    func assignHold(in voyage: SharedVoyage, item: SharedHoldItem, to assigneeUid: String?) {
        var v = voyage
        guard let i = v.holdItems.firstIndex(where: { $0.id == item.id }) else { return }
        v.holdItems[i].assigneeUid = assigneeUid
        save(v)
    }

    func complete(_ voyage: SharedVoyage) {
        var v = voyage
        v.completedAt = Date()
        save(v)
    }

    func stop() {
        listener?.remove()
        listener = nil
    }
}
