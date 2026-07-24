import SwiftUI

/// 持ち物セットの詳細。日々の準備でチェックし、翌日はリセットして再利用する。
struct KitDetailView: View {
    @ObservedObject var store: AnchorStore
    let kitID: UUID

    @Environment(\.dismiss) private var dismiss
    @State private var newItemName = ""
    @FocusState private var addFieldFocused: Bool
    @State private var showingEdit = false
    @State private var showingDeleteConfirm = false

    private var kit: PackingKit? { store.kit(withID: kitID) }

    var body: some View {
        Group {
            if let kit {
                content(kit)
            } else {
                Color.clear.onAppear { dismiss() }
            }
        }
        .background(AnchorTheme.background)
    }

    @ViewBuilder
    private func content(_ kit: PackingKit) -> some View {
        List {
            // ヘッダー(アイコン・進捗・リセット)
            Section {
                KitDetailHeader(kit: kit) {
                    withAnimation { store.resetChecks(in: kit) }
                    Haptics.soft()
                }
                .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 12, trailing: 16))
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }

            // 持ち物
            Section {
                ForEach(kit.items) { item in
                    KitItemRow(item: item) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            store.toggleItem(in: kit, item: item)
                        }
                        if !item.isChecked { Haptics.success() } else { Haptics.tap() }
                    }
                    .listRowBackground(AnchorTheme.surface)
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            withAnimation { store.deleteItem(in: kit, item: item) }
                        } label: {
                            Label("削除", systemImage: "trash")
                        }
                    }
                }

                // インライン追加
                HStack(spacing: 12) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(AnchorTheme.accent)
                    TextField("持ち物を追加", text: $newItemName)
                        .font(.system(size: 16))
                        .foregroundStyle(AnchorTheme.textPrimary)
                        .focused($addFieldFocused)
                        .submitLabel(.done)
                        .onSubmit(addItem)
                }
                .listRowBackground(AnchorTheme.surface)
            } header: {
                Text(kit.items.isEmpty ? "" : "持ち物")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(AnchorTheme.textSecondary)
                    .textCase(nil)
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(AnchorTheme.background)
        .navigationTitle(kit.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        showingEdit = true
                    } label: {
                        Label("セットを編集", systemImage: "pencil")
                    }
                    Button {
                        withAnimation { store.resetChecks(in: kit) }
                        Haptics.soft()
                    } label: {
                        Label("チェックを外す", systemImage: "arrow.counterclockwise")
                    }
                    Divider()
                    Button(role: .destructive) {
                        showingDeleteConfirm = true
                    } label: {
                        Label("セットを削除", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundStyle(AnchorTheme.textPrimary)
                }
            }
        }
        .sheet(isPresented: $showingEdit) {
            KitEditSheet(
                title: "セットを編集",
                initialName: kit.name,
                initialSymbol: kit.symbolName,
                initialColor: kit.color
            ) { name, symbol, color in
                store.updateKit(kit, name: name, symbolName: symbol, color: color)
            }
        }
        .confirmationDialog("このセットを削除しますか?", isPresented: $showingDeleteConfirm, titleVisibility: .visible) {
            Button("削除", role: .destructive) {
                store.deleteKit(kit)
                dismiss()
            }
            Button("キャンセル", role: .cancel) {}
        }
    }

    private func addItem() {
        guard let kit else { return }
        let trimmed = newItemName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        store.addItem(to: kit, name: trimmed)
        newItemName = ""
        Haptics.tap()
        addFieldFocused = true // 連続入力しやすいようフォーカス維持
    }
}

// MARK: - ヘッダー

private struct KitDetailHeader: View {
    let kit: PackingKit
    let onReset: () -> Void

