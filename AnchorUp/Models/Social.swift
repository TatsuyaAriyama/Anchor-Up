import SwiftUI
import FirebaseFirestore

/// 乗船証に掲げるシンボル。錨だけは自前の図形で描く。
enum ProfileSymbol: String, CaseIterable, Identifiable {
    case anchor      // 錨(ブランドの印)
    case helm        // 舵輪
    case sailboat    // 帆船
    case compass     // 羅針盤
    case lifering    // 浮き輪
    case moon        // 月と星
    case waves       // 波
    case island      // 島
    case chart       // 海図
    case flags       // 信号旗
    case telescope   // 望遠鏡
    case star        // 北極星

    var id: String { rawValue }

    /// SF Symbols 名(錨のみ nil = 自前描画)
    var systemName: String? {
        switch self {
        case .anchor: nil
        case .helm: "helm"
        case .sailboat: "sailboat"
        case .compass: "location.north.circle"
        case .lifering: "lifepreserver"
        case .moon: "moon.stars"
        case .waves: "water.waves"
        case .island: "mountain.2"
        case .chart: "map"
        case .flags: "flag.2.crossed"
        case .telescope: "binoculars"
        case .star: "star"
        }
    }

    static func from(_ raw: String?) -> ProfileSymbol {
        guard let raw, let s = ProfileSymbol(rawValue: raw) else { return .anchor }
        return s
    }
}

/// 乗船証のシンボルを描くビュー(錨は自前の図形)
struct ProfileSymbolView: View {
    let symbol: ProfileSymbol
    var size: CGFloat = 24
    var color: Color = AnchorTheme.textPrimary

    var body: some View {
        if let name = symbol.systemName {
            Image(systemName: name)
                .font(.system(size: size * 0.86, weight: .regular))
                .foregroundStyle(color)
                .frame(width: size, height: size)
        } else {
            AnchorLogo(size: size, color: color)
        }
    }
}

/// 連携した友達(実在ユーザー)。ローカル名簿のCrewmateとは別物。
struct ConnectedFriend: Identifiable, Equatable {
    let uid: String
    var name: String
    var colorIndex: Int
    var symbol: ProfileSymbol = .anchor
    var motto: String = ""

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
    /// 乗船証のシンボルと、掲げる言葉
    @Published private(set) var mySymbol: ProfileSymbol = .anchor
    @Published private(set) var myMotto: String = ""
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
            mySymbol = ProfileSymbol.from(data["symbol"] as? String)
            myMotto = data["motto"] as? String ?? ""
            if myCode.isEmpty { await createProfile(ref: ref, uid: uid) }
            return
        }
        await createProfile(ref: ref, uid: uid)
    }

    private func createProfile(ref: DocumentReference, uid: String) async {
        let code = Self.generateCode()
        let colorIndex = Int.random(in: 0..<CrewPalette.all.count)
        let name = "船長"
        try? await ref.setData([
            "name": name, "code": code, "colorIndex": colorIndex,
            "symbol": ProfileSymbol.anchor.rawValue, "motto": "",
        ])
        try? await db.collection("codes").document(code).setData(["uid": uid])
        myCode = code
        myName = name
        myColorIndex = colorIndex
        mySymbol = .anchor
        myMotto = ""
    }

    /// 乗船証を更新する(名前・配色・シンボル・掲げる言葉)
    func updateProfile(name: String, colorIndex: Int, symbol: ProfileSymbol, motto: String) async {
        guard let uid else { return }
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedMotto = motto.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedName.isEmpty { myName = trimmedName }
        myColorIndex = colorIndex
        mySymbol = symbol
        myMotto = trimmedMotto

        try? await db.collection("profiles").document(uid).setData([
            "name": myName,
            "colorIndex": colorIndex,
            "symbol": symbol.rawValue,
            "motto": trimmedMotto,
        ], merge: true)

        // 連携済みの相手にも新しい表示を届ける
        await refreshMyProfileInConnections()
    }

    /// 自分が参加している connections の profiles を最新の乗船証で更新する
    private func refreshMyProfileInConnections() async {
        guard let uid else { return }
        guard let snap = try? await db.collection("connections")
            .whereField("members", arrayContains: uid).getDocuments() else { return }
        for doc in snap.documents {
            try? await doc.reference.setData([
                "profiles": [
                    uid: [
                        "name": myName,
                        "colorIndex": myColorIndex,
                        "symbol": mySymbol.rawValue,
                        "motto": myMotto,
                    ],
                ],
            ], merge: true)
        }
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
                uid: [
                    "name": myName,
                    "colorIndex": myColorIndex,
                    "symbol": mySymbol.rawValue,
                    "motto": myMotto,
                ],
                friendUid: [
                    "name": pdata["name"] as? String ?? "船長",
                    "colorIndex": pdata["colorIndex"] as? Int ?? 0,
                    "symbol": pdata["symbol"] as? String ?? ProfileSymbol.anchor.rawValue,
                    "motto": pdata["motto"] as? String ?? "",
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
                        colorIndex: prof["colorIndex"] as? Int ?? 0,
                        symbol: ProfileSymbol.from(prof["symbol"] as? String),
                        motto: prof["motto"] as? String ?? ""
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
