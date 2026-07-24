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

                    // 3件を超える未チェックがある場合の「他N件」
                    if moreCount > 0 {
                        Button(action: onOpen) {
                            HStack(spacing: 6) {
                                Text("他 \(moreCount) 件")
                                    .font(.anchorBody(13))
                                    .foregroundStyle(AnchorTheme.textSecondary)
                                Image(systemName: "chevron.right")
                                    .font(.anchorHeading(10))
                                    .foregroundStyle(AnchorTheme.textSecondary)
                                Spacer()
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 11)
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

    /// プレビューに載らなかった未チェックの件数
    private var moreCount: Int {
        max(0, (store.totalItemCount - store.checkedItemCount) - preview.count)
    }
}

// MARK: - 乗組員(概要。実データの名簿を表示)

struct CrewOverviewSection: View {
    @ObservedObject var store: AnchorStore
    var onOpen: () -> Void = {}

    var body: some View {
        VStack(spacing: 10) {
            HStack {
                SectionHeader(title: "乗組員")
                Button(action: onOpen) {
                    Text("名簿へ")
                        .font(.anchorHeading(13))
                        .foregroundStyle(AnchorTheme.accent)
                }
                .buttonStyle(.plain)
            }

            Button(action: onOpen) {
                Group {
                    if let plan = store.nextPlan, !plan.holdItems.isEmpty {
                        // 船倉の分担状況を優先して見せる
                        let unassigned = plan.holdItems.filter { !$0.isAssigned }
                        HStack(spacing: 12) {
                            Image(systemName: "shippingbox.fill")
                                .font(.anchorBody(18))
                                .foregroundStyle(unassigned.isEmpty ? AnchorTheme.hullTan : AnchorTheme.accent)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("船倉の分担")
                                    .font(.anchorHeading(14))
                                    .foregroundStyle(AnchorTheme.textPrimary)
                                Text(unassigned.isEmpty
                                     ? "全員の分担が決まりました"
                                     : "\(unassigned.map(\.name).joined(separator: "・"))が未定")
                                    .font(.anchorBody(12))
                                    .foregroundStyle(AnchorTheme.textSecondary)
                                    .lineLimit(1)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.anchorHeading(12))
                                .foregroundStyle(AnchorTheme.textSecondary)
                        }
                    } else if store.crew.isEmpty {
                        HStack(spacing: 10) {
                            Image(systemName: "person.badge.plus")
                                .foregroundStyle(AnchorTheme.hullTan)
                            Text("一緒に出かける仲間を登録しよう")
                                .font(.anchorBody(14))
                                .foregroundStyle(AnchorTheme.textPrimary)
                            Spacer()
                        }
                    } else {
                        HStack(spacing: 16) {
                            HStack(spacing: -10) {
                                ForEach(store.crew.prefix(6)) { mate in
                                    CrewmateAvatar(mate: mate, size: 40)
                                        .overlay(Circle().stroke(AnchorTheme.surface, lineWidth: 2))
                                }
                            }
                            Text("\(store.crew.count)人")
                                .font(.anchorHeading(15))
                                .foregroundStyle(AnchorTheme.textPrimary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.anchorHeading(12))
                                .foregroundStyle(AnchorTheme.textSecondary)
                        }
                    }
                }
                .padding(16)
                .background(AnchorTheme.surface, in: RoundedRectangle(cornerRadius: AnchorTheme.cornerMedium, style: .continuous))
            }
            .buttonStyle(.plain)
        }
    }
}

// MARK: - 寄港の記録(終わった航海)

/// 過去/出航済みの予定を表示する。実データが無ければ空状態。
struct PortLogSection: View {
    @ObservedObject var store: AnchorStore

    var body: some View {
        VStack(spacing: 10) {
            SectionHeader(title: "寄港の記録")

            if store.pastPlans.isEmpty {
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
                        ForEach(Array(store.pastPlans.enumerated()), id: \.element.id) { idx, voyage in
                            VStack(alignment: .leading, spacing: 0) {
                                ZStack {
                                    PortLog.tint(idx).opacity(0.35)
                                    Image(systemName: voyage.completedAt != nil ? "checkmark.seal" : "sailboat")
                                        .font(.anchorBody(24))
                                        .foregroundStyle(AnchorTheme.moonGlow.opacity(0.85))
                                }
                                .frame(width: 132, height: 84)

                                VStack(alignment: .leading, spacing: 3) {
                                    Text(voyage.title)
                                        .font(.anchorHeading(13))
                                        .foregroundStyle(AnchorTheme.textPrimary)
                                        .lineLimit(1)
                                    Text(PortLog.dateLabel(voyage))
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

/// 寄港の記録の表示ヘルパ
enum PortLog {
    static func tint(_ index: Int) -> Color {
        let palette = [AnchorTheme.tileTerracotta, AnchorTheme.seaShallow, AnchorTheme.tileIndigo, AnchorTheme.tileMustard]
        return palette[index % palette.count]
    }
    static func dateLabel(_ voyage: Voyage) -> String {
        let d = voyage.completedAt ?? voyage.date
        return d.formatted(Date.FormatStyle(locale: .init(identifier: "ja_JP")).month().day())
    }
}
