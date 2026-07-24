import SwiftUI

struct HomeView: View {
    @StateObject private var store = AnchorStore()
    @StateObject private var notifications = NotificationManager()
    @State private var selectedTab: AppTab = .home
    @State private var showingSettings = false
    @State private var showingCustomize = false
    @State private var planEditTarget: PlanEditTarget?

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
                    Haptics.tap()
                    planEditTarget = .create
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
        .sheet(isPresented: $showingSettings) {
            SettingsView(store: store, notifications: notifications)
        }
        .sheet(isPresented: $showingCustomize) {
            HomeCustomizeView(store: store)
        }
        .sheet(item: $planEditTarget) { target in
            switch target {
            case .create:
                PlanEditView(store: store, plan: nil)
            case .edit(let plan):
                PlanEditView(store: store, plan: plan)
            }
        }
        .onAppear {
            notifications.refreshAuthStatus()
            notifications.rescheduleIfEnabled(itemCount: store.totalItemCount)
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

            HStack(spacing: 18) {
                // ホームタブでのみカスタマイズ導線を出す
                if selectedTab == .home {
                    Button {
                        Haptics.tap()
                        showingCustomize = true
                    } label: {
                        Image(systemName: "slider.horizontal.3")
                            .font(.system(size: 18))
                            .foregroundStyle(AnchorTheme.textSecondary)
                    }
                    .buttonStyle(.plain)
                }

                Button {
                    Haptics.tap()
                    showingSettings = true
                } label: {
                    Image(systemName: "gearshape")
                        .font(.system(size: 18))
                        .foregroundStyle(AnchorTheme.textSecondary)
                }
                .buttonStyle(.plain)
            }
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

                // レイアウト設定に従って、表示中のセクションを順に並べる
                ForEach(store.homeSections) { config in
                    if config.isVisible {
                        sectionView(config.kind)
                    }
                }

                // FABに隠れないよう余白を確保
                Color.clear.frame(height: 60)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
        }
        .scrollIndicators(.hidden)
    }

    @ViewBuilder
    private func sectionView(_ kind: HomeSectionKind) -> some View {
        switch kind {
        case .todayItems:
            TodayItemsSection(store: store) {
                withAnimation { selectedTab = .packing }
            }
        case .pinnedKits:
            PinnedKitsSection(store: store) {
                withAnimation { selectedTab = .packing }
            }
        case .nextVoyage:
            let plan = store.nextPlan
            HeroCard(
                plan: plan,
                progress: plan.map { store.planProgress($0) } ?? 0,
                isReady: plan.map { store.planReady($0) } ?? false,
                packed: plan.map { store.planItemCounts($0) } ?? (0, 0),
                onTap: {
                    if let plan { planEditTarget = .edit(plan) }
                },
                onAnchorUp: {
                    Haptics.success()
                },
                onCreate: {
                    planEditTarget = .create
                }
            )
        case .crew:
            CrewSection(crew: SampleData.crew, sharedItems: SampleData.sharedItems)
        case .portLog:
            PortLogSection(pastVoyages: SampleData.pastVoyages)
        }
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

/// 予定シートの表示対象(新規 or 既存の編集)
enum PlanEditTarget: Identifiable {
    case create
    case edit(Voyage)

    var id: String {
        switch self {
        case .create: "create"
        case .edit(let plan): plan.id.uuidString
        }
    }
}

#Preview {
    HomeView()
}
