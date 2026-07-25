import SwiftUI

/// 予定(航海)の作成・編集。plan / shared がどちらも nil なら新規作成。
/// 連携した友達を招待すると「共有航海」に昇格し、双方の航海図に並ぶ。
struct PlanEditView: View {
    @ObservedObject var store: AnchorStore
    @ObservedObject var social: SocialService
    @ObservedObject var share: VoyageShareService
    let plan: Voyage?
    let shared: SharedVoyage?

    @Environment(\.dismiss) private var dismiss
    @FocusState private var titleFocused: Bool

    @State private var title: String
    @State private var destination: String
    @State private var date: Date
    @State private var hasTime: Bool
    @State private var selectedKitIDs: Set<UUID>
    @State private var selectedCrewIDs: Set<UUID>
    @State private var selectedFriendUids: Set<String>
    @State private var showingDeleteConfirm = false

    init(
        store: AnchorStore,
        social: SocialService,
        share: VoyageShareService,
        plan: Voyage? = nil,
        shared: SharedVoyage? = nil,
        defaultDate: Date? = nil
    ) {
        self.store = store
        self.social = social
        self.share = share
        self.plan = plan
        self.shared = shared

        let fallbackDate = defaultDate ?? Calendar.current.date(byAdding: .day, value: 1, to: .now) ?? .now
        _title = State(initialValue: shared?.title ?? plan?.title ?? "")
        _destination = State(initialValue: shared?.destination ?? plan?.destination ?? "")
        _date = State(initialValue: shared?.date ?? plan?.date ?? fallbackDate)
        _hasTime = State(initialValue: shared?.hasTime ?? plan?.hasTime ?? false)
        _selectedKitIDs = State(initialValue: Set(plan?.linkedKitIDs ?? []))
        _selectedCrewIDs = State(initialValue: Set(plan?.memberIDs ?? []))
        // 共有航海なら自分以外の参加者を初期選択に
        let myUid = share.uid ?? ""
        _selectedFriendUids = State(initialValue: Set(shared?.memberUids.filter { $0 != myUid } ?? []))
    }

    private var isEditing: Bool { plan != nil || shared != nil }
    private var canSave: Bool { !title.trimmingCharacters(in: .whitespaces).isEmpty }
    /// 共有航海として保存されるか
    private var willBeShared: Bool { !selectedFriendUids.isEmpty }

