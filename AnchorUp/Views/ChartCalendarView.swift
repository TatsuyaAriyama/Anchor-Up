import SwiftUI

/// 航海図(カレンダー)。自分の予定と、招待した乗組員の色が海図の上に並ぶ。
struct ChartCalendarView: View {
    @ObservedObject var store: AnchorStore
    var onEdit: (Voyage) -> Void = { _ in }
    var onCreate: (Date) -> Void = { _ in }

    @State private var monthAnchor: Date = Date()
    @State private var selectedDay: Date = Date()

    private var cal: Calendar { Calendar.current }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                header

                chartCard

                legend

                dayDetail
            }
            .padding(.horizontal, 20)
            .padding(.top, 24)
            .padding(.bottom, 190) // 舵輪ぶんの余白
        }
        .scrollIndicators(.hidden)
    }

    // MARK: - ヘッダー(月の航行)

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("航海図")
                .font(.anchorHeading(26))
                .foregroundStyle(AnchorTheme.textPrimary)

            HStack(spacing: 14) {
                Text(monthTitle)
                    .font(.anchorDisplay(18, weight: .semibold))
                    .foregroundStyle(AnchorTheme.textSecondary)

                Spacer()

                Button { shiftMonth(-1) } label: {
                    Image(systemName: "chevron.left")
                        .font(.anchorHeading(15))
                        .foregroundStyle(AnchorTheme.textPrimary)
                        .frame(width: 34, height: 34)
                        .background(AnchorTheme.surface, in: Circle())
                }
                .buttonStyle(.plain)

                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        monthAnchor = Date()
                        selectedDay = Date()
                    }
                    Haptics.tap()
                } label: {
                    Text("今日")
                        .font(.anchorHeading(13))
                        .foregroundStyle(AnchorTheme.accent)
                        .padding(.horizontal, 12)
                        .frame(height: 34)
                        .background(AnchorTheme.surface, in: Capsule())
                }
                .buttonStyle(.plain)

                Button { shiftMonth(1) } label: {
                    Image(systemName: "chevron.right")
                        .font(.anchorHeading(15))
                        .foregroundStyle(AnchorTheme.textPrimary)
                        .frame(width: 34, height: 34)
                        .background(AnchorTheme.surface, in: Circle())
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var monthTitle: String {
        monthAnchor.formatted(
            Date.FormatStyle(locale: .init(identifier: "ja_JP")).year().month(.wide)
        )
    }

    private func shiftMonth(_ delta: Int) {
        withAnimation(.easeInOut(duration: 0.2)) {
            monthAnchor = cal.date(byAdding: .month, value: delta, to: monthAnchor) ?? monthAnchor
        }
        Haptics.tap()
    }

    // MARK: - 海図(月のグリッド)

    private var chartCard: some View {
        VStack(spacing: 8) {
            // 曜日(日は暖色、土は海色)
            HStack(spacing: 0) {
                ForEach(Array(["日", "月", "火", "水", "木", "金", "土"].enumerated()), id: \.offset) { i, w in
                    Text(w)
                        .font(.anchorHeading(11))
                        .foregroundStyle(
                            i == 0 ? AnchorTheme.tileTerracotta :
                            i == 6 ? AnchorTheme.seaShallow : AnchorTheme.textSecondary
                        )
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.bottom, 2)

            let cells = monthCells()
            let rows = cells.chunked(into: 7)
            ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                HStack(spacing: 0) {
                    ForEach(Array(row.enumerated()), id: \.offset) { _, day in
                        if let day {
                            dayCell(day)
                        } else {
                            Color.clear.frame(maxWidth: .infinity, minHeight: 46)
                        }
                    }
                }
            }
        }
        .padding(14)
        .background(AnchorTheme.surface, in: RoundedRectangle(cornerRadius: AnchorTheme.cornerLarge, style: .continuous))
        // 海図の経緯線のような薄い罫線
        .overlay(
            RoundedRectangle(cornerRadius: AnchorTheme.cornerLarge, style: .continuous)
                .strokeBorder(AnchorTheme.moonGlow.opacity(0.07), lineWidth: 1)
        )
    }

    private func dayCell(_ day: Date) -> some View {
        let plansToday = store.plans(on: day)
        let isToday = cal.isDateInToday(day)
        let isSelected = cal.isDate(day, inSameDayAs: selectedDay)

        return Button {
            withAnimation(.easeInOut(duration: 0.18)) { selectedDay = day }
            Haptics.tap()
        } label: {
            VStack(spacing: 4) {
                Text("\(cal.component(.day, from: day))")
                    .font(.anchorDisplay(15, weight: isToday ? .bold : .regular))
                    .foregroundStyle(
                        isSelected ? AnchorTheme.seaDeep :
                        isToday ? AnchorTheme.moonGlow : AnchorTheme.textPrimary
                    )
                    .frame(width: 30, height: 30)
                    .background {
                        if isSelected {
                            Circle().fill(AnchorTheme.hullTan)
                        } else if isToday {
                            Circle().strokeBorder(AnchorTheme.moonGlow.opacity(0.7), lineWidth: 1.2)
                        }
                    }

                // 航海の印(あなた=アクセント、乗組員=各自の色)
                HStack(spacing: 3) {
                    ForEach(Array(dayDots(plansToday).prefix(4).enumerated()), id: \.offset) { _, color in
                        Circle().fill(color).frame(width: 5, height: 5)
                    }
                }
                .frame(height: 6)
            }
            .frame(maxWidth: .infinity, minHeight: 46)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    /// 日付セルに付ける点の色: 予定があれば「あなた」+ 招待乗組員の色
    private func dayDots(_ plans: [Voyage]) -> [Color] {
        guard !plans.isEmpty else { return [] }
        var colors: [Color] = [AnchorTheme.accent] // あなた
        var seen = Set<UUID>()
        for plan in plans {
            for mate in store.members(of: plan) where !seen.contains(mate.id) {
                seen.insert(mate.id)
                colors.append(mate.color)
            }
        }
        return colors
    }

    // MARK: - 凡例

    private var legend: some View {
        // 今月の航海に登場する乗組員だけを凡例に出す
        let mates = monthMates()
        return HStack(spacing: 14) {
            legendItem(color: AnchorTheme.accent, name: "あなた")
            ForEach(mates) { mate in
                legendItem(color: mate.color, name: mate.name)
            }
            Spacer()
        }
        .padding(.horizontal, 4)
    }

    private func legendItem(color: Color, name: String) -> some View {
        HStack(spacing: 5) {
            Circle().fill(color).frame(width: 7, height: 7)
            Text(name)
                .font(.anchorBody(11))
                .foregroundStyle(AnchorTheme.textSecondary)
        }
    }

    private func monthMates() -> [Crewmate] {
        guard let interval = cal.dateInterval(of: .month, for: monthAnchor) else { return [] }
        var seen = Set<UUID>()
        var result: [Crewmate] = []
        for plan in store.plans where interval.contains(plan.date) {
            for mate in store.members(of: plan) where !seen.contains(mate.id) {
                seen.insert(mate.id)
                result.append(mate)
            }
        }
        return result
    }

    // MARK: - 選択日の詳細

    private var dayDetail: some View {
        let plansToday = store.plans(on: selectedDay)
        return VStack(alignment: .leading, spacing: 10) {
            Text(selectedDay.formatted(
                Date.FormatStyle(locale: .init(identifier: "ja_JP")).month(.wide).day().weekday(.wide)
            ))
            .font(.anchorHeading(15))
            .foregroundStyle(AnchorTheme.textPrimary)

            if plansToday.isEmpty {
                Button {
                    onCreate(selectedDay)
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "plus.circle")
                            .foregroundStyle(AnchorTheme.accent)
                        Text("この日の航海を計画する")
                            .font(.anchorBody(14))
                            .foregroundStyle(AnchorTheme.textPrimary)
                        Spacer()
                    }
                    .padding(14)
                    .background(AnchorTheme.surface, in: RoundedRectangle(cornerRadius: AnchorTheme.cornerMedium, style: .continuous))
                }
                .buttonStyle(.plain)
            } else {
                VStack(spacing: 8) {
                    ForEach(plansToday) { plan in
                        Button { onEdit(plan) } label: {
                            planRow(plan)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private func planRow(_ plan: Voyage) -> some View {
        HStack(spacing: 12) {
            // 帆船の印
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(AnchorTheme.seaDeep.opacity(0.6))
                Image(systemName: plan.isFinished ? "checkmark.seal" : "sailboat")
                    .font(.anchorBody(15))
                    .foregroundStyle(AnchorTheme.moonGlow.opacity(0.9))
            }
            .frame(width: 40, height: 40)

            VStack(alignment: .leading, spacing: 3) {
                Text(plan.title)
                    .font(.anchorHeading(15))
                    .foregroundStyle(AnchorTheme.textPrimary)
                    .lineLimit(1)
                HStack(spacing: 8) {
                    if plan.hasTime {
                        Text(plan.date.formatted(
                            Date.FormatStyle(locale: .init(identifier: "ja_JP")).hour().minute()
                        ))
                        .font(.anchorDisplay(12, weight: .semibold))
                        .foregroundStyle(AnchorTheme.accent)
                    }
                    if !plan.destination.isEmpty {
                        Text(plan.destination)
                            .font(.anchorBody(12))
                            .foregroundStyle(AnchorTheme.textSecondary)
                            .lineLimit(1)
                    }
                }
            }

            Spacer()

            // 参加する乗組員
            HStack(spacing: -7) {
                ForEach(store.members(of: plan).prefix(4)) { mate in
                    CrewmateAvatar(mate: mate, size: 26)
                        .overlay(Circle().stroke(AnchorTheme.surface, lineWidth: 1.5))
                }
            }
        }
        .padding(12)
        .background(AnchorTheme.surface, in: RoundedRectangle(cornerRadius: AnchorTheme.cornerMedium, style: .continuous))
    }

    // MARK: - 月のセル生成

    /// 月のセル(週頭の空きはnil)
    private func monthCells() -> [Date?] {
        guard let interval = cal.dateInterval(of: .month, for: monthAnchor),
              let dayCount = cal.range(of: .day, in: .month, for: monthAnchor)?.count else { return [] }
        let first = interval.start
        let leading = cal.component(.weekday, from: first) - 1 // 日曜=1
        var cells = [Date?](repeating: nil, count: leading)
        for d in 0..<dayCount {
            cells.append(cal.date(byAdding: .day, value: d, to: first))
        }
        while cells.count % 7 != 0 { cells.append(nil) }
        return cells
    }
}

private extension Array {
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}

#Preview {
    ZStack {
        AnchorTheme.background.ignoresSafeArea()
        ChartCalendarView(store: AnchorStore())
    }
    .preferredColorScheme(.dark)
}
