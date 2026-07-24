import SwiftUI

/// ホーム画面のメインヒーローカード「次の予定」
struct HeroCard: View {
    let voyage: Voyage?
    var onAnchorUp: () -> Void = {}
    var onCreateVoyage: () -> Void = {}

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            HeroIllustrationView()

            LinearGradient(
                colors: [.clear, AnchorTheme.seaDeep.opacity(0.85)],
                startPoint: .center,
                endPoint: .bottom
            )

            if let voyage {
                voyageOverlay(voyage)
            } else {
                emptyOverlay
            }
        }
        .frame(height: 250)
        .clipShape(RoundedRectangle(cornerRadius: AnchorTheme.cornerLarge, style: .continuous))
    }

    // MARK: - 予定あり

    @ViewBuilder
    private func voyageOverlay(_ voyage: Voyage) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Spacer()

            Text(voyage.title)
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(AnchorTheme.textPrimary)

            Text(countdownText(for: voyage))
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(AnchorTheme.moonGlow.opacity(0.9))

            HStack(alignment: .center) {
                // 乗組員アバター
                HStack(spacing: -8) {
                    ForEach(voyage.crew) { member in
                        CrewAvatar(member: member, size: 30)
                            .overlay(Circle().stroke(AnchorTheme.seaDeep, lineWidth: 2))
                    }
                }

                Spacer()

                if voyage.isReadyToSail {
                    // 準備100%のときだけ出航ボタンが現れる
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
                } else {
                    // 持ち物準備の進捗リング
                    ZStack {
                        ProgressRing(progress: voyage.myProgress, lineWidth: 4.5)
                        Text("\(Int(voyage.myProgress * 100))%")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(AnchorTheme.textPrimary)
                    }
                    .frame(width: 46, height: 46)
                }
            }
        }
        .padding(18)
    }

    private func countdownText(for voyage: Voyage) -> String {
        let days = voyage.daysUntilDeparture
        return days == 0 ? "本日、出航" : "出航まであと\(days)日"
    }

    // MARK: - 空の状態

    private var emptyOverlay: some View {
        VStack(alignment: .leading, spacing: 12) {
            Spacer()
            Text("次の航海を計画しよう。")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(AnchorTheme.textPrimary)

            Button(action: onCreateVoyage) {
                Text("予定をつくる")
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
    HeroCard(voyage: SampleData.nextVoyage)
        .padding()
        .background(AnchorTheme.background)
}

#Preview("空の状態") {
    HeroCard(voyage: nil)
        .padding()
        .background(AnchorTheme.background)
}