    var body: some View {
        NavigationStack {
            ZStack {
                AnchorTheme.background.ignoresSafeArea()

                List {
                    basicSection
                    scheduleSection
                    shareSection
                    // 持ち物セット・ローカル名簿は自分の手元の予定にだけ紐づく
                    if !willBeShared {
                        kitsSection
                        crewSection
                    }
                    if isEditing { deleteSection }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
            }
            .navigationTitle(isEditing ? "予定を編集" : "予定をつくる")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }
                        .foregroundStyle(AnchorTheme.textSecondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存", action: save)
                        .fontWeight(.bold)
                        .foregroundStyle(canSave ? AnchorTheme.accent : AnchorTheme.textSecondary)
                        .disabled(!canSave)
                }
            }
            .confirmationDialog("この予定を削除しますか?", isPresented: $showingDeleteConfirm, titleVisibility: .visible) {
                Button("削除", role: .destructive) {
                    if let shared { share.delete(shared) }
                    if let plan { store.deletePlan(plan) }
                    dismiss()
                }
                Button("キャンセル", role: .cancel) {}
            }
        }
        .onAppear { if !isEditing { titleFocused = true } }
    }

    // MARK: - 仲間と共有

    private var shareSection: some View {
        Section {
            if social.friends.isEmpty {
                Text("「乗組員」タブで招待コードを交換すると、この航海を仲間と共有できます。")
                    .font(.anchorBody(13))
                    .foregroundStyle(AnchorTheme.textSecondary)
                    .listRowBackground(AnchorTheme.surface)
            } else {
                ForEach(social.friends) { friend in
                    Button {
                        toggleFriend(friend.uid)
                        Haptics.tap()
                    } label: {
                        HStack(spacing: 12) {
                            ZStack {
                                Circle().fill(friend.color)
                                Text(friend.initial)
                                    .font(.anchorHeading(16))
                                    .foregroundStyle(AnchorTheme.textPrimary)
                            }
                            .frame(width: 34, height: 34)
                            Text(friend.name)
                                .font(.anchorBody(16))
                                .foregroundStyle(AnchorTheme.textPrimary)
                            Spacer()
                            Image(systemName: selectedFriendUids.contains(friend.uid) ? "checkmark.circle.fill" : "circle")
                                .font(.anchorBody(20))
                                .foregroundStyle(selectedFriendUids.contains(friend.uid) ? AnchorTheme.accent : AnchorTheme.textSecondary.opacity(0.6))
                        }
                    }
                    .buttonStyle(.plain)
                    .listRowBackground(AnchorTheme.surface)
                }
            }
        } header: {
            Text("仲間と共有").foregroundStyle(AnchorTheme.textSecondary)
        } footer: {
            Text(willBeShared
                 ? "共有航海になります。相手の航海図にも表示され、船倉の分担を一緒に決められます。"
                 : "誰も選ばなければ、自分だけの予定として保存されます。")
                .foregroundStyle(willBeShared ? AnchorTheme.accent : AnchorTheme.textSecondary)
        }
    }

    private func toggleFriend(_ uid: String) {
        if selectedFriendUids.contains(uid) {
            selectedFriendUids.remove(uid)
        } else {
            selectedFriendUids.insert(uid)
        }
    }

    // MARK: - 基本情報

    private var basicSection: some View {
        Section {
            TextField("タイトル(例: 沖ノ島キャンプ)", text: $title)
                .font(.anchorBody(16))
                .foregroundStyle(AnchorTheme.textPrimary)
                .focused($titleFocused)
                .listRowBackground(AnchorTheme.surface)

            TextField("行き先(任意)", text: $destination)
                .font(.anchorBody(16))
                .foregroundStyle(AnchorTheme.textPrimary)
                .listRowBackground(AnchorTheme.surface)
        } header: {
            Text("基本情報").foregroundStyle(AnchorTheme.textSecondary)
        }
    }

    // MARK: - 日程

    private var scheduleSection: some View {
        Section {
            DatePicker(selection: $date, displayedComponents: .date) {
                Label("日付", systemImage: "calendar")
                    .foregroundStyle(AnchorTheme.textPrimary)
            }
            .tint(AnchorTheme.accent)
            .listRowBackground(AnchorTheme.surface)

            Toggle(isOn: $hasTime) {
                Label("時刻を指定", systemImage: "clock")
                    .foregroundStyle(AnchorTheme.textPrimary)
            }
            .tint(AnchorTheme.accent)
            .listRowBackground(AnchorTheme.surface)

            if hasTime {
                DatePicker(selection: $date, displayedComponents: .hourAndMinute) {
                    Label("時刻", systemImage: "clock.badge")
                        .foregroundStyle(AnchorTheme.textPrimary)
                }
                .tint(AnchorTheme.accent)
                .listRowBackground(AnchorTheme.surface)
            }
        } header: {
            Text("日程").foregroundStyle(AnchorTheme.textSecondary)
        } footer: {
            // 選んだ日付の残り(過去なら警告色)
            let v = Voyage(title: "", date: date)
            Text(v.isPast ? "この日付は過ぎています" : v.countdownText)
                .foregroundStyle(v.isPast ? AnchorTheme.tileTerracotta : AnchorTheme.textSecondary)
        }
    }

    // MARK: - 持っていくセット

    private var kitsSection: some View {
        Section {
            if store.kits.isEmpty {
                Text("持ち物タブでセットを作ると、ここで選べます。")
                    .font(.anchorBody(13))
                    .foregroundStyle(AnchorTheme.textSecondary)
                    .listRowBackground(AnchorTheme.surface)
            } else {
                ForEach(store.kits) { kit in
                    Button {
                        toggleKit(kit.id)
                        Haptics.tap()
                    } label: {
                        HStack(spacing: 12) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 9, style: .continuous)
                                    .fill(kit.color.color.opacity(0.28))
                                Image(systemName: kit.symbolName)
                                    .font(.anchorBody(15))
                                    .foregroundStyle(kit.color.color)
                            }
                            .frame(width: 36, height: 36)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(kit.name)
                                    .font(.anchorBody(16))
                                    .foregroundStyle(AnchorTheme.textPrimary)
                                Text("\(kit.items.count) 個の持ち物")
                                    .font(.anchorBody(12))
                                    .foregroundStyle(AnchorTheme.textSecondary)
                            }

                            Spacer()

                            Image(systemName: selectedKitIDs.contains(kit.id) ? "checkmark.circle.fill" : "circle")
                                .font(.anchorBody(20))
                                .foregroundStyle(selectedKitIDs.contains(kit.id) ? AnchorTheme.accent : AnchorTheme.textSecondary.opacity(0.6))
                        }
                    }
                    .buttonStyle(.plain)
                    .listRowBackground(AnchorTheme.surface)
                }
            }
        } header: {
            Text("持っていくセット").foregroundStyle(AnchorTheme.textSecondary)
        } footer: {
            Text("選んだセットの持ち物が、この予定の準備進捗になります。")
                .foregroundStyle(AnchorTheme.textSecondary)
        }
    }

    // MARK: - 乗組員を招待

    private var crewSection: some View {
        Section {
            if store.crew.isEmpty {
                Text("乗組員タブで仲間を登録すると、ここで招待できます。")
                    .font(.anchorBody(13))
                    .foregroundStyle(AnchorTheme.textSecondary)
                    .listRowBackground(AnchorTheme.surface)
            } else {
                ForEach(store.crew) { mate in
                    Button {
                        toggleCrew(mate.id)
                        Haptics.tap()
                    } label: {
                        HStack(spacing: 12) {
                            CrewmateAvatar(mate: mate, size: 34)
                            Text(mate.name)
                                .font(.anchorBody(16))
                                .foregroundStyle(AnchorTheme.textPrimary)
                            Spacer()
                            Image(systemName: selectedCrewIDs.contains(mate.id) ? "checkmark.circle.fill" : "circle")
                                .font(.anchorBody(20))
                                .foregroundStyle(selectedCrewIDs.contains(mate.id) ? AnchorTheme.accent : AnchorTheme.textSecondary.opacity(0.6))
                        }
                    }
                    .buttonStyle(.plain)
                    .listRowBackground(AnchorTheme.surface)
                }
            }
        } header: {
            Text("乗組員を招待").foregroundStyle(AnchorTheme.textSecondary)
        } footer: {
            Text("招待した乗組員は、航海図にそれぞれの色で表示されます。")
                .foregroundStyle(AnchorTheme.textSecondary)
        }
    }

    // MARK: - 削除

    private var deleteSection: some View {
        Section {
            Button(role: .destructive) {
                showingDeleteConfirm = true
            } label: {
                Text("この予定を削除")
            }
            .listRowBackground(AnchorTheme.surface)
        }
    }

    // MARK: - 操作

    private func toggleKit(_ id: UUID) {
        if selectedKitIDs.contains(id) {
            selectedKitIDs.remove(id)
        } else {
            selectedKitIDs.insert(id)
        }
    }

    private func toggleCrew(_ id: UUID) {
        if selectedCrewIDs.contains(id) {
            selectedCrewIDs.remove(id)
        } else {
            selectedCrewIDs.insert(id)
        }
    }

    private func save() {
        guard canSave else { return }
        if willBeShared {
            saveShared()
        } else {
            saveLocal()
        }
        Haptics.soft()
        dismiss()
    }

    /// 自分だけの予定として保存する
    private func saveLocal() {
        // 元の並び順を保ちつつ、選択されたものだけ残す
        let orderedKitIDs = store.kits.map(\.id).filter { selectedKitIDs.contains($0) }
        let orderedCrewIDs = store.crew.map(\.id).filter { selectedCrewIDs.contains($0) }
        if let plan {
            store.updatePlan(plan, title: title, destination: destination, date: date, hasTime: hasTime, kitIDs: orderedKitIDs, memberIDs: orderedCrewIDs)
        } else {
            store.addPlan(title: title, destination: destination, date: date, hasTime: hasTime, kitIDs: orderedKitIDs, memberIDs: orderedCrewIDs)
        }
        // 共有をやめた場合は、共有航海を取り下げる
        if let shared { share.delete(shared) }
    }

    /// 仲間と共有する航海として保存する
    private func saveShared() {
        guard let myUid = share.uid else { return }
        let memberUids = [myUid] + social.friends.map(\.uid).filter { selectedFriendUids.contains($0) }

        // 表示用の名前・配色スナップショット
        var names: [String: String] = [myUid: social.myName]
        var colors: [String: Int] = [myUid: social.myColorIndex]
        for friend in social.friends where selectedFriendUids.contains(friend.uid) {
            names[friend.uid] = friend.name
            colors[friend.uid] = friend.colorIndex
        }

        let voyage = SharedVoyage(
            id: shared?.id ?? UUID().uuidString,
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            destination: destination.trimmingCharacters(in: .whitespacesAndNewlines),
            date: date,
            hasTime: hasTime,
            ownerUid: shared?.ownerUid ?? myUid,
            memberUids: memberUids,
            memberNames: names,
            memberColors: colors,
            holdItems: shared?.holdItems ?? [],
            completedAt: shared?.completedAt
        )
        share.save(voyage)

        // ローカル予定から昇格した場合は、手元の重複を取り除く
        if let plan { store.deletePlan(plan) }
    }
}

#Preview {
    PlanEditView(store: AnchorStore(), social: SocialService(), share: VoyageShareService())
        .preferredColorScheme(.dark)
}
