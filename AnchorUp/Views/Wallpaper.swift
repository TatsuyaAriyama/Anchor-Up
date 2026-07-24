import SwiftUI

// MARK: - 壁紙の種類

enum Wallpaper: String, Codable, CaseIterable, Identifiable {
    case deep      // 深海(無地)
    case midnight  // 真夜中の海
    case aurora    // 極光の海
    case dawn      // 暁の凪
    case abyss     // 深淵
    case tide      // 潮騒

    var id: String { rawValue }

    var name: String {
        switch self {
        case .deep: "深海"
        case .midnight: "真夜中の海"
        case .aurora: "極光の海"
        case .dawn: "暁の凪"
        case .abyss: "深淵"
        case .tide: "潮騒"
        }
    }
}

// MARK: - 壁紙の描画

struct WallpaperView: View {
    let wallpaper: Wallpaper

    var body: some View {
        switch wallpaper {
        case .deep: AnchorTheme.background
        case .midnight: MidnightSeaBackground()
        case .aurora: AuroraSeaBackground()
        case .dawn: DawnCalmBackground()
        case .abyss: AbyssBackground()
        case .tide: TideBackground()
        }
    }
}

// MARK: - 波のシルエット(低ポリ)

private struct WaveShape: Shape {
    var amplitude: CGFloat
    /// 波が座る高さ(0=上, 1=下)
    var baseline: CGFloat
    var phase: CGFloat

    func path(in rect: CGRect) -> Path {
        let w = rect.width
        let h = rect.height
        let y0 = h * baseline
        let steps = 8
        return Path { p in
            p.move(to: CGPoint(x: 0, y: y0))
            for i in 0...steps {
                let x = w * CGFloat(i) / CGFloat(steps)
                let y = y0 + sin(CGFloat(i) * 0.9 + phase) * amplitude
                p.addLine(to: CGPoint(x: x, y: y))
            }
            p.addLine(to: CGPoint(x: w, y: h))
            p.addLine(to: CGPoint(x: 0, y: h))
            p.closeSubpath()
        }
    }
}

// 星の固定配置(上部のみ)
private let starField: [(x: CGFloat, y: CGFloat, z: Double)] = [
    (0.10, 0.08, 0.6), (0.22, 0.16, 0.35), (0.33, 0.06, 0.5),
    (0.46, 0.13, 0.3), (0.58, 0.05, 0.55), (0.67, 0.18, 0.3),
    (0.74, 0.10, 0.45), (0.88, 0.07, 0.5), (0.94, 0.20, 0.3),
    (0.16, 0.24, 0.28), (0.52, 0.22, 0.3), (0.40, 0.28, 0.22),
]

// MARK: - 真夜中の海

private struct MidnightSeaBackground: View {
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            ZStack {
                LinearGradient(
                    colors: [Color(hex: 0x0F1413), Color(hex: 0x11302C), Color(hex: 0x0A1E1B)],
                    startPoint: .top, endPoint: .bottom
                )

                ForEach(Array(starField.enumerated()), id: \.offset) { _, s in
                    Circle()
                        .fill(AnchorTheme.moonGlow.opacity(s.z))
                        .frame(width: 2, height: 2)
                        .position(x: s.x * w, y: s.y * h)
                }

                // 月あかり(やわらかな光のみ。ヘッダーと干渉しないよう控えめ・低め)
                Circle()
                    .fill(AnchorTheme.moonGlow.opacity(0.10))
                    .frame(width: w * 0.6, height: w * 0.6)
                    .blur(radius: 58)
                    .position(x: w * 0.78, y: h * 0.27)

                // 波レイヤー
                WaveShape(amplitude: 8, baseline: 0.72, phase: 0).fill(AnchorTheme.seaShallow.opacity(0.45))
                WaveShape(amplitude: 10, baseline: 0.82, phase: 1.4).fill(AnchorTheme.seaDeep.opacity(0.7))
                WaveShape(amplitude: 12, baseline: 0.92, phase: 2.6).fill(Color(hex: 0x081513))
            }
        }
    }
}

// MARK: - 極光の海

