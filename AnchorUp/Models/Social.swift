import SwiftUI
import FirebaseFirestore

/// 連携した友達(実在ユーザー)。ローカル名簿のCrewmateとは別物。
struct ConnectedFriend: Identifiable, Equatable {
    let uid: String
    var name: String
    var colorIndex: Int

    var id: String { uid }
    var initial: String { String(name.prefix(1)) }
    var color: Color { CrewPalette.color(at: colorIndex) }
}

/// プロフィール・招待コード・連携(connections)を扱うサービス。
/// 予定の相互共有のための「誰が誰か」の土台。
@MainActor
final class SocialService: ObservableObject {
    /// 自分の招待コード(友達に渡す)
    @Published private(set) var myCode: String = ""
    /// 自分の表示名(友達に見える)
    @Published private(set) var myName: String = "船長"
    @Published private(set) var myColorIndex: Int = 0
    /// 連携した友達
    @Published private(set) var friends: [ConnectedFriend] = []

    private let db = Firestore.firestore()
    private(set) var uid: String?
    private var connListener: ListenerRegistration?

    func start(uid: String) async {
        self.uid = uid
        await ensureProfile(uid: uid)
        listenConnections(uid: uid)
    }

    // MARK: - プロフィール

    private func ensureProfile(uid: String) async {
        let ref = db.collection("profiles").document(uid)
        if let snap = try? await ref.getDocument(), snap.exists, let data = snap.data() {
            myCode = data["code"] as? String ?? ""
            myName = data["name"] as? String ?? "船長"
            myColorIndex = data["colorIndex"] as? Int ?? 0
            if myCode.isEmpty { await createProfile(ref: ref, uid: uid) }
            return
        }
        await createProfile(ref: ref, uid: uid)
    }

    private func createProfile(ref: DocumentReference, uid: String) async {
        let code = Self.generateCode()
        let colorIndex = Int.random(in: 0..<CrewPalette.all.count)
        let name = "船長"
        try? await ref.setData(["name": name, "code": code, "colorIndex": colorIndex])
        try? await db.collection("codes").document(code).setData(["uid": uid])
        myCode = code
        myName = name
        myColorIndex = colorIndex
    }

    func rename(_ newName: String) async {
        let trimmed = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let uid, !trimmed.isEmpty, trimmed != myName else { return }
        myName = trimmed
        try? await db.collection("profiles").document(uid).setData(["name": trimmed], merge: true)
    }

    // MARK: - 連携

    /// 友達のコードで連携する。成功時 nil、失敗時はエラーメッセージ。
    func connect(code rawCode: String) async -> String? {
        guard let uid else { return "サインインしていません" }
        let code = rawCode.uppercased().trimmingCharacters(in: .whitespacesAndNewlines)
        guard code.count == 6 else { return "コードは6文字です" }
        if code == myCode { return "自分のコードです" }

        guard let codeSnap = try? await db.collection("codes").document(code).getDocument(),
              codeSnap.exists, let friendUid = codeSnap.data()?["uid"] as? String else {
            return "コードが見つかりません"
        }
        guard let profSnap = try? await db.collection("profiles").document(friendUid).getDocument(),
              let pdata = profSnap.data() else {
            return "相手のプロフィールを取得できません"
        }

        let pairID = [uid, friendUid].sorted().joined(separator: "_")
        try? await db.collection("connections").document(pairID).setData([
            "members": [uid, friendUid],
            "profiles": [
                uid: ["name": myName, "colorIndex": myColorIndex],
                friendUid: [
                    "name": pdata["name"] as? String ?? "船長",
                    "colorIndex": pdata["colorIndex"] as? Int ?? 0,
                ],
            ],
            "createdAt": FieldValue.serverTimestamp(),
        ])
        return nil
    }

    private func listenConnections(uid: String) {
        connListener?.remove()
        connListener = db.collection("connections")
            .whereField("members", arrayContains: uid)
            .addSnapshotListener { [weak self] snapshot, _ in
                guard let self, let docs = snapshot?.documents else { return }
                var result: [ConnectedFriend] = []
                for doc in docs {
                    let data = doc.data()
                    guard let members = data["members"] as? [String],
                          let profiles = data["profiles"] as? [String: [String: Any]],
                          let otherUid = members.first(where: { $0 != uid }),
                          let prof = profiles[otherUid] else { continue }
                    result.append(ConnectedFriend(
                        uid: otherUid,
                        name: prof["name"] as? String ?? "船長",
                        colorIndex: prof["colorIndex"] as? Int ?? 0
                    ))
                }
                self.friends = result.sorted { $0.name < $1.name }
            }
    }

    // 紛らわしい文字(0,O,1,I等)を除いた6文字コード
    static func generateCode() -> String {
        let chars = Array("ABCDEFGHJKLMNPQRSTUVWXYZ23456789")
        return String((0..<6).map { _ in chars.randomElement()! })
    }
}
