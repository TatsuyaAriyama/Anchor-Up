import SwiftUI

/// 「持ち物」タブ。用途別の持ち物セットを一覧し、日々チェックして使う。
struct KitsView: View {
    @ObservedObject var store: AnchorStore
    @State private var showingAddKit = false

    private let columns = [
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14),
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    // 今日の準備サマリー
                    if store.totalItemCount > 0 {
                        TodaySummaryCard(store: store)
                    }

                    HStack {
                        Text("持ち物セット")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundStyle(AnchorTheme.textPrimary)
                        Spacer()
                        Button {
                            Haptics.tap()
                            showingAddKit = true
                        } label: {
                            Label("追加", systemImage: "plus")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(AnchorTheme.accent)
                        }
                        .buttonStyle(.plain)
                    }

                    if store.kits.isEmpty {
                        emptyState
                    } else {
                        LazyVGrid(columns: columns, spacing: 14) {
                            ForEach(store.kits) { kit in
                                NavigationLink(value: kit.id) {
                                    KitCard(kit: kit)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 18)
                .padding(.bottom, 40)
            }
            .scrollIndicators(.hidden)
            .background(AnchorTheme.background)
            .navigationDestination(for: UUID.self) { kitID in
                KitDetailView(store: store, kitID: kitID)
            }
            .toolbar(.hidden, for: .navigationBar)
        }
        .tint(AnchorTheme.accent)
        .sheet(isPresented: $showingAddKit) {
            KitEditSheet(title: "セットを追加") { name, symbol, color in
                store.addKit(name: name, symbolName: symbol, color: color)
                Haptics.soft()
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "bag")
                .font(.system(size: 40))
                .foregroundStyle(AnchorTheme.textSecondary.opacity(0.7))
            Text("持ち物セットがまだありません。\n「仕事」「毎日」など用途ごとに作ってみよう。")
                .font(.system(size: 14))
                .foregroundStyle(AnchorTheme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 50)
    }
}

// MARK: - 今日の準備サマリー

private struct TodaySummaryCard: View {
    @ObservedObject var store: AnchorStore

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                ProgressRing(progress: store.overallProgress, lineWidth: 6)
                Text("\(Int(store.overallProgress * 100))%")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(AnchorTheme.textPrimary)
            }
            .frame(width: 58, height: 58)

            VStack(alignment: .leading, spacing: 4) {
                Text("今日の準備")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(AnchorTheme.textSecondary)
                Text("\(store.checkedItemCount) / \(store.totalItemCount) 個 準備OK")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(AnchorTheme.textPrimary)
            }
            Spacer()
        }
        .padding(16)
        .background(AnchorTheme.surface, in: RoundedRectangle(cornerRadius: AnchorTheme.cornerLarge, style: .continuous))
    }
}

// MARK: - セットカード

private struct KitCard: View {
    let kit: PackingKit

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(kit.color.color.opacity(0.28))
                    Image(systemName: kit.symbolName)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(kit.color.color)
                }
                .frame(width: 46, height: 46)

                Spacer()

                if kit.isComplete {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(AnchorTheme.accent)
                }
            }

            Text(kit.name)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(AnchorTheme.textPrimary)
                .lineLimit(1)

            Text(kit.items.isEmpty ? "持ち物なし" : "\(kit.checkedCount) / \(kit.items.count)")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(AnchorTheme.textSecondary)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(AnchorTheme.moonGlow.opacity(0.12))
                    Capsule()
                        .fill(kit.color.color)
                        .frame(width: max(kit.items.isEmpty ? 0 : 6, geo.size.width * kit.progress))
                }
            }
            .frame(height: 6)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AnchorTheme.surface, in: RoundedRectangle(cornerRadius: AnchorTheme.cornerLarge, style: .continuous))
    }
}

#Preview {
    KitsView(store: AnchorStore())
        .preferredColorScheme(.dark)
}
