import SwiftUI

/// 半分幅タイルの共通枠。正方形に近い比率で、タップ可能。
private struct CompactTile<Content: View>: View {
    let action: () -> Void
    @ViewBuilder let content: Content

    var body: some View {
        Button(action: action) {
            content
                .frame(maxWidth: .infinity, alignment: .leading)
                .frame(height: 150)
                .background(AnchorTheme.surface, in: RoundedRectangle(cornerRadius: AnchorTheme.cornerLarge, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

private struct TileTitle: View {
    let symbol: String
    let title: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: symbol)
                .font(.anchorBody(12))
                .foregroundStyle(AnchorTheme.hullTan)
            Text(title)
                .font(.anchorHeading(12))
                .foregroundStyle(AnchorTheme.textSecondary)
            Spacer(minLength: 0)
        }
    }
}

// MARK: - 今日の持ち物(コンパクト)

struct TodayItemsCompactCard: View {
    @ObservedObject var store: AnchorStore
    var onOpen: () -> Void = {}

    private var remaining: Int { store.totalItemCount - store.checkedItemCount }

    var body: some View {
        CompactTile(action: onOpen) {
            VStack(alignment: .leading, spacing: 6) {
                TileTitle(symbol: "checklist", title: "今日の持ち物")
                Spacer()
                if store.totalItemCount == 0 {
                    Text("セットを\n作ってみよう")
                        .font(.anchorBody(14))
                        .foregroundStyle(AnchorTheme.textPrimary)
                } else if remaining == 0 {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.anchorBody(24))
                        .foregroundStyle(AnchorTheme.accent)
                    Text("準備OK")
                        .font(.anchorHeading(16))
                        .foregroundStyle(AnchorTheme.textPrimary)
                } else {
                    Text("\(remaining)")
                        .font(.anchorDisplay(34, weight: .bold))
                        .foregroundStyle(AnchorTheme.textPrimary)
                    Text("個 のこり")
                        .font(.anchorBody(12))
                        .foregroundStyle(AnchorTheme.textSecondary)
                }
            }
            .padding(14)
            .overlay(alignment: .topTrailing) {
                if store.totalItemCount > 0 {
                    ZStack {
                        ProgressRing(progress: store.overallProgress, lineWidth: 4)
                        Text("\(Int(store.overallProgress * 100))%")
                            .font(.anchorDisplay(10, weight: .semibold))
                            .foregroundStyle(AnchorTheme.textSecondary)
                    }
                    .frame(width: 40, height: 40)
                    .padding(12)
                }
            }
        }
    }
}

// MARK: - 次の予定(コンパクト)

struct NextVoyageCompactCard: View {
    @ObservedObject var store: AnchorStore
    var onTap: () -> Void = {}
    var onCreate: () -> Void = {}

    var body: some View {
        let plan = store.nextPlan
        CompactTile(action: { plan == nil ? onCreate() : onTap() }) {
            ZStack(alignment: .bottomLeading) {
                // ミニチュアの海(イラストのトーンを継承)
                LinearGradient(
                    colors: [AnchorTheme.seaDeep, AnchorTheme.seaShallow],
                    startPoint: .top, endPoint: .bottom
                )

                Circle()
                    .fill(AnchorTheme.moonGlow)
                    .frame(width: 22, height: 22)
                    .padding(.top, 16)
                    .padding(.trailing, 18)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)

                VStack(alignment: .leading, spacing: 4) {
                    if let plan {
                        Text(plan.countdownText)
                            .font(.anchorHeading(11))
                            .foregroundStyle(AnchorTheme.accent)
                        Text(plan.title)
                            .font(.anchorHeading(15))
                            .foregroundStyle(AnchorTheme.textPrimary)
                            .lineLimit(1)
                        Text(plan.dateText)
                            .font(.anchorBody(11))
                            .foregroundStyle(AnchorTheme.moonGlow.opacity(0.8))
                    } else {
                        Text("次の航海を\n計画しよう。")
                            .font(.anchorHeading(14))
                            .foregroundStyle(AnchorTheme.textPrimary)
                        Label("予定をつくる", systemImage: "plus")
                            .font(.anchorBody(11))
                            .foregroundStyle(AnchorTheme.seaDeep)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(AnchorTheme.moonGlow, in: Capsule())
                    }
                }
                .padding(14)
            }
        }
    }
}