    var body: some View {
        VStack(spacing: 14) {
            HStack(spacing: 16) {
                ZStack {
                    ProgressRing(progress: kit.progress, lineWidth: 6, tint: kit.color.color)
                    Image(systemName: kit.symbolName)
                        .font(.system(size: 22, weight: .medium))
                        .foregroundStyle(kit.color.color)
                }
                .frame(width: 64, height: 64)

                VStack(alignment: .leading, spacing: 4) {
                    Text(kit.isComplete ? "準備OK!" : "準備中")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(kit.isComplete ? AnchorTheme.accent : AnchorTheme.textSecondary)
                    Text(kit.items.isEmpty ? "持ち物を追加しよう" : "\(kit.checkedCount) / \(kit.items.count) 個 準備OK")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(AnchorTheme.textPrimary)
                }
                Spacer()
            }

            if kit.checkedCount > 0 {
                Button(action: onReset) {
                    Label("チェックをすべて外す", systemImage: "arrow.counterclockwise")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(AnchorTheme.textPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 11)
                        .background(AnchorTheme.surfaceRaised, in: Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .background(AnchorTheme.surface, in: RoundedRectangle(cornerRadius: AnchorTheme.cornerLarge, style: .continuous))
    }
}

// MARK: - 持ち物の行(チェックボックス)

private struct KitItemRow: View {
    let item: KitItem
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .strokeBorder(item.isChecked ? AnchorTheme.seaShallow : AnchorTheme.textSecondary.opacity(0.6), lineWidth: 2)
                        .frame(width: 26, height: 26)
                    if item.isChecked {
                        Circle().fill(AnchorTheme.seaShallow).frame(width: 26, height: 26)
                        Image(systemName: "checkmark")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(AnchorTheme.moonGlow)
                    }
                }
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: item.isChecked)

                Text(item.name)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(item.isChecked ? AnchorTheme.textSecondary : AnchorTheme.textPrimary)
                    .strikethrough(item.isChecked, color: AnchorTheme.textSecondary)

                Spacer()
            }
            .padding(.vertical, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - セット追加/編集シート

struct KitEditSheet: View {
    @Environment(\.dismiss) private var dismiss
    @FocusState private var nameFocused: Bool

    let title: String
    @State private var name: String
    @State private var symbol: String
    @State private var color: KitColor
    let onSave: (String, String, KitColor) -> Void

    init(
        title: String,
        initialName: String = "",
        initialSymbol: String = "bag",
        initialColor: KitColor = .tan,
        onSave: @escaping (String, String, KitColor) -> Void
    ) {
        self.title = title
        _name = State(initialValue: initialName)
        _symbol = State(initialValue: initialSymbol)
        _color = State(initialValue: initialColor)
        self.onSave = onSave
    }

    private let symbolColumns = [GridItem(.adaptive(minimum: 52), spacing: 10)]

    var body: some View {
        NavigationStack {
            ZStack {
                AnchorTheme.background.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // プレビュー
                        HStack(spacing: 14) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(color.color.opacity(0.28))
                                Image(systemName: symbol)
                                    .font(.system(size: 24, weight: .medium))
                                    .foregroundStyle(color.color)
                            }
                            .frame(width: 56, height: 56)
                            Text(name.isEmpty ? "セット名" : name)
                                .font(.system(size: 18, weight: .bold))
                                .foregroundStyle(name.isEmpty ? AnchorTheme.textSecondary : AnchorTheme.textPrimary)
                            Spacer()
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("名前")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(AnchorTheme.textSecondary)
                            TextField("例: 仕事", text: $name)
                                .font(.system(size: 17))
                                .foregroundStyle(AnchorTheme.textPrimary)
                                .focused($nameFocused)
                                .padding(14)
                                .background(AnchorTheme.surface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }

                        VStack(alignment: .leading, spacing: 10) {
                            Text("色")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(AnchorTheme.textSecondary)
                            HStack(spacing: 12) {
                                ForEach(KitColor.allCases) { c in
                                    Circle()
                                        .fill(c.color)
                                        .frame(width: 34, height: 34)
                                        .overlay {
                                            if c == color {
                                                Circle().strokeBorder(AnchorTheme.moonGlow, lineWidth: 2.5)
                                                    .padding(-3)
                                            }
                                        }
                                        .onTapGesture {
                                            color = c
                                            Haptics.tap()
                                        }
                                }
                            }
                        }

                        VStack(alignment: .leading, spacing: 10) {
                            Text("アイコン")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(AnchorTheme.textSecondary)
                            LazyVGrid(columns: symbolColumns, spacing: 10) {
                                ForEach(KitSymbols.all, id: \.self) { s in
                                    Image(systemName: s)
                                        .font(.system(size: 20))
                                        .foregroundStyle(symbol == s ? AnchorTheme.seaDeep : AnchorTheme.textPrimary)
                                        .frame(width: 52, height: 52)
                                        .background {
                                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                .fill(symbol == s ? color.color : AnchorTheme.surface)
                                        }
                                        .onTapGesture {
                                            symbol = s
                                            Haptics.tap()
                                        }
                                }
                            }
                        }

                        Spacer(minLength: 20)
                    }
                    .padding(20)
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }
                        .foregroundStyle(AnchorTheme.textSecondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        onSave(name, symbol, color)
                        dismiss()
                    }
                    .fontWeight(.bold)
                    .foregroundStyle(name.trimmingCharacters(in: .whitespaces).isEmpty ? AnchorTheme.textSecondary : AnchorTheme.accent)
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
        .onAppear { if name.isEmpty { nameFocused = true } }
    }
}
