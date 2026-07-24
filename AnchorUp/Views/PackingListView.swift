import SwiftUI

/// 「持ち物」タブの本体。自分の持ち場と船倉シェアを切り替えて管理する。
struct PackingListView: View {
    @ObservedObject var store: AnchorStore

    enum Segment: String, CaseIterable {
        case mine = "自分の持ち場"
        case shared = "船倉シェア"
    }

    @State private var segment: Segment = .mine
    @State private var showingAddSheet = false

    var body: some View {
        VStack(spacing: 0) {
            SubSegmentControl(segment: $segment)
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 8)

            switch segment {
            case .mine:
                MyItemsList(store: store)
            case .shared:
                SharedItemsList(store: store)
            }
        }
        .overlay(alignment: .bottomTrailing) {
            Button {
                Haptics.tap()
                showingAddSheet = true
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(AnchorTheme.moonGlow)
                    .frame(width: 56, height: 56)
                    .background(AnchorTheme.accent, in: Circle())
                    .shadow(color: .black.opacity(0.3), radius: 8, y: 4)
            }
            .buttonStyle(.plain)
            .padding(.trailing, 20)
            .padding(.bottom, 24)
        }
        .sheet(isPresented: $showingAddSheet) {
            switch segment {
            case .mine:
                AddMyItemSheet { name, category in
                    store.addMyItem(name: name, category: category)
                    Haptics.soft()
                }
            case .shared:
                AddSharedItemSheet { name in
                    store.addSharedItem(name: name)
                    Haptics.soft()
                }
            }
        }
    }
}

// MARK: - サブセグメント(自分 / 船倉シェア)

private struct SubSegmentControl: View {
    @Binding var segment: PackingListView.Segment

    var body: some View {
        HStack(spacing: 4) {
            ForEach(PackingListView.Segment.allCases, id: \.self) { seg in
                Button {
                    withAnimation(.easeOut(duration: 0.2)) { segment = seg }
                } label: {
                    Text(seg.rawValue)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(segment == seg ? AnchorTheme.seaDeep : AnchorTheme.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 9)
                        .background {
                            if segment == seg {
                                Capsule().fill(AnchorTheme.hullTan)
                            }
                        }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(AnchorTheme.surface, in: Capsule())
    }
}

// MARK: - 自分の持ち物リスト(カテゴリ別)

private struct MyItemsList: View {
    @ObservedObject var store: AnchorStore

    /// 未完了を上、完了を下にしつつカテゴリで束ねる
    private var groupedCategories: [PackingCategory] {
        PackingCategory.allCases.filter { cat in
            store.voyage.myItems.contains { $0.category == cat }
        }
    }

    private func items(in category: PackingCategory) -> [PackingItem] {
        store.voyage.myItems
            .filter { $0.category == category }
            .sorted { ($0.status == .done ? 1 : 0) < ($1.status == .done ? 1 : 0) }
    }

    var body: some View {
        if store.voyage.myItems.isEmpty {
            EmptyPackingState(
                symbol: "duffle.bag",
                message: "持ち物はまだありません。\n右下の＋から追加しよう。"
            )
        } else {
            List {
                // 進捗サマリー
                Section {
                    ProgressSummary(voyage: store.voyage)
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                }

                ForEach(groupedCategories) { category in
                    Section {
                        ForEach(items(in: category)) { item in
                            PackingRow(item: item) {
                                withAnimation(.easeInOut(duration: 0.25)) {
                                    store.advanceStatus(item)
                                }
                                if item.status.next == .done { Haptics.success() } else { Haptics.tap() }
                            }
                            .listRowBackground(AnchorTheme.surface)
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    withAnimation { store.deleteMyItem(item) }
                                } label: {
                                    Label("削除", systemImage: "trash")
                                }
                            }
                        }
                    } header: {
                        CategoryHeader(category: category, count: items(in: category).count)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(AnchorTheme.background)
        }
    }
}

private struct ProgressSummary: View {
    let voyage: Voyage

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("準備の進み具合")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AnchorTheme.textSecondary)
                Spacer()
                Text("\(voyage.doneCount) / \(voyage.myItems.count) 完了")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(AnchorTheme.textPrimary)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(AnchorTheme.moonGlow.opacity(0.12))
                    Capsule()
                        .fill(voyage.isReadyToSail ? AnchorTheme.accent : AnchorTheme.hullTan)
                        .frame(width: max(6, geo.size.width * voyage.myProgress))
                        .animation(.easeInOut(duration: 0.3), value: voyage.myProgress)
                }
            }
            .frame(height: 8)

            if voyage.isReadyToSail {
                Label("出航準備が整いました", systemImage: "checkmark.seal.fill")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(AnchorTheme.accent)
            }
        }
        .padding(16)
        .background(AnchorTheme.surface, in: RoundedRectangle(cornerRadius: AnchorTheme.cornerMedium, style: .continuous))
    }
}

