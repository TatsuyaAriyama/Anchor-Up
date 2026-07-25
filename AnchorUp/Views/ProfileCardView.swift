import SwiftUI

/// 乗船証(プロフィールカード)。
/// 選んだ配色の海に、シンボルを掲げ、名前と言葉を刻んだ航海者の証。
struct ProfileCardView: View {
    let name: String
    let colorIndex: Int
    let symbol: ProfileSymbol
    let motto: String
    /// 招待コード。nil なら下段を出さない(相手のカードなど)
    var code: String?
    /// 小さめの表示(一覧向け)
    var compact: Bool = false

    private var tint: Color { CrewPalette.color(at: colorIndex) }

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // 海の底に沈むような縦のグラデーション
            LinearGradient(
                colors: [tint.opacity(0.75), tint.opacity(0.32), AnchorTheme.seaDeep.opacity(0.95)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // 右上に大きく透かしたシンボル
            ProfileSymbolView(symbol: symbol, size: compact ? 120 : 190,
                              color: AnchorTheme.moonGlow.opacity(0.13))
                .rotationEffect(.degrees(-12))
                .offset(x: compact ? 42 : 66, y: compact ? -16 : -26)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                .clipped()

            // 底の波
            WaveTrim()
                .fill(AnchorTheme.seaDeep.opacity(0.5))
                .frame(height: compact ? 26 : 38)
                .frame(maxHeight: .infinity, alignment: .bottom)

            VStack(alignment: .leading, spacing: 0) {
                // シンボルの徽章
                ZStack {
                    Circle().fill(AnchorTheme.seaDeep.opacity(0.45))
                    Circle().strokeBorder(AnchorTheme.moonGlow.opacity(0.35), lineWidth: 1)
                    ProfileSymbolView(symbol: symbol, size: compact ? 20 : 26,
                                      color: AnchorTheme.moonGlow)
                }
                .frame(width: compact ? 38 : 50, height: compact ? 38 : 50)

                Spacer(minLength: compact ? 10 : 16)

                Text(name.isEmpty ? "船長" : name)
                    .font(.anchorHeading(compact ? 19 : 25))
                    .foregroundStyle(AnchorTheme.moonGlow)
                    .lineLimit(1)

                if !motto.isEmpty {
                    Text(motto)
                        .font(.anchorBody(compact ? 11 : 13))
                        .foregroundStyle(AnchorTheme.moonGlow.opacity(0.8))
                        .lineLimit(2)
                        .padding(.top, 4)
                }

                if let code, !code.isEmpty {
                    Divider()
                        .overlay(AnchorTheme.moonGlow.opacity(0.22))
                        .padding(.top, compact ? 8 : 14)

                    HStack(spacing: 8) {
                        Text("乗船証")
                            .font(.anchorBody(10))
                            .foregroundStyle(AnchorTheme.moonGlow.opacity(0.6))
                            .tracking(2)
                        Text(code)
                            .font(.anchorDisplay(compact ? 13 : 15, weight: .bold))
                            .foregroundStyle(AnchorTheme.moonGlow)
                            .tracking(3)
                        Spacer()
                    }
                    .padding(.top, compact ? 6 : 9)
                }
            }
            .padding(compact ? 14 : 20)
        }
        .frame(height: cardHeight)
        .clipShape(RoundedRectangle(cornerRadius: AnchorTheme.cornerLarge, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AnchorTheme.cornerLarge, style: .continuous)
                .strokeBorder(AnchorTheme.moonGlow.opacity(0.14), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.35), radius: 12, y: 6)
    }

    private var cardHeight: CGFloat {
        if compact { return motto.isEmpty ? 122 : 138 }
        let base: CGFloat = motto.isEmpty ? 150 : 178
        return code == nil ? base : base + 40
    }
}

/// カード下端の波形
private struct WaveTrim: Shape {
    func path(in rect: CGRect) -> Path {
        Path { p in
            let w = rect.width, h = rect.height
            p.move(to: CGPoint(x: 0, y: h * 0.45))
            p.addCurve(to: CGPoint(x: w * 0.5, y: h * 0.5),
                       control1: CGPoint(x: w * 0.18, y: h * 0.05),
                       control2: CGPoint(x: w * 0.32, y: h * 0.9))
            p.addCurve(to: CGPoint(x: w, y: h * 0.4),
                       control1: CGPoint(x: w * 0.68, y: h * 0.1),
                       control2: CGPoint(x: w * 0.84, y: h * 0.85))
            p.addLine(to: CGPoint(x: w, y: h))
            p.addLine(to: CGPoint(x: 0, y: h))
            p.closeSubpath()
        }
    }
}

#Preview {
    ZStack {
        AnchorTheme.background.ignoresSafeArea()
        VStack(spacing: 20) {
            ProfileCardView(name: "Ari", colorIndex: 5, symbol: .anchor,
                            motto: "忘れ物なき航海を。", code: "S6RLCU")
            ProfileCardView(name: "ハルカ", colorIndex: 1, symbol: .sailboat,
                            motto: "海はいつでも呼んでいる", code: nil, compact: true)
        }
        .padding(20)
    }
    .preferredColorScheme(.dark)
}
