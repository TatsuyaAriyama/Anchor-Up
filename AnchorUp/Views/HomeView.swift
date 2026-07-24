import SwiftUI
import UniformTypeIdentifiers

struct HomeView: View {
    @StateObject private var store = AnchorStore()
    @StateObject private var notifications = NotificationManager()
    @State private var selectedTab: AppTab = .home
    @State private var showingSettings = false
    @State private var showingCustomize = false
    @State private var planEditTarget: PlanEditTarget?
    /// 長押しドラッグ中のセクション
    @State private var draggingSection: HomeSectionKind?

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
                        .font(.anchorHeading(22))
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
                // ロゴタイプはセリフ体で船名の趣に
                Text("Anchor Up")
                    .font(.anchorDisplay(20, weight: .bold))
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
                            .font(.anchorBody(18))
                            .foregroundStyle(AnchorTheme.textSecondary)
                    }
                    .buttonStyle(.plain)
                }

                Button {
                    Haptics.tap()
                    showingSettings = true
                } label: {
                    Image(systemName: "gearshape")
                        .font(.anchorBody(18))
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
                .font(.anchorHeading(13))
                .foregroundStyle(AnchorTheme.accent)

            Text(Date.now.formatted(Date.FormatStyle(locale: .init(identifier: "ja_JP")).month(.wide).day()))
                .font(.anchorHeading(30))
                .foregroundStyle(AnchorTheme.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - ホームタブの中身

    /// 表示中のセクションを行に組む。連続する「半分」タイルは2つで1行になる。
    private var bentoRows: [[HomeSectionConfig]] {
        var rows: [[HomeSectionConfig]] = []
        var pendingHalf: HomeSectionConfig?
        for config in store.homeSections where config.isVisible {
            switch config.size {
            case .full:
                if let half = pendingHalf {
                    rows.append([half])
                    pendingHalf = nil
                }
                rows.append([config])
            case .half:
                if let half = pendingHalf {
                    rows.append([half, config])
                    pendingHalf = nil
                } else {
                    pendingHalf = config
                }
            }
        }
        if let half = pendingHalf { rows.append([half]) }
        return rows
    }

    private var homeContent: some View {
        ScrollView {
            VStack(spacing: 18) {
                dateHeader
                    .padding(.bottom, 6)

                // レイアウト設定に従ったベントーグリッド(長押しドラッグで並び替え可)
                ForEach(bentoRows, id: \.self) { row in
                    if row.count == 2 {
                        HStack(alignment: .top, spacing: 14) {
                            draggableTile(row[0].kind) { compactView(row[0].kind) }
                            draggableTile(row[1].kind) { compactView(row[1].kind) }
                        }
                    } else if let config = row.first {
                        if config.size == .half {
                            HStack(alignment: .top, spacing: 14) {
                                draggableTile(config.kind) { compactView(config.kind) }
                                Color.clear.frame(maxWidth: .infinity)
                            }
                        } else {
                            draggableTile(config.kind) { sectionView(config.kind) }
                        }
                    }
                }

                // FABに隠れないよう余白を確保
                Color.clear.frame(height: 60)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .animation(.easeInOut(duration: 0.25), value: store.homeSections)
        }
        .scrollIndicators(.hidden)
        // タイルの外側でドロップした場合のリセット
        .onDrop(of: [.text], delegate: LayoutResetDropDelegate(dragging: $draggingSection))
    }

    /// タイルに長押しドラッグ(並び替え)を付与する
    @ViewBuilder
    private func draggableTile<V: View>(_ kind: HomeSectionKind, @ViewBuilder _ content: () -> V) -> some View {
        content()
            .opacity(draggingSection == kind ? 0.3 : 1)
            .scaleEffect(draggingSection == kind ? 0.97 : 1)
            .onDrag {
                draggingSection = kind
                Haptics.soft()
                return NSItemProvider(object: kind.rawValue as NSString)
            }
            .onDrop(
                of: [.text],
                delegate: SectionDropDelegate(target: kind, store: store, dragging: $draggingSection)
            )
    }

    /// 半分サイズのコンパクトタイル
    @ViewBuilder
    private func compactView(_ kind: HomeSectionKind) -> some View {
        switch kind {
        case .todayItems:
            TodayItemsCompactCard(store: store) {
                withAnimation { selectedTab = .packing }
            }
        case .pinnedKits:
            PinnedKitsCompactCard(store: store) {
                withAnimation { selectedTab = .packing }
            }
        case .nextVoyage:
            NextVoyageCompactCard(
                store: store,
                onTap: { if let plan = store.nextPlan { planEditTarget = .edit(plan) } },
                onCreate: { planEditTarget = .create }
            )
        case .crew:
            CrewCompactCard()
        case .portLog:
            PortLogCompactCard()
        }
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
                .font(.anchorBody(34))
                .foregroundStyle(AnchorTheme.textSecondary)
            Text("この区画は整備中です")
                .font(.anchorBody(14))
                .foregroundStyle(AnchorTheme.textSecondary)
            Spacer()
        }
    }
}

// MARK: - 並び替えのドロップ処理

/// タイルにドラッグが重なったら、その位置へ即座に差し替える
struct SectionDropDelegate: DropDelegate {
    let target: HomeSectionKind
    let store: AnchorStore
    @Binding var dragging: HomeSectionKind?

    func dropEntered(info: DropInfo) {
        guard let dragging, dragging != target else { return }
        MainActor.assumeIsolated {
            withAnimation(.easeInOut(duration: 0.22)) {
                store.moveSection(dragging, before: target)
            }
        }
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
    }

    func performDrop(info: DropInfo) -> Bool {
        MainActor.assumeIsolated {
            dragging = nil
            Haptics.success()
        }
        return true
    }
}

/// タイルの外側でドロップした場合に、ドラッグ状態を解除する
struct LayoutResetDropDelegate: DropDelegate {
    @Binding var dragging: HomeSectionKind?

    func performDrop(info: DropInfo) -> Bool {
        MainActor.assumeIsolated { dragging = nil }
        return true
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