// MARK: - ピン留めセット(コンパクト)

struct PinnedKitsCompactCard: View {
    @ObservedObject var store: AnchorStore
    var onOpen: () -> Void = {}

    var body: some View {
        CompactTile(action: onOpen) {
            VStack(alignment: .leading, spacing: 8) {
                TileTitle(symbol: "pin", title: "ピン留め")
                Spacer(minLength: 0)
                if store.pinnedKits.isEmpty {
                    Text("セットを\nピン留めしよう")
                        .font(.anchorBody(13))
                        .foregroundStyle(AnchorTheme.textSecondary)
                } else {
                    ForEach(store.pinnedKits.prefix(2)) { kit in
                        HStack(spacing: 8) {
                            Image(systemName: kit.symbolName)
                                .font(.anchorBody(12))
                                .foregroundStyle(kit.color.color)
                                .frame(width: 18)
                            Text(kit.name)
                                .font(.anchorBody(13))
                                .foregroundStyle(AnchorTheme.textPrimary)
                                .lineLimit(1)
                            Spacer(minLength: 0)
                            Text("\(kit.checkedCount)/\(kit.items.count)")
                                .font(.anchorDisplay(11, weight: .semibold))
                                .foregroundStyle(kit.isComplete ? AnchorTheme.accent : AnchorTheme.textSecondary)
                        }
                    }
                }
            }
            .padding(14)
        }
    }
}

// MARK: - 乗組員(コンパクト)

struct CrewCompactCard: View {
    var onOpen: () -> Void = {}

    var body: some View {
        CompactTile(action: onOpen) {
            VStack(alignment: .leading, spacing: 8) {
                TileTitle(symbol: "flag.2.crossed", title: "乗組員")
                Spacer(minLength: 0)
                HStack(spacing: -8) {
                    ForEach(SampleData.crew) { member in
                        CrewAvatar(member: member, size: 32)
                            .overlay(Circle().stroke(AnchorTheme.surface, lineWidth: 2))
                    }
                }
                Text("\(SampleData.crew.count)人が乗船中")
                    .font(.anchorBody(11))
                    .foregroundStyle(AnchorTheme.textSecondary)
            }
            .padding(14)
        }
    }
}

// MARK: - 寄港の記録(コンパクト)

struct PortLogCompactCard: View {
    var onOpen: () -> Void = {}

    private var latest: PastVoyage? { SampleData.pastVoyages.first }

    var body: some View {
        CompactTile(action: onOpen) {
            VStack(alignment: .leading, spacing: 8) {
                TileTitle(symbol: "clock.arrow.circlepath", title: "寄港の記録")
                Spacer(minLength: 0)
                if let latest {
                    HStack(spacing: 8) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(latest.tint.opacity(0.3))
                            Image(systemName: latest.symbolName)
                                .font(.anchorBody(13))
                                .foregroundStyle(AnchorTheme.moonGlow.opacity(0.85))
                        }
                        .frame(width: 34, height: 34)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(latest.title)
                                .font(.anchorBody(13))
                                .foregroundStyle(AnchorTheme.textPrimary)
                                .lineLimit(1)
                            Text(latest.dateLabel)
                                .font(.anchorBody(11))
                                .foregroundStyle(AnchorTheme.textSecondary)
                        }
                    }
                } else {
                    Text("まだ記録が\nありません")
                        .font(.anchorBody(13))
                        .foregroundStyle(AnchorTheme.textSecondary)
                }
            }
            .padding(14)
        }
    }
}
