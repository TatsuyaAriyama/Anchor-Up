import SwiftUI

struct HomeView: View {
    @StateObject private var store = AnchorStore()
    @State private var selectedTab: AppTab = .home

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            AnchorTheme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                header
                    .padding(.horizontal, 20)
                    .padding(.top, 8)

                SegmentTabBar(selection: $selectedTab)
                    .padding(.top, 14)

                Divider()
                    .overlay(AnchorTheme.moonGlow.opacity(0.08))

                switch selectedTab {
                case .home:
                    homeContent
                case .packing:
                    KitsView(store: store)
                default:
                    placeholderContent
                }
            }

            // ホームタブのみ: 新規予定作成のFAB(持ち物タブは自前のFABを持つ)
            if selectedTab == .home {
                Button {
                    // TODO: 新規予定作成フローへ
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
        }
    }

    // MARK: - ヘッダー

    private var header: some View {
        HStack {
            HStack(spacing: 8) {
                AnchorLogo(size: 22)
                Text("Anchor Up")
                    .font(.system(size: 19, weight: .bold))
                    .foregroundStyle(AnchorTheme.textPrimary)
            }

            Spacer()

            Button {
                // TODO: 設定画面へ
            } label: {
                Image(systemName: "gearshape")
                    .font(.system(size: 18))
                    .foregroundStyle(AnchorTheme.textSecondary)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - 日付ヘッダー

    private var dateHeader: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(Date.now.formatted(Date.FormatStyle(locale: .init(identifier: "ja_JP")).weekday(.wide)))
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(AnchorTheme.accent)

            Text(Date.now.formatted(Date.FormatStyle(locale: .init(identifier: "ja_JP")).month(.wide).day()))
                .font(.system(size: 30, weight: .bold))
                .foregroundStyle(AnchorTheme.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - ホームタブの中身

    private var homeContent: some View {
        ScrollView {
            VStack(spacing: 24) {
                dateHeader

                HeroCard(
                    voyage: store.voyage,
                    onAnchorUp: {
                        // TODO: 全乗組員への出航通知
                    },
                    onCreateVoyage: {
                        // TODO: 新規予定作成フローへ
                    }
                )

                TodayItemsSection(store: store) {
                    withAnimation { selectedTab = .packing }
                }

                CrewSection(crew: store.voyage.crew, sharedItems: store.voyage.sharedItems)

                PortLogSection(pastVoyages: SampleData.pastVoyages)

                // FABに隠れないよう余白を確保
                Color.clear.frame(height: 60)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
        }
        .scrollIndicators(.hidden)
    }

    // MARK: - 未実装タブ

    private var placeholderContent: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "helm")
                .font(.system(size: 34))
                .foregroundStyle(AnchorTheme.textSecondary)
            Text("この区画は整備中です")
                .font(.system(size: 14))
                .foregroundStyle(AnchorTheme.textSecondary)
            Spacer()
        }
    }
}

#Preview {
    HomeView()
}
