import SwiftUI

// MARK: - あなたの持ち場(未完了の持ち物の抜粋)

struct MyStationSection: View {
    let items: [PackingItem]
    var onOpenPackingList: () -> Void = {}

    /// 未完了・準備中のものだけを最大3件抜粋する
    private var pendingItems: [PackingItem] {
        Array(items.filter { $0.status != .done }.prefix(3))
    }

    var body: some View {
        VStack(spacing: 10) {
            SectionHeader(title: "あなたの持ち場")

            VStack(spacing: 1) {
                ForEach(pendingItems) { item in
                    Button(action: onOpenPackingList) {
                        HStack(spacing: 12) {
                            // 信号旗風のステータスドット
                            Circle()
                                .fill(item.status.flagColor)
                                .frame(width: 9, height: 9)

                            Text(item.name)
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(AnchorTheme.textPrimary)

                            Spacer()

                            Text(item.status.label)
                                .font(.system(size: 12))
                                .foregroundStyle(AnchorTheme.textSecondary)

                            Image(systemName: "chevron.right")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(AnchorTheme.textSecondary)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 13)
                        .background(AnchorTheme.surfaceRaised)
                    }
                    .buttonStyle(.plain)
                }
            }
            .background(AnchorTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: AnchorTheme.cornerMedium, style: .continuous))
        }
    }
}

// MARK: - 乗組員

struct CrewSection: View {
    let crew: [CrewMember]
    let sharedItems: [SharedItem]

    /// 担当未定の船倉シェアアイテム
    private var unassigned: [SharedItem] {
        sharedItems.filter { $0.assignee == nil }
    }

    var body: some View {
        VStack(spacing: 10) {
            SectionHeader(title: "乗組員")

            VStack(spacing: 14) {
                HStack(spacing: 18) {
                    ForEach(crew) { member in
                        VStack(spacing: 6) {
                            ZStack {
                                ProgressRing(progress: member.progress, lineWidth: 3)
                                    .frame(width: 46, height: 46)
                                CrewAvatar(member: member, size: 36)
                            }
                            Text(member.name)
                                .font(.system(size: 11))
                                .foregroundStyle(AnchorTheme.textSecondary)
                                .lineLimit(1)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }

                if !unassigned.isEmpty {
                    // 船倉シェアの担当が未定の場合のさりげない通知
                    HStack(spacing: 8) {
                        Image(systemName: "shippingbox")
                            .font(.system(size: 12))
                            .foregroundStyle(AnchorTheme.tileMustard)
                        Text("\(unassigned.map(\.name).joined(separator: "・"))の担当がまだ決まっていません")
                            .font(.system(size: 12))
                            .foregroundStyle(AnchorTheme.textSecondary)
                        Spacer()
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 9)
                    .background(
                        AnchorTheme.tileMustard.opacity(0.12),
                        in: RoundedRectangle(cornerRadius: 10, style: .continuous)
                    )
                }
            }
            .padding(16)
            .background(AnchorTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: AnchorTheme.cornerMedium, style: .continuous))
        }
    }
}

// MARK: - 寄港の記録(過去の予定)

struct PortLogSection: View {
    let pastVoyages: [PastVoyage]

    var body: some View {
        VStack(spacing: 10) {
            SectionHeader(title: "寄港の記録")

            if pastVoyages.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "water.waves")
                            .font(.system(size: 22))
                            .foregroundStyle(AnchorTheme.textSecondary)
                        Text("まだ記録がありません")
                            .font(.system(size: 13))
                            .foregroundStyle(AnchorTheme.textSecondary)
                    }
                    Spacer()
                }
                .padding(.vertical, 28)
                .background(AnchorTheme.surface)
                .clipShape(RoundedRectangle(cornerRadius: AnchorTheme.cornerMedium, style: .continuous))
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(pastVoyages) { voyage in
                            VStack(alignment: .leading, spacing: 0) {
                                ZStack {
                                    voyage.tint.opacity(0.35)
                                    Image(systemName: voyage.symbolName)
                                        .font(.system(size: 24))
                                        .foregroundStyle(AnchorTheme.moonGlow.opacity(0.85))
                                }
                                .frame(width: 132, height: 84)

                                VStack(alignment: .leading, spacing: 3) {
                                    Text(voyage.title)
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundStyle(AnchorTheme.textPrimary)
                                        .lineLimit(1)
                                    Text(voyage.dateLabel)
                                        .font(.system(size: 11))
                                        .foregroundStyle(AnchorTheme.textSecondary)
                                }
                                .padding(10)
                            }
                            .frame(width: 132)
                            .background(AnchorTheme.surface)
                            .clipShape(RoundedRectangle(cornerRadius: AnchorTheme.cornerMedium, style: .continuous))
                        }
                    }
                }
            }
        }
    }
}
