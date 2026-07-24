import SwiftUI

/// ホーム画面のメインヒーローカード「次の予定」
struct HeroCard: View {
    let plan: Voyage?
    /// 紐付いた持ち物の準備進捗 (0.0 - 1.0)
    var progress: Double = 0
    /// 準備が完了しているか
    var isReady: Bool = false
    /// 紐付いた持ち物の (チェック済み, 総数)
    var packed: (checked: Int, total: Int) = (0, 0)

    var onTap: () -> Void = {}
    var onAnchorUp: () -> Void = {}
    var onCreate: () -> Void = {}

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            HeroIllustrationView()

            LinearGradient(
                colors: [.clear, AnchorTheme.seaDeep.opacity(0.9)],
                startPoint: .center,
                endPoint: .bottom
            )

            if let plan {
                planOverlay(plan)
            } else {
                emptyOverlay
            }
        }
        .frame(height: 250)
        .clipShape(RoundedRectangle(cornerRadius: AnchorTheme.cornerLarge, style: .continuous))
        .contentShape(Rectangle())
        // 予定あり: タップで編集 / 空: タップで作成
        .onTapGesture { plan != nil ? onTap() : onCreate() }
        // 予定がある時だけ、別の航海を計画する小さな導線をカード左上(夜空側)に置く
        .overlay(alignment: .topLeading) {
            if plan != nil {
                Button(action: onCreate) {
                    Image(systemName: "plus")
                        .font(.anchorHeading(14))
                        .foregroundStyle(AnchorTheme.moonGlow)
                        .frame(width: 32, height: 32)
                        .background(AnchorTheme.seaDeep.opacity(0.55), in: Circle())
                        .overlay(Circle().strokeBorder(AnchorTheme.moonGlow.opacity(0.25), lineWidth: 1))
                }
                .buttonStyle(.plain)
                .padding(12)
                .accessibilityLabel("別の航海を計画")
            }
        }
    }

    // MARK: - 予定あり

    @ViewBuilder
    private func planOverlay(_ plan: Voyage) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Spacer()

            Text(plan.countdownText)
                .font(.anchorHeading(13))
                .foregroundStyle(AnchorTheme.accent)

            Text(plan.title)
                .font(.anchorHeading(23))
                .foregroundStyle(AnchorTheme.textPrimary)
                .lineLimit(1)

            HStack(spacing: 10) {
                Label(plan.dateText, systemImage: "calendar")
                    .font(.anchorBody(12))
                    .foregroundStyle(AnchorTheme.moonGlow.opacity(0.85))
                if !plan.destination.isEmpty {
                    Label(plan.destination, systemImage: "mappin.and.ellipse")
                        .font(.anchorBody(12))
                        .foregroundStyle(AnchorTheme.moonGlow.opacity(0.85))
                        .lineLimit(1)
                }
            }

            HStack(alignment: .center) {
                packingSummary(plan)

                Spacer()

                if isReady {
                    Button(action: onAnchorUp) {
                        HStack(spacing: 6) {
                            AnchorLogo(size: 16, color: AnchorTheme.seaDeep)
                            Text("Anchor Up")
                                .font(.anchorHeading(15))
                        }
                        .foregroundStyle(AnchorTheme.seaDeep)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 9)
                        .background(AnchorTheme.moonGlow, in: Capsule())
                    }
                    .buttonStyle(.plain)
                } else if packed.total > 0 {
                    ZStack {
                        ProgressRing(progress: progress, lineWidth: 4.5)
                        Text("\(Int(progress * 100))%")
                            .font(.anchorHeading(12))
                            .foregroundStyle(AnchorTheme.textPrimary)
                    }
                    .frame(width: 46, height: 46)
                }
            }
            .padding(.top, 2)
        }
        .padding(18)
    }

    @ViewBuilder
    private func packingSummary(_ plan: Voyage) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "bag")
                .font(.anchorBody(12))
            if packed.total > 0 {
                Text("持ち物 \(packed.checked)/\(packed.total)")
                    .font(.anchorHeading(13))
            } else {
                Text("持ち物セット未設定")
                    .font(.anchorBody(13))
            }
        }
        .foregroundStyle(AnchorTheme.moonGlow.opacity(0.9))
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(AnchorTheme.seaDeep.opacity(0.5), in: Capsule())
    }

    // MARK: - 空の状態

    private var emptyOverlay: some View {
        VStack(alignment: .leading, spacing: 12) {
            Spacer()
            Text("次の航海を計画しよう。")
                .font(.anchorHeading(20))
                .foregroundStyle(AnchorTheme.textPrimary)

            Button(action: onCreate) {
                Label("予定をつくる", systemImage: "plus")
                    .font(.anchorHeading(14))
                    .foregroundStyle(AnchorTheme.seaDeep)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 9)
                    .background(AnchorTheme.moonGlow, in: Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview("予定あり") {
    HeroCard(
        plan: Voyage(title: "沖ノ島キャンプ", destination: "千葉・沖ノ島",
                     date: Calendar.current.date(byAdding: .day, value: 2, to: .now) ?? .now),
        progress: 0.375,
        packed: (3, 8)
    )
    .padding()
    .background(AnchorTheme.background)
}

#Preview("空の状態") {
    HeroCard(plan: nil)
        .padding()
        .background(AnchorTheme.background)
}
