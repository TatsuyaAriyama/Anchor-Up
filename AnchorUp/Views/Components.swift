import SwiftUI

// MARK: - アンカーロゴ

/// アプリロゴのアンカー(錨)。SF Symbolsに錨が無いため自前で描く
struct AnchorMark: Shape {
    func path(in rect: CGRect) -> Path {
        let s = min(rect.width, rect.height) / 24
        let cx = rect.midX
        var p = Path()

        // リング
        p.addEllipse(in: CGRect(x: cx - 2.6 * s, y: 1.5 * s, width: 5.2 * s, height: 5.2 * s))
        // シャフト
        p.move(to: CGPoint(x: cx, y: 6.7 * s))
        p.addLine(to: CGPoint(x: cx, y: 19.5 * s))
        // クロスバー
        p.move(to: CGPoint(x: cx - 4.5 * s, y: 10.5 * s))
        p.addLine(to: CGPoint(x: cx + 4.5 * s, y: 10.5 * s))
        // 両腕(フルーク)
        p.move(to: CGPoint(x: cx, y: 19.5 * s))
        p.addQuadCurve(
            to: CGPoint(x: cx - 7.2 * s, y: 13 * s),
            control: CGPoint(x: cx - 5.5 * s, y: 19 * s)
        )
        p.move(to: CGPoint(x: cx, y: 19.5 * s))
        p.addQuadCurve(
            to: CGPoint(x: cx + 7.2 * s, y: 13 * s),
            control: CGPoint(x: cx + 5.5 * s, y: 19 * s)
        )
        return p
    }
}

struct AnchorLogo: View {
    var size: CGFloat = 20
    var color: Color = AnchorTheme.hullTan

    var body: some View {
        AnchorMark()
            .stroke(color, style: StrokeStyle(lineWidth: size * 0.085, lineCap: .round))
            .frame(width: size, height: size)
    }
}

// MARK: - 上部セグメントタブ

enum AppTab: String, CaseIterable {
    case home = "ホーム"
    case packing = "持ち物"
    case crew = "乗組員"
    case myPage = "マイページ"

    var symbolName: String {
        switch self {
        case .home: "helm"          // 舵輪
        case .packing: "duffle.bag"
        case .crew: "flag.2.crossed"
        case .myPage: "person"
        }
    }
}

struct SegmentTabBar: View {
    @Binding var selection: AppTab

    var body: some View {
        HStack(spacing: 0) {
            ForEach(AppTab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.easeOut(duration: 0.2)) { selection = tab }
                } label: {
                    VStack(spacing: 7) {
                        HStack(spacing: 5) {
                            Image(systemName: tab.symbolName)
                                .font(.anchorBody(13))
                            Text(tab.rawValue)
                                .font(.anchorHeading(13))
                        }
                        .foregroundStyle(
                            selection == tab ? AnchorTheme.textPrimary : AnchorTheme.textSecondary
                        )

                        // 選択中のみアクセントカラーの下線
                        Capsule()
                            .fill(selection == tab ? AnchorTheme.accent : .clear)
                            .frame(height: 3)
                            .padding(.horizontal, 10)
                    }
                }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 10)
    }
}

// MARK: - 進捗リング

struct ProgressRing: View {
    let progress: Double
    var lineWidth: CGFloat = 5
    var tint: Color = AnchorTheme.hullTan

    var body: some View {
        ZStack {
            Circle()
                .stroke(AnchorTheme.moonGlow.opacity(0.15), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(tint, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
    }
}

// MARK: - 乗組員アバター

struct CrewAvatar: View {
    let member: CrewMember
    var size: CGFloat = 34

    var body: some View {
        ZStack {
            Circle().fill(member.color)
            Text(member.initial)
                .font(.anchorHeading(size * 0.42))
                .foregroundStyle(AnchorTheme.textPrimary)
        }
        .frame(width: size, height: size)
    }
}

// MARK: - セクション見出し

struct SectionHeader: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.anchorHeading(17))
            .foregroundStyle(AnchorTheme.textPrimary)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}
