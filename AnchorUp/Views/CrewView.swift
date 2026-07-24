import SwiftUI

/// 乗組員タブ。一緒に出かける仲間をローカルに登録して管理する。
struct CrewView: View {
    @ObservedObject var store: AnchorStore
    @State private var showingAdd = false
    @State private var editing: Crewmate?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header

                if store.crew.isEmpty {
                    emptyState
                } else {
                    VStack(spacing: 10) {
                        ForEach(store.crew) { mate in
                            Button {
                                Haptics.tap()
                                editing = mate
                            } label: {
                                CrewRow(mate: mate)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 24)
            .padding(.bottom, 190) // 舵輪ぶんの余白
        }
        .scrollIndicators(.hidden)
        .overlay(alignment: .top) {
            addButton
        }
        .sheet(isPresented: $showingAdd) {
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

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 4) {
                Text("乗組員")
                    .font(.anchorHeading(26))
                    .foregroundStyle(AnchorTheme.textPrimary)
                Text("一緒に航海する仲間")
                    .font(.anchorBody(13))
                    .foregroundStyle(AnchorTheme.textSecondary)
            }
            Spacer()
        }
    }

    private var addButton: some View {
        HStack {
            Spacer()
            Button {
                Haptics.tap()
                showingAdd = true
            } label: {
                Label("追加", systemImage: "person.badge.plus")
                    .font(.anchorHeading(13))
                    .foregroundStyle(AnchorTheme.accent)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(AnchorTheme.background.opacity(0.6), in: Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(.trailing, 20)
        .padding(.top, 26)
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "flag.2.crossed")
                .font(.anchorBody(40))
                .foregroundStyle(AnchorTheme.textSecondary.opacity(0.7))
            Text("まだ乗組員がいません。\n一緒に出かける仲間を登録しよう。")
                .font(.anchorBody(14))
                .foregroundStyle(AnchorTheme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
}

private struct CrewRow: View {
    let mate: Crewmate

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle().fill(mate.color)
                Text(mate.initial)
                    .font(.anchorHeading(18))
                    .foregroundStyle(AnchorTheme.textPrimary)
            }
            .frame(width: 46, height: 46)

            VStack(alignment: .leading, spacing: 3) {
                Text(mate.name)
                    .font(.anchorHeading(16))
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
}

// MARK: - 追加/編集シート

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
        CrewView(store: AnchorStore())
    }
    .preferredColorScheme(.dark)
}