private struct CategoryHeader: View {
    let category: PackingCategory
    let count: Int

    var body: some View {
        HStack(spacing: 7) {
            Image(systemName: category.symbolName)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(category.tint)
            Text(category.rawValue)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(AnchorTheme.textPrimary)
            Text("\(count)")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(AnchorTheme.textSecondary)
        }
        .textCase(nil)
        .padding(.bottom, 2)
    }
}

private struct PackingRow: View {
    let item: PackingItem
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                StatusIndicator(status: item.status)

                Text(item.name)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(item.status == .done ? AnchorTheme.textSecondary : AnchorTheme.textPrimary)
                    .strikethrough(item.status == .done, color: AnchorTheme.textSecondary)

                Spacer()

                if item.status == .inProgress {
                    Text("準備中")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(AnchorTheme.tileMustard)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(AnchorTheme.tileMustard.opacity(0.15), in: Capsule())
                }
            }
            .padding(.vertical, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - 船倉シェア(共有アイテム)

private struct SharedItemsList: View {
    @ObservedObject var store: AnchorStore

    var body: some View {
        if store.voyage.sharedItems.isEmpty {
            EmptyPackingState(
                symbol: "shippingbox",
                message: "船倉シェアはまだありません。\n誰か一人が持てば足りる物を登録しよう。"
            )
        } else {
            List {
                Section {
                    Text("誰か一人が持てば足りる共有の持ち物です。担当を決めましょう。")
                        .font(.system(size: 12))
                        .foregroundStyle(AnchorTheme.textSecondary)
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                }

                Section {
                    ForEach(store.voyage.sharedItems) { item in
                        SharedRow(
                            item: item,
                            isMine: item.assignee?.id == store.me.id
                        ) {
                            withAnimation { store.toggleAssignSelf(item) }
                            Haptics.tap()
                        }
                        .listRowBackground(AnchorTheme.surface)
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                withAnimation { store.deleteSharedItem(item) }
                            } label: {
                                Label("削除", systemImage: "trash")
                            }
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(AnchorTheme.background)
        }
    }
}

private struct SharedRow: View {
    let item: SharedItem
    let isMine: Bool
    let onToggle: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "shippingbox")
                .font(.system(size: 15))
                .foregroundStyle(item.assignee == nil ? AnchorTheme.tileMustard : AnchorTheme.hullTan)
                .frame(width: 26)

            Text(item.name)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(AnchorTheme.textPrimary)

            Spacer()

            if let assignee = item.assignee {
                HStack(spacing: 7) {
                    CrewAvatar(member: assignee, size: 26)
                    Text(isMine ? "あなたが担当" : "\(assignee.name)が担当")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(AnchorTheme.textSecondary)
                }
                .onTapGesture(perform: onToggle)
            } else {
                Button(action: onToggle) {
                    Text("担当する")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(AnchorTheme.seaDeep)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .background(AnchorTheme.hullTan, in: Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - 空状態

private struct EmptyPackingState: View {
    let symbol: String
    let message: String

    var body: some View {
        VStack(spacing: 14) {
            Spacer()
            Image(systemName: symbol)
                .font(.system(size: 40))
                .foregroundStyle(AnchorTheme.textSecondary.opacity(0.7))
            Text(message)
                .font(.system(size: 14))
                .foregroundStyle(AnchorTheme.textSecondary)
                .multilineTextAlignment(.center)
            Spacer()
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 40)
    }
}

// MARK: - 追加シート

private struct AddMyItemSheet: View {
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focused: Bool
    @State private var name = ""
    @State private var category: PackingCategory = .gear

    let onAdd: (String, PackingCategory) -> Void

    var body: some View {
        NavigationStack {
            ZStack {
                AnchorTheme.background.ignoresSafeArea()

                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("持ち物の名前")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(AnchorTheme.textSecondary)
                        TextField("例: モバイルバッテリー", text: $name)
                            .font(.system(size: 17))
                            .foregroundStyle(AnchorTheme.textPrimary)
                            .focused($focused)
                            .submitLabel(.done)
                            .onSubmit(add)
                            .padding(14)
                            .background(AnchorTheme.surface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Text("カテゴリ")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(AnchorTheme.textSecondary)
                        CategoryPicker(selection: $category)
                    }

                    Spacer()
                }
                .padding(20)
            }
            .navigationTitle("持ち物を追加")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }
                        .foregroundStyle(AnchorTheme.textSecondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("追加", action: add)
                        .fontWeight(.bold)
                        .foregroundStyle(name.isEmpty ? AnchorTheme.textSecondary : AnchorTheme.accent)
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
        .presentationDetents([.medium])
        .onAppear { focused = true }
    }

    private func add() {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        onAdd(trimmed, category)
        dismiss()
    }
}

private struct CategoryPicker: View {
    @Binding var selection: PackingCategory

    let columns = [GridItem(.adaptive(minimum: 96), spacing: 8)]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(PackingCategory.allCases) { cat in
                Button {
                    selection = cat
                    Haptics.tap()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: cat.symbolName)
                            .font(.system(size: 12, weight: .semibold))
                        Text(cat.rawValue)
                            .font(.system(size: 13, weight: .medium))
                    }
                    .foregroundStyle(selection == cat ? AnchorTheme.seaDeep : AnchorTheme.textPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(selection == cat ? cat.tint : AnchorTheme.surface)
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }
}

private struct AddSharedItemSheet: View {
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focused: Bool
    @State private var name = ""

    let onAdd: (String) -> Void

    var body: some View {
        NavigationStack {
            ZStack {
                AnchorTheme.background.ignoresSafeArea()

                VStack(alignment: .leading, spacing: 8) {
                    Text("船倉シェアの名前")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(AnchorTheme.textSecondary)
                    TextField("例: テント", text: $name)
                        .font(.system(size: 17))
                        .foregroundStyle(AnchorTheme.textPrimary)
                        .focused($focused)
                        .submitLabel(.done)
                        .onSubmit(add)
                        .padding(14)
                        .background(AnchorTheme.surface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    Spacer()
                }
                .padding(20)
            }
            .navigationTitle("船倉シェアを追加")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }
                        .foregroundStyle(AnchorTheme.textSecondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("追加", action: add)
                        .fontWeight(.bold)
                        .foregroundStyle(name.isEmpty ? AnchorTheme.textSecondary : AnchorTheme.accent)
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
        .presentationDetents([.height(200)])
        .onAppear { focused = true }
    }

    private func add() {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        onAdd(trimmed)
        dismiss()
    }
}

#Preview {
    PackingListView(store: AnchorStore())
        .background(AnchorTheme.background)
        .preferredColorScheme(.dark)
}
