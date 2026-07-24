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
        .onTapGesture { if plan != nil { onTap() } }
    }

    // MARK: - 予定あり

    @ViewBuilder
    private func planOverlay(_ plan: Voyage) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Spacer()

            Text(plan.countdownText)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(AnchorTheme.accent)

            Text(plan.title)
                .font(.system(size: 23, weight: .bold))
                .foregroundStyle(AnchorTheme.textPrimary)
                .lineLimit(1)

            HStack(spacing: 10) {
                Label(plan.dateText, systemImage: "calendar")
                    .font(.system(size: 12))
                    .foregroundStyle(AnchorTheme.moonGlow.opacity(0.85))
                if !plan.destination.isEmpty {
                    Label(plan.destination, systemImage: "mappin.and.ellipse")
                        .font(.system(size: 12))
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
                                .font(.system(size: 15, weight: .bold))
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
                            .font(.system(size: 12, weight: .bold))
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
                .font(.system(size: 12, weight: .medium))
            if packed.total > 0 {
                Text("持ち物 \(packed.checked)/\(packed.total)")
                    .font(.system(size: 13, weight: .semibold))
            } else {
                Text("持ち物セット未設定")
                    .font(.system(size: 13, weight: .medium))
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
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(AnchorTheme.textPrimary)

            Button(action: onCreate) {
                Label("予定をつくる", systemImage: "plus")
                    .font(.system(size: 14, weight: .semibold))
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
