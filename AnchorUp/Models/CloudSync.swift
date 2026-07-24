import Foundation
import FirebaseAuth
import FirebaseFirestore

/// 匿名認証でサインインし、この端末のuidを提供する。
/// 将来 Apple/Google サインインへ「昇格(link)」させる余地を残した設計。
@MainActor
final class AuthService: ObservableObject {
    @Published private(set) var uid: String?

    func start() async {
        if let user = Auth.auth().currentUser {
            uid = user.uid
            return
        }
        do {
            let result = try await Auth.auth().signInAnonymously()
            uid = result.user.uid
        } catch {
            // サインインに失敗してもアプリはローカルのみで動作を続ける
            print("Anchor Up: 匿名サインインに失敗しました - \(error.localizedDescription)")
        }
    }
}

/// クラウドに保存する状態のまとまり。1ユーザー1ドキュメントに丸ごと収める
/// (持ち物リストの規模は小さく、Firestoreの1MiB制限に対して十分余裕がある)。
struct CloudState: Codable, Equatable {
    var kits: [PackingKit]
    var homeSections: [HomeSectionConfig]
    var plans: [Voyage]
    var wallpaper: Wallpaper
    var crew: [Crewmate]
}

/// AnchorStoreの状態をFirestoreへ同期するエンジン。
/// 既存のJSONEncoder/Decoderで丸ごとシリアライズし、単一フィールドに保存することで
/// Firestore側のCodableブリッジの癖(enum等のネスト表現)を避け、確実性を優先している。
final class CloudSyncEngine {
    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?
    private var uploadTask: Task<Void, Never>?
    /// 直近に自分がアップロードしたペイロード。受信時のフィードバックループ防止に使う。
    private var lastUploadedPayload: String?

    private func docRef(uid: String) -> DocumentReference {
        db.collection("users").document(uid)
    }

    func fetchOnce(uid: String) async -> CloudState? {
        guard let snapshot = try? await docRef(uid: uid).getDocument(),
              snapshot.exists,
              let payload = snapshot.data()?["payload"] as? String,
              let data = payload.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(CloudState.self, from: data)
    }

    /// 変更をまとめて(デバウンスして)アップロードする
    func upload(uid: String, state: CloudState) {
        uploadTask?.cancel()
        uploadTask = Task {
            guard let data = try? JSONEncoder().encode(state),
                  let payload = String(data: data, encoding: .utf8),
                  payload != lastUploadedPayload else { return }
            try? await Task.sleep(nanoseconds: 500_000_000)
            guard !Task.isCancelled else { return }
            lastUploadedPayload = payload
            try? await docRef(uid: uid).setData([
                "payload": payload,
                "updatedAt": FieldValue.serverTimestamp(),
            ])
        }
    }

    /// リアルタイムのリスナーを張る。自分が直前に書き込んだ内容は無視する。
    func listen(uid: String, onChange: @escaping (CloudState) -> Void) {
        listener?.remove()
        listener = docRef(uid: uid).addSnapshotListener { [weak self] snapshot, _ in
            guard let self, let snapshot, snapshot.exists,
                  let payload = snapshot.data()?["payload"] as? String,
                  payload != self.lastUploadedPayload,
                  let data = payload.data(using: .utf8),
                  let state = try? JSONDecoder().decode(CloudState.self, from: data) else { return }
            onChange(state)
        }
    }

    func stop() {
        listener?.remove()
        listener = nil
    }
}
