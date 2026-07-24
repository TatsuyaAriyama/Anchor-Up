import SwiftUI
import UniformTypeIdentifiers

struct HomeView: View {
    @StateObject private var store = AnchorStore()
    @StateObject private var notifications = NotificationManager()
    @State private var selectedTab: AppTab = .home
    /// 舵の回転方向(+1: 順 / -1: 逆)。画面スライドの向きに使う
    @State private var navDirection: Double = 1
    @State private var planEditTarget: PlanEditTarget?
    /// 舵輪の使い方ヒント(初回のみ)
    @AppStorage("anchorup.helmHintShown") private var helmHintShown = false
    @State private var showHelmHint = false
    /// Anchor Up の出航演出
    @State private var celebrating = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// 長押しドラッグ中のセクション
    @State private var draggingSection: HomeSectionKind?

    var body: some View {
        ZStack(alignment: .bottom) {
            WallpaperView(wallpaper: store.wallpaper)
                .ignoresSafeArea()

            // タブごとの画面(舵輪の回転で切り替わる)。回した方向へスライド
            ZStack {
                switch selectedTab {
                case .home:
                    homeContent.transition(tabTransition)
                case .packing:
                    KitsView(store: store).transition(tabTransition)
                case .crew:
                    CrewView(store: store).transition(tabTransition)
                case .myPage:
                    MyPageView(store: store, notifications: notifications).transition(tabTransition)
                }
            }
            .animation(reduceMotion ? .easeInOut(duration: 0.2) : .spring(response: 0.38, dampingFraction: 0.86), value: selectedTab)

            // 舵輪の背後の暗がり(海面下)。触れないよう素通し
            LinearGradient(
                colors: [.clear, AnchorTheme.background.opacity(0.85)],
                startPoint: .top, endPoint: .bottom
            )
            .frame(height: 180)
            .allowsHitTesting(false)
            .ignoresSafeArea(edges: .bottom)

            // 半分海に沈んだ舵輪。回して画面を切り替える
            HelmControl(selection: $selectedTab, direction: $navDirection,
                        reduceMotion: reduceMotion, showHint: showHelmHint)
                .offset(y: 170)
        }
        .overlay {
            if celebrating { celebrationOverlay }
        }
        .overlay(alignment: .bottomTrailing) {
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
            // 初回のみ、舵輪の使い方ヒントを少し遅れて出す
            if !helmHintShown {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) { showHelmHint = true }
                }
            }
        }
        .onChange(of: selectedTab) { _, _ in
            dismissHelmHint()
        }
    }

    /// 舵の回転方向に応じたスライド遷移(順=右から、逆=左から)。視差減時はフェード
    private var tabTransition: AnyTransition {
        if reduceMotion { return .opacity }
        return .asymmetric(
            insertion: .move(edge: navDirection >= 0 ? .trailing : .leading)
                .combined(with: .opacity),
            removal: .move(edge: navDirection >= 0 ? .leading : .trailing)
                .combined(with: .opacity)
        )
    }

    private func dismissHelmHint() {
        guard showHelmHint else { return }
        helmHintShown = true
        withAnimation(.easeOut(duration: 0.3)) { showHelmHint = false }
    }

    // MARK: - Anchor Up の出航演出

    private var celebrationOverlay: some View {
        ZStack {
            AnchorTheme.seaDeep.opacity(0.5).ignoresSafeArea()
            VStack(spacing: 16) {
                AnchorLogo(size: 64, color: AnchorTheme.moonGlow)
                    .rotationEffect(.degrees(celebrating ? 0 : -20))
                Text("錨を上げた")
                    .font(.anchorHeading(24))
                    .foregroundStyle(AnchorTheme.moonGlow)
                Text("よい航海を。")
                    .font(.anchorBody(15))
                    .foregroundStyle(AnchorTheme.moonGlow.opacity(0.85))
            }
        }
        .transition(.opacity)
        .allowsHitTesting(false)
    }

    /// 「Anchor Up」で出航 → 完了して記録へ
    private func anchorUp(_ plan: Voyage) {
        Haptics.success()
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) { celebrating = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
            store.completePlan(plan)
            withAnimation(.easeOut(duration: 0.4)) { celebrating = false }
        }
    }

    // MARK: - 日付ヘッダー

    private var dateHeader: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("\(greeting) · \(Date.now.formatted(Date.FormatStyle(locale: .init(identifier: "ja_JP")).weekday(.wide)))")
                .font(.anchorHeading(13))
                .foregroundStyle(AnchorTheme.accent)

            Text(Date.now.formatted(Date.FormatStyle(locale: .init(identifier: "ja_JP")).month(.wide).day()))
                .font(.anchorHeading(30))
                .foregroundStyle(AnchorTheme.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// 時間帯に応じた挨拶
    private var greeting: String {
        switch Calendar.current.component(.hour, from: Date()) {
        case 5..<11: "おはよう"
        case 11..<17: "こんにちは"
        case 17..<22: "こんばんは"
        default: "航海日和"
        }
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

                // 舵輪とFABに隠れないよう余白を確保
                Color.clear.frame(height: 170)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .animation(.easeInOut(duration: 0.25), value: store.homeSections)
        }
        .scrollIndicators(.hidden)
        // タイルの外側でドロップした場合のリセット
        .onDrop(of: [.text], delegate: LayoutResetDropDelegate(dragging: $draggingSection))
    }

    /// タイルに長押しドラッグ(並び替え)を付与する。
    /// ドラッグ中は他タイルがリアルタイムに動いて位置を空けるため、
    /// 元タイルを減光し続けない(減光状態が残って暗いまま固まるのを防ぐ)。
    @ViewBuilder
    private func draggableTile<V: View>(_ kind: HomeSectionKind, @ViewBuilder _ content: () -> V) -> some View {
        content()
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
            CrewCompactCard(store: store) {
                withAnimation { selectedTab = .crew }
            }
        case .portLog:
            PortLogCompactCard(store: store)
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
                    if let plan { anchorUp(plan) }
                },
                onCreate: {
                    planEditTarget = .create
                }
            )
        case .crew:
            CrewOverviewSection(store: store) {
                withAnimation { selectedTab = .crew }
            }
        case .portLog:
            PortLogSection(store: store)
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
                store.moveSection(dragging, over: target)
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
