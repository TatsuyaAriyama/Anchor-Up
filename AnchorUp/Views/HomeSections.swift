import SwiftUI

// MARK: - ピン留めセット

struct PinnedKitsSection: View {
    @ObservedObject var store: AnchorStore
    var onOpen: () -> Void = {}

    var body: some View {
        let pinned = store.pinnedKits
        VStack(spacing: 10) {
            SectionHeader(title: "ピン留めセット")

            if pinned.isEmpty {
                Button(action: onOpen) {
                    HStack(spacing: 10) {
                        Image(systemName: "pin")
                            .foregroundStyle(AnchorTheme.textSecondary)
                        Text("持ち物タブでセットをピン留めすると、ここに並びます")
                            .font(.anchorBody(13))
                            .foregroundStyle(AnchorTheme.textSecondary)
                            .multilineTextAlignment(.leading)
                        Spacer()
                    }
                    .padding(16)
                    .background(AnchorTheme.surface, in: RoundedRectangle(cornerRadius: AnchorTheme.cornerMedium, style: .continuous))
                }
                .buttonStyle(.plain)
            } else {
                VStack(spacing: 10) {
                    ForEach(pinned) { kit in
                        Button(action: onOpen) {
                            PinnedKitRow(kit: kit)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}

private struct PinnedKitRow: View {
    let kit: PackingKit

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(kit.color.color.opacity(0.28))
                Image(systemName: kit.symbolName)
                    .font(.anchorBody(18))
                    .foregroundStyle(kit.color.color)
            }
            .frame(width: 44, height: 44)

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(kit.name)
                        .font(.anchorHeading(16))
                        .foregroundStyle(AnchorTheme.textPrimary)
                    Spacer()
                    Text(kit.items.isEmpty ? "―" : "\(kit.checkedCount) / \(kit.items.count)")
                        .font(.anchorBody(13))
                        .foregroundStyle(kit.isComplete ? AnchorTheme.accent : AnchorTheme.textSecondary)
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(AnchorTheme.moonGlow.opacity(0.12))
                        Capsule()
                            .fill(kit.color.color)
                            .frame(width: max(kit.items.isEmpty ? 0 : 5, geo.size.width * kit.progress))
                    }
                }
                .frame(height: 5)
            }

            Image(systemName: "chevron.right")
                .font(.anchorHeading(12))
                .foregroundStyle(AnchorTheme.textSecondary)
        }
        .padding(14)
        .background(AnchorTheme.surface, in: RoundedRectangle(cornerRadius: AnchorTheme.cornerMedium, style: .continuous))
    }
}

// MARK: - 持ち物リスト(全セットから未チェックを抜粋)

struct TodayItemsSection: View {
    @ObservedObject var store: AnchorStore
    var onOpen: () -> Void = {}

    private var preview: [(kit: PackingKit, item: KitItem)] {
        store.remainingPreview(limit: 3)
    }

    /// 空表示の内容(セット無し / セットはあるが空 / 全部準備OK で出し分ける)
    private var emptyState: (icon: String, message: String) {
        if store.kits.isEmpty {
            return ("bag.badge.plus", "持ち物セットを作ってみよう")
        }
        if store.totalItemCount == 0 {
            return ("plus.circle", "持ち物を追加しよう")
        }
        return ("checkmark.seal.fill", "持ち物はすべて準備OK")
    }

    var body: some View {
        VStack(spacing: 10) {
            HStack {
                SectionHeader(title: "持ち物リスト")
                Button(action: onOpen) {
                    Text("すべて見る")
                        .font(.anchorHeading(13))
                        .foregroundStyle(AnchorTheme.accent)
                }
                .buttonStyle(.plain)
            }

            if preview.isEmpty {
                Button(action: onOpen) {
                    HStack(spacing: 10) {
                        Image(systemName: emptyState.icon)
                            .foregroundStyle(AnchorTheme.accent)
                        Text(emptyState.message)
                            .font(.anchorBody(15))
                            .foregroundStyle(AnchorTheme.textPrimary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.anchorHeading(11))
                            .foregroundStyle(AnchorTheme.textSecondary)
                    }
                    .padding(16)
                    .background(AnchorTheme.surface, in: RoundedRectangle(cornerRadius: AnchorTheme.cornerMedium, style: .continuous))
                }
                .buttonStyle(.plain)
            } else {
                VStack(spacing: 1) {
                    ForEach(preview, id: \.item.id) { entry in
                        Button(action: onOpen) {
                            HStack(spacing: 12) {
                                Circle()
                                    .fill(entry.kit.color.color)
                                    .frame(width: 9, height: 9)

                                Text(entry.item.name)
                                    .font(.anchorBody(15))
                                    .foregroundStyle(AnchorTheme.textPrimary)

                                Spacer()

                                Text(entry.kit.name)
                                    .font(.anchorBody(12))
                                    .foregroundStyle(AnchorTheme.textSecondary)

                                Image(systemName: "chevron.right")
                                    .font(.anchorHeading(11))
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
                                .font(.anchorBody(11))
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
                            .font(.anchorBody(12))
                            .foregroundStyle(AnchorTheme.tileMustard)
                        Text("\(unassigned.map(\.name).joined(separator: "・"))の担当がまだ決まっていません")
                            .font(.anchorBody(12))
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
                            .font(.anchorBody(22))
                            .foregroundStyle(AnchorTheme.textSecondary)
                        Text("まだ記録がありません")
                            .font(.anchorBody(13))
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
                                        .font(.anchorBody(24))
                                        .foregroundStyle(AnchorTheme.moonGlow.opacity(0.85))
                                }
                                .frame(width: 132, height: 84)

                                VStack(alignment: .leading, spacing: 3) {
                                    Text(voyage.title)
                                        .font(.anchorHeading(13))
                                        .foregroundStyle(AnchorTheme.textPrimary)
                                        .lineLimit(1)
                                    Text(voyage.dateLabel)
                                        .font(.anchorBody(11))
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