private struct AuroraSeaBackground: View {
    private struct Ribbon { let color: Color; let x, y, wf, hf, rot: CGFloat }
    private let ribbons: [Ribbon] = [
        Ribbon(color: Color(hex: 0x2E6E5A), x: 0.30, y: 0.38, wf: 0.55, hf: 0.22, rot: -18),
        Ribbon(color: Color(hex: 0x3A5E7A), x: 0.62, y: 0.34, wf: 0.55, hf: 0.18, rot: 14),
        Ribbon(color: Color(hex: 0x5A4A72), x: 0.48, y: 0.48, wf: 0.62, hf: 0.16, rot: -6),
    ]

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            ZStack {
                Color(hex: 0x0B0F11)

                ForEach(Array(ribbons.enumerated()), id: \.offset) { _, r in
                    Ellipse()
                        .fill(r.color.opacity(0.5))
                        .frame(width: w * r.wf, height: h * r.hf)
                        .rotationEffect(.degrees(r.rot))
                        .position(x: w * r.x, y: h * r.y)
                }
                .blur(radius: 48)

                ForEach(Array(starField.prefix(8).enumerated()), id: \.offset) { _, s in
                    Circle()
                        .fill(AnchorTheme.moonGlow.opacity(s.z * 0.7))
                        .frame(width: 1.8, height: 1.8)
                        .position(x: s.x * w, y: s.y * h)
                }

                LinearGradient(colors: [.clear, Color(hex: 0x070A0B)], startPoint: .center, endPoint: .bottom)
            }
        }
    }
}

// MARK: - 暁の凪

private struct DawnCalmBackground: View {
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            ZStack {
                LinearGradient(
                    colors: [Color(hex: 0x121110), Color(hex: 0x1B1512), Color(hex: 0x2B1E17)],
                    startPoint: .top, endPoint: .bottom
                )

                // 水平線ににじむ暖色の光
                Ellipse()
                    .fill(AnchorTheme.accent.opacity(0.28))
                    .frame(width: w * 1.5, height: h * 0.34)
                    .blur(radius: 40)
                    .position(x: w * 0.5, y: h * 0.9)
                Circle()
                    .fill(Color(hex: 0xE8A45C).opacity(0.35))
                    .frame(width: w * 0.4, height: w * 0.4)
                    .blur(radius: 34)
                    .position(x: w * 0.5, y: h * 0.96)

                // 波のシルエット
                WaveShape(amplitude: 8, baseline: 0.8, phase: 0.6).fill(Color(hex: 0x1A120E).opacity(0.85))
                WaveShape(amplitude: 11, baseline: 0.9, phase: 2.1).fill(Color(hex: 0x0E0A08))
            }
        }
    }
}

// MARK: - 深淵

private struct AbyssBackground: View {
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            ZStack {
                RadialGradient(
                    colors: [Color(hex: 0x13201E), Color(hex: 0x080B0B)],
                    center: .center, startRadius: 8, endRadius: max(w, h) * 0.85
                )

                // 波紋のリング
                ForEach(0..<4, id: \.self) { i in
                    Circle()
                        .stroke(AnchorTheme.seaShallow.opacity(0.11 * Double(4 - i)), lineWidth: 1.2)
                        .frame(width: w * (0.35 + 0.28 * CGFloat(i)))
                        .position(x: w * 0.5, y: h * 0.55)
                }

                // 生物発光のようなかすかな光
                Circle()
                    .fill(AnchorTheme.seaShallow.opacity(0.2))
                    .frame(width: w * 0.5, height: w * 0.5)
                    .blur(radius: 55)
                    .position(x: w * 0.5, y: h * 0.58)
            }
        }
    }
}

// MARK: - 潮騒

private struct TideBackground: View {
    var body: some View {
        GeometryReader { _ in
            ZStack {
                LinearGradient(
                    colors: [Color(hex: 0x0F1312), Color(hex: 0x102A27)],
                    startPoint: .top, endPoint: .bottom
                )
                WaveShape(amplitude: 10, baseline: 0.55, phase: 0).fill(AnchorTheme.seaShallow.opacity(0.30))
                WaveShape(amplitude: 12, baseline: 0.66, phase: 1.0).fill(AnchorTheme.seaDeep.opacity(0.55))
                WaveShape(amplitude: 10, baseline: 0.77, phase: 2.0).fill(AnchorTheme.hullShadow.opacity(0.22))
                WaveShape(amplitude: 14, baseline: 0.88, phase: 3.0).fill(Color(hex: 0x081514))
            }
        }
    }
}

#Preview {
    ScrollView {
        VStack(spacing: 12) {
            ForEach(Wallpaper.allCases) { wp in
                WallpaperView(wallpaper: wp)
                    .frame(height: 160)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(alignment: .bottomLeading) {
                        Text(wp.name).font(.anchorHeading(14)).foregroundStyle(.white).padding(12)
                    }
            }
        }
        .padding()
    }
    .background(.black)
}
