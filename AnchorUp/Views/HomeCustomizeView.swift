import SwiftUI

/// ホーム画面のカスタマイズ。セクションの表示/非表示と並び順を編集する。
struct HomeCustomizeView: View {
    @ObservedObject var store: AnchorStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                AnchorTheme.background.ignoresSafeArea()

                List {
                    Section {
                        ForEach(store.homeSections) { config in
                            HStack(spacing: 12) {
                                Image(systemName: config.kind.symbol)
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundStyle(config.isVisible ? AnchorTheme.hullTan : AnchorTheme.textSecondary)
                                    .frame(width: 26)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(config.kind.title)
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundStyle(AnchorTheme.textPrimary)
                                    Text(config.kind.detail)
                                        .font(.system(size: 12))
                                        .foregroundStyle(AnchorTheme.textSecondary)
                                }

                                Spacer()

                                Toggle("", isOn: Binding(
                                    get: { config.isVisible },
                                    set: { store.setSectionVisible(config.kind, $0); Haptics.tap() }
                                ))
                                .labelsHidden()
                                .tint(AnchorTheme.accent)
                            }
                            .opacity(config.isVisible ? 1 : 0.55)
                            .listRowBackground(AnchorTheme.surface)
                        }
                        .onMove { store.moveSections(fromOffsets: $0, toOffset: $1) }
                    } header: {
                        Text("表示するセクション")
                            .foregroundStyle(AnchorTheme.textSecondary)
                    } footer: {
                        Text("左上の「編集」を押すとドラッグで並び替えできます。スイッチで表示/非表示を切り替えます。日付は常に上部に表示されます。")
                            .foregroundStyle(AnchorTheme.textSecondary)
                    }

                    Section {
                        Button(role: .destructive) {
                            withAnimation { store.resetHomeLayout() }
                            Haptics.soft()
                        } label: {
                            Text("既定の並びに戻す")
                        }
                        .listRowBackground(AnchorTheme.surface)
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("ホームのカスタマイズ")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    EditButton()
                        .foregroundStyle(AnchorTheme.accent)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("完了") { dismiss() }
                        .fontWeight(.semibold)
                        .foregroundStyle(AnchorTheme.accent)
                }
            }
        }
    }
}

#Preview {
    HomeCustomizeView(store: AnchorStore())
        .preferredColorScheme(.dark)
}
