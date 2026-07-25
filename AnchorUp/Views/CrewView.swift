import SwiftUI

/// 乗組員タブ。次の航海の「船倉(みんなで分担する持ち物)」と、乗組員名簿を管理する。
struct CrewView: View {
    @ObservedObject var store: AnchorStore
    @ObservedObject var social: SocialService
    @ObservedObject var share: VoyageShareService
    @State private var showingAddCrew = false
    @State private var editing: Crewmate?
    @State private var newHoldName = ""
    @State private var newSharedHoldName = ""
    @State private var showingConnect = false
    @FocusState private var holdFocused: Bool
    @FocusState private var sharedHoldFocused: Bool

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                header

                connectedSection

                // 仲間と共有している航海があれば、そちらの船倉を優先して見せる
                if let voyage = share.nextVoyage {
                    SharedHoldCard(share: share, voyage: voyage,
                                   newItemName: $newSharedHoldName,
                                   focused: $sharedHoldFocused)
                } else if let plan = store.nextPlan {
                    HoldCard(store: store, plan: plan,
                             newHoldName: $newHoldName, holdFocused: $holdFocused)
                } else {
                    holdEmpty
                }

                rosterSection
            }
            .padding(.horizontal, 20)
            .padding(.top, 24)
            .padding(.bottom, 190) // 舵輪ぶんの余白
        }
        .scrollIndicators(.hidden)
        .sheet(isPresented: $showingConnect) {
            ConnectView(social: social)
        }
        .sheet(isPresented: $showingAddCrew) {
            CrewEditSheet(title: "乗組員を追加") { name, note in
                if let mate = store.addCrew(name: name) {
                    store.updateCrew(mate, name: name, note: note)
                    Haptics.soft()
                }
            }
        }
        .sheet(item: $editing) { mate in
            CrewEditSheet(
                title: "乗組員を編集",
                initialName: mate.name,
                initialNote: mate.note,
                onDelete: { store.removeCrew(mate) }
            ) { name, note in
                store.updateCrew(mate, name: name, note: note)
            }
        }
    }

    // MARK: - ヘッダー

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("乗組員")
                .font(.anchorHeading(26))
                .foregroundStyle(AnchorTheme.textPrimary)
            Text("船倉の分担と、仲間の名簿")
                .font(.anchorBody(13))
                .foregroundStyle(AnchorTheme.textSecondary)
        }
    }

    // MARK: - つながっている仲間(実在ユーザー)

    private var connectedSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                SectionHeader(title: "つながっている仲間")
                Button {
                    Haptics.tap()
                    showingConnect = true
                } label: {
                    Label("友達とつながる", systemImage: "link.badge.plus")
                        .font(.anchorHeading(13))
                        .foregroundStyle(AnchorTheme.accent)
                }
                .buttonStyle(.plain)
            }

            if social.friends.isEmpty {
                Button {
                    Haptics.tap()
                    showingConnect = true
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "link")
                            .foregroundStyle(AnchorTheme.hullTan)
                        Text("招待コードを交換すると、予定を共有できます")
                            .font(.anchorBody(13))
                            .foregroundStyle(AnchorTheme.textPrimary)
                        Spacer(minLength: 0)
                    }
                    .padding(16)
                    .background(AnchorTheme.surface, in: RoundedRectangle(cornerRadius: AnchorTheme.cornerMedium, style: .continuous))
                }
                .buttonStyle(.plain)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 14) {
                        ForEach(social.friends) { friend in
                            VStack(spacing: 6) {
                                ZStack {
                                    Circle().fill(friend.color)
                                    Text(friend.initial)
                                        .font(.anchorHeading(20))
                                        .foregroundStyle(AnchorTheme.textPrimary)
                                    // 実在ユーザーの印
                                    Image(systemName: "link")
                                        .font(.system(size: 9, weight: .bold))
                                        .foregroundStyle(AnchorTheme.seaDeep)
                                        .padding(3)
                                        .background(AnchorTheme.moonGlow, in: Circle())
                                        .offset(x: 16, y: 16)
                                }
                                .frame(width: 50, height: 50)
                                Text(friend.name)
                                    .font(.anchorBody(11))
                                    .foregroundStyle(AnchorTheme.textSecondary)
                                    .lineLimit(1)
                            }
                            .frame(width: 62)
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        }
    }

    // MARK: - 船倉(予定が無い時)

    private var holdEmpty: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "船倉")
            HStack(spacing: 10) {
                Image(systemName: "shippingbox")
                    .foregroundStyle(AnchorTheme.textSecondary)
                Text("予定を立てると、共有の持ち物を仲間で分担できます。")
                    .font(.anchorBody(13))
                    .foregroundStyle(AnchorTheme.textSecondary)
                Spacer(minLength: 0)
            }
            .padding(16)
            .background(AnchorTheme.surface, in: RoundedRectangle(cornerRadius: AnchorTheme.cornerMedium, style: .continuous))
        }
    }

    // MARK: - 名簿

    private var rosterSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                SectionHeader(title: "乗組員名簿")
                Button {
                    Haptics.tap()
                    showingAddCrew = true
                } label: {
                    Label("追加", systemImage: "person.badge.plus")
                        .font(.anchorHeading(13))
                        .foregroundStyle(AnchorTheme.accent)
                }
                .buttonStyle(.plain)
            }

            if store.crew.isEmpty {
                HStack(spacing: 10) {
                    Image(systemName: "flag.2.crossed")
                        .foregroundStyle(AnchorTheme.textSecondary)
                    Text("一緒に出かける仲間を登録しよう")
                        .font(.anchorBody(13))
                        .foregroundStyle(AnchorTheme.textSecondary)
                    Spacer(minLength: 0)
                }
                .padding(16)
                .background(AnchorTheme.surface, in: RoundedRectangle(cornerRadius: AnchorTheme.cornerMedium, style: .continuous))
            } else {
                VStack(spacing: 8) {
                    ForEach(store.crew) { mate in
                        Button {
                            Haptics.tap()
                            editing = mate
                        } label: {
                            HStack(spacing: 14) {
                                CrewmateAvatar(mate: mate, size: 42)
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(mate.name)
                                        .font(.anchorHeading(15))
                                        .foregroundStyle(AnchorTheme.textPrimary)
                                    if !mate.note.isEmpty {
                                        Text(mate.note)
                                            .font(.anchorBody(12))
                                            .foregroundStyle(AnchorTheme.textSecondary)
                                            .lineLimit(1)
                                    }
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.anchorHeading(12))
                                    .foregroundStyle(AnchorTheme.textSecondary)
                            }
                            .padding(14)
                            .background(AnchorTheme.surface, in: RoundedRectangle(cornerRadius: AnchorTheme.cornerMedium, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}

// MARK: - 共有航海の船倉(仲間とリアルタイムに分担)

private struct SharedHoldCard: View {
    @ObservedObject var share: VoyageShareService
    let voyage: SharedVoyage
    @Binding var newItemName: String
    var focused: FocusState<Bool>.Binding

    private var myUid: String { share.uid ?? "" }
    private var assignedCount: Int { voyage.holdItems.filter(\.isAssigned).count }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 見出し(共有中であることを明示)
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(AnchorTheme.seaShallow.opacity(0.28))
                    Image(systemName: "shippingbox.fill")
                        .font(.anchorBody(16))
                        .foregroundStyle(AnchorTheme.seaShallow)
                }
                .frame(width: 40, height: 40)
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text("船倉")
                            .font(.anchorHeading(16))
                            .foregroundStyle(AnchorTheme.textPrimary)
                        Image(systemName: "link")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(AnchorTheme.seaShallow)
                    }
                    Text("\(voyage.title) を \(voyage.others(excluding: myUid).count + 1)人で分担")
                        .font(.anchorBody(12))
                        .foregroundStyle(AnchorTheme.textSecondary)
                }
                Spacer()
                if !voyage.holdItems.isEmpty {
                    Text("\(assignedCount)/\(voyage.holdItems.count)")
                        .font(.anchorDisplay(14, weight: .semibold))
                        .foregroundStyle(assignedCount == voyage.holdItems.count ? AnchorTheme.accent : AnchorTheme.textSecondary)
                }
            }

            if voyage.holdItems.isEmpty {
                Text("テント・クーラーなど、誰か一人が持てば足りる物を積もう。仲間の画面にもすぐ届きます。")
                    .font(.anchorBody(12))
                    .foregroundStyle(AnchorTheme.textSecondary)
                    .padding(.vertical, 4)
            }

            VStack(spacing: 8) {
                ForEach(voyage.holdItems) { item in
                    SharedHoldRow(share: share, voyage: voyage, item: item)
                }
                addRow
            }

            if !voyage.holdItems.isEmpty {
                HStack {
                    if assignedCount < voyage.holdItems.count {
                        Label("\(voyage.holdItems.count - assignedCount)件が未定", systemImage: "exclamationmark.circle")
                            .font(.anchorBody(12))
                            .foregroundStyle(AnchorTheme.accent)
                    } else {
                        Label("分担が決まりました", systemImage: "checkmark.seal")
                            .font(.anchorBody(12))
                            .foregroundStyle(AnchorTheme.accent)
                    }
                    Spacer()
                }
                .padding(.top, 2)
            }
        }
        .padding(16)
        .background(AnchorTheme.surface, in: RoundedRectangle(cornerRadius: AnchorTheme.cornerLarge, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AnchorTheme.cornerLarge, style: .continuous)
                .strokeBorder(AnchorTheme.seaShallow.opacity(0.3), lineWidth: 1)
        )
    }

    private var addRow: some View {
        HStack(spacing: 12) {
            Image(systemName: "plus.circle.fill")
                .font(.anchorBody(20))
                .foregroundStyle(AnchorTheme.accent)
            TextField("船倉に積む(例: テント)", text: $newItemName)
                .font(.anchorBody(15))
                .foregroundStyle(AnchorTheme.textPrimary)
                .focused(focused)
                .submitLabel(.done)
                .onSubmit(add)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(AnchorTheme.surfaceRaised, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func add() {
        let trimmed = newItemName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        share.addHoldItem(to: voyage, name: trimmed)
        newItemName = ""
        Haptics.tap()
        focused.wrappedValue = true
    }
}

private struct SharedHoldRow: View {
    @ObservedObject var share: VoyageShareService
    let voyage: SharedVoyage
    let item: SharedHoldItem

    private var myUid: String { share.uid ?? "" }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: item.isAssigned ? "shippingbox.fill" : "shippingbox")
                .font(.anchorBody(16))
                .foregroundStyle(item.isAssigned ? AnchorTheme.hullTan : AnchorTheme.accent)
                .frame(width: 26)

            Text(item.name)
                .font(.anchorBody(15))
                .foregroundStyle(AnchorTheme.textPrimary)

            Spacer()

            Menu {
                Button { assign(myUid) } label: { Label("あなた", systemImage: "person.fill") }
                ForEach(voyage.others(excluding: myUid), id: \.self) { uid in
                    Button { assign(uid) } label: { Text(voyage.name(of: uid)) }
                }
                Button { assign(nil) } label: { Label("未定にする", systemImage: "questionmark") }
                Divider()
                Button(role: .destructive) {
                    withAnimation { share.deleteHoldItem(in: voyage, item: item) }
                } label: {
                    Label("船倉から降ろす", systemImage: "trash")
                }
            } label: {
                chip
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .background(AnchorTheme.surfaceRaised, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    @ViewBuilder
    private var chip: some View {
        if let uid = item.assigneeUid {
            let isMe = uid == myUid
            HStack(spacing: 6) {
                ZStack {
                    Circle().fill(isMe ? AnchorTheme.tileIndigo : voyage.color(of: uid))
                    Text(isMe ? "あ" : String(voyage.name(of: uid).prefix(1)))
                        .font(.anchorHeading(10))
                        .foregroundStyle(AnchorTheme.textPrimary)
                }
                .frame(width: 22, height: 22)
                Text(isMe ? "あなた" : voyage.name(of: uid))
                    .font(.anchorBody(13))
                    .foregroundStyle(AnchorTheme.textPrimary)
            }
            .padding(.leading, 4)
            .padding(.trailing, 10)
            .padding(.vertical, 4)
            .background(AnchorTheme.background.opacity(0.5), in: Capsule())
        } else {
            Text("担当を決める")
                .font(.anchorHeading(12))
                .foregroundStyle(AnchorTheme.seaDeep)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(AnchorTheme.accent, in: Capsule())
        }
    }

    private func assign(_ uid: String?) {
        withAnimation(.easeInOut(duration: 0.2)) {
            share.assignHold(in: voyage, item: item, to: uid)
        }
        Haptics.tap()
    }
}

// MARK: - 船倉カード(分担の仕切り)

private struct HoldCard: View {
    @ObservedObject var store: AnchorStore
    let plan: Voyage
    @Binding var newHoldName: String
    var holdFocused: FocusState<Bool>.Binding

    private var assignedCount: Int { plan.holdItems.filter(\.isAssigned).count }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 見出し
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(AnchorTheme.hullTan.opacity(0.16))
                    Image(systemName: "shippingbox.fill")
                        .font(.anchorBody(16))
                        .foregroundStyle(AnchorTheme.hullTan)
                }
                .frame(width: 40, height: 40)
                VStack(alignment: .leading, spacing: 2) {
                    Text("船倉")
                        .font(.anchorHeading(16))
                        .foregroundStyle(AnchorTheme.textPrimary)
                    Text("\(plan.title) の分担")
                        .font(.anchorBody(12))
                        .foregroundStyle(AnchorTheme.textSecondary)
                }
                Spacer()
                if !plan.holdItems.isEmpty {
                    Text("\(assignedCount)/\(plan.holdItems.count)")
                        .font(.anchorDisplay(14, weight: .semibold))
                        .foregroundStyle(assignedCount == plan.holdItems.count ? AnchorTheme.accent : AnchorTheme.textSecondary)
                }
            }

            if plan.holdItems.isEmpty {
                Text("テント・クーラー・ランタンなど、誰か一人が持てば足りる物を積もう。")
                    .font(.anchorBody(12))
                    .foregroundStyle(AnchorTheme.textSecondary)
                    .padding(.vertical, 4)
            }

            // 木箱(共有アイテム)を積む
            VStack(spacing: 8) {
                ForEach(plan.holdItems) { item in
                    HoldRow(store: store, plan: plan, item: item)
                }
                addRow
            }

            // 分担を共有
            if !plan.holdItems.isEmpty {
                HStack {
                    if assignedCount < plan.holdItems.count {
                        Label("\(plan.holdItems.count - assignedCount)件が未定", systemImage: "exclamationmark.circle")
                            .font(.anchorBody(12))
                            .foregroundStyle(AnchorTheme.accent)
                    } else {
                        Label("分担が決まりました", systemImage: "checkmark.seal")
                            .font(.anchorBody(12))
                            .foregroundStyle(AnchorTheme.accent)
                    }
                    Spacer()
                    ShareLink(item: store.holdManifestText(for: plan)) {
                        Label("分担を共有", systemImage: "square.and.arrow.up")
                            .font(.anchorHeading(13))
                            .foregroundStyle(AnchorTheme.seaDeep)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .background(AnchorTheme.hullTan, in: Capsule())
                    }
                }
                .padding(.top, 2)
            }
        }
        .padding(16)
        .background(AnchorTheme.surface, in: RoundedRectangle(cornerRadius: AnchorTheme.cornerLarge, style: .continuous))
    }

    private var addRow: some View {
        HStack(spacing: 12) {
            Image(systemName: "plus.circle.fill")
                .font(.anchorBody(20))
                .foregroundStyle(AnchorTheme.accent)
            TextField("船倉に積む(例: テント)", text: $newHoldName)
                .font(.anchorBody(15))
                .foregroundStyle(AnchorTheme.textPrimary)
                .focused(holdFocused)
                .submitLabel(.done)
                .onSubmit(addHold)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(AnchorTheme.surfaceRaised, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func addHold() {
        let trimmed = newHoldName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        store.addHoldItem(to: plan, name: trimmed)
        newHoldName = ""
        Haptics.tap()
        holdFocused.wrappedValue = true
    }
}

private struct HoldRow: View {
    @ObservedObject var store: AnchorStore
    let plan: Voyage
    let item: HoldItem

    var body: some View {
        HStack(spacing: 12) {
            // 木箱アイコン(担当済みは満載、未定は空箱)
            Image(systemName: item.isAssigned ? "shippingbox.fill" : "shippingbox")
                .font(.anchorBody(16))
                .foregroundStyle(item.isAssigned ? AnchorTheme.hullTan : AnchorTheme.accent)
                .frame(width: 26)

            Text(item.name)
                .font(.anchorBody(15))
                .foregroundStyle(AnchorTheme.textPrimary)

            Spacer()

            // 担当のピッカー(メニュー)
            Menu {
                Button { assign(.me) } label: { Label("あなた", systemImage: "person.fill") }
                ForEach(store.crew) { mate in
                    Button { assign(.crew(mate.id)) } label: { Text(mate.name) }
                }
                Button { assign(.unassigned) } label: { Label("未定にする", systemImage: "questionmark") }
                Divider()
                Button(role: .destructive) {
                    withAnimation { store.deleteHoldItem(in: plan, item: item) }
                } label: {
                    Label("船倉から降ろす", systemImage: "trash")
                }
            } label: {
                assigneeChip
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .background(AnchorTheme.surfaceRaised, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    @ViewBuilder
    private var assigneeChip: some View {
        switch item.assignee {
        case .unassigned:
            Text("担当を決める")
                .font(.anchorHeading(12))
                .foregroundStyle(AnchorTheme.seaDeep)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(AnchorTheme.accent, in: Capsule())
        case .me:
            chip(text: "あなた", color: AnchorTheme.tileIndigo, initial: "あ")
        case .crew(let id):
            if let mate = store.crew.first(where: { $0.id == id }) {
                chip(text: mate.name, color: mate.color, initial: mate.initial)
            } else {
                Text("担当を決める")
                    .font(.anchorHeading(12))
                    .foregroundStyle(AnchorTheme.seaDeep)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(AnchorTheme.accent, in: Capsule())
            }
        }
    }

    private func chip(text: String, color: Color, initial: String) -> some View {
        HStack(spacing: 6) {
            ZStack {
                Circle().fill(color)
                Text(initial).font(.anchorHeading(10)).foregroundStyle(AnchorTheme.textPrimary)
            }
            .frame(width: 22, height: 22)
            Text(text)
                .font(.anchorBody(13))
                .foregroundStyle(AnchorTheme.textPrimary)
        }
        .padding(.leading, 4)
        .padding(.trailing, 10)
        .padding(.vertical, 4)
        .background(AnchorTheme.background.opacity(0.5), in: Capsule())
    }

    private func assign(_ a: HoldAssignee) {
        withAnimation(.easeInOut(duration: 0.2)) {
            store.assignHold(in: plan, item: item, to: a)
        }
        Haptics.tap()
    }
}

// MARK: - 乗組員の追加/編集シート

private struct CrewEditSheet: View {
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focused: Bool

    let title: String
    @State private var name: String
    @State private var note: String
    var onDelete: (() -> Void)?
    let onSave: (String, String) -> Void
    @State private var showingDeleteConfirm = false

    init(
        title: String,
        initialName: String = "",
        initialNote: String = "",
        onDelete: (() -> Void)? = nil,
        onSave: @escaping (String, String) -> Void
    ) {
        self.title = title
        _name = State(initialValue: initialName)
        _note = State(initialValue: initialNote)
        self.onDelete = onDelete
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AnchorTheme.background.ignoresSafeArea()
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("名前")
                            .font(.anchorHeading(13))
                            .foregroundStyle(AnchorTheme.textSecondary)
                        TextField("例: ハルカ", text: $name)
                            .font(.anchorBody(16))
                            .foregroundStyle(AnchorTheme.textPrimary)
                            .focused($focused)
                            .padding(14)
                            .background(AnchorTheme.surface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    field(label: "メモ(任意)", placeholder: "例: 車を出してくれる", text: $note)

                    if onDelete != nil {
                        Button(role: .destructive) {
                            showingDeleteConfirm = true
                        } label: {
                            Text("乗組員を削除")
                                .font(.anchorHeading(15))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(AnchorTheme.surface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                        .padding(.top, 8)
                    }
                    Spacer()
                }
                .padding(20)
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }.foregroundStyle(AnchorTheme.textSecondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        onSave(name, note)
                        dismiss()
                    }
                    .fontWeight(.bold)
                    .foregroundStyle(name.trimmingCharacters(in: .whitespaces).isEmpty ? AnchorTheme.textSecondary : AnchorTheme.accent)
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .confirmationDialog("この乗組員を削除しますか?", isPresented: $showingDeleteConfirm, titleVisibility: .visible) {
                Button("削除", role: .destructive) { onDelete?(); dismiss() }
                Button("キャンセル", role: .cancel) {}
            }
        }
        .presentationDetents([.height(onDelete == nil ? 260 : 330)])
        .onAppear { focused = true }
    }

    private func field(label: String, placeholder: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.anchorHeading(13))
                .foregroundStyle(AnchorTheme.textSecondary)
            TextField(placeholder, text: text)
                .font(.anchorBody(16))
                .foregroundStyle(AnchorTheme.textPrimary)
                .padding(14)
                .background(AnchorTheme.surface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }
}

#Preview {
    ZStack {
        AnchorTheme.background.ignoresSafeArea()
        CrewView(store: AnchorStore(), social: SocialService(), share: VoyageShareService())
    }
    .preferredColorScheme(.dark)
}
