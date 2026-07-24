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
                                    .font(.anchorBody(15))
                                    .foregroundStyle(config.isVisible ? AnchorTheme.hullTan : AnchorTheme.textSecondary)
                                    .frame(width: 26)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(config.kind.title)
                                        .font(.anchorBody(16))
                                        .foregroundStyle(AnchorTheme.textPrimary)
                                    Text(config.kind.detail)
                                        .font(.anchorBody(12))
                                        .foregroundStyle(AnchorTheme.textSecondary)
                                }

                                Spacer()

                                // サイズ切替(全幅 ⇄ 半分)
                                if config.isVisible {
                                    Button {
                                        let next: HomeSectionSize = config.size == .full ? .half : .full
                                        store.setSectionSize(config.kind, next)
                                        Haptics.tap()
                                    } label: {
                                        HStack(spacing: 4) {
                                            Image(systemName: config.size.symbol)
                                                .font(.anchorBody(11))
                                            Text(config.size.label)
                                                .font(.anchorBody(11))
                                        }
                                        .foregroundStyle(AnchorTheme.textPrimary)
                                        .padding(.horizontal, 9)
                                        .padding(.vertical, 5)
                                        .background(AnchorTheme.surfaceRaised, in: Capsule())
                                    }
                                    .buttonStyle(.plain)
                                }

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
                        Text("左上の「編集」でドラッグ並び替え、スイッチで表示/非表示。「全幅/半分」でカードの大きさを選べます。半分どうしは横に2つ並び、自分だけの盤面を組めます。")
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
