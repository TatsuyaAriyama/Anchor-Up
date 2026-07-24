import SwiftUI

/// 夜の海・帆船・目的地の島を描くロープリ風イラスト。
/// 将来アニメーション(月光の揺らぎ、波紋)を加えられるよう、
/// 揺らぎ量をパラメータとして受け取る構造にしてある。
/// 現状は静的(すべて 0)で描画する。
struct HeroIllustrationView: View {
    /// 月光の明滅 (0.0 - 1.0)。将来 TimelineView から供給する
    var glowPhase: Double = 0
    /// 波のうねり (0.0 - 1.0)
    var wavePhase: Double = 0

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let horizon = h * 0.52

            ZStack {
                // 空: 深い夜の海に沈む空
                LinearGradient(
                    colors: [AnchorTheme.seaDeep, AnchorTheme.seaShallow],
                    startPoint: .top,
                    endPoint: .bottom
                )

                // 星
                ForEach(Array(starPositions.enumerated()), id: \.offset) { _, p in
                    Circle()
                        .fill(AnchorTheme.moonGlow.opacity(p.z))
                        .frame(width: 2.5, height: 2.5)
                        .position(x: p.x * w, y: p.y * horizon)
                }

                // 月とにじむ光
                let moonCenter = CGPoint(x: w * 0.76, y: h * 0.2)
                Circle()
                    .fill(AnchorTheme.moonGlow.opacity(0.16 + glowPhase * 0.06))
                    .frame(width: w * 0.3, height: w * 0.3)
                    .position(moonCenter)
                    .blur(radius: 18)
                Circle()
                    .fill(AnchorTheme.moonGlow)
                    .frame(width: w * 0.11, height: w * 0.11)
                    .position(moonCenter)

                // 目的地の島(右奥)。低ポリの重なる山影
                islandPath(in: geo.size, horizon: horizon)
                    .fill(AnchorTheme.hullShadow.opacity(0.55))
                islandFrontPath(in: geo.size, horizon: horizon)
                    .fill(AnchorTheme.hullTan.opacity(0.4))

                // 海面: 奥から手前へ層を重ねる
                seaLayer(in: geo.size, top: horizon, amp: 4, phase: wavePhase)
                    .fill(AnchorTheme.seaDeep.opacity(0.9))
                seaLayer(in: geo.size, top: horizon + h * 0.13, amp: 6, phase: wavePhase + 0.4)
                    .fill(AnchorTheme.seaShallow.opacity(0.75))
                seaLayer(in: geo.size, top: horizon + h * 0.28, amp: 8, phase: wavePhase + 0.8)
                    .fill(AnchorTheme.seaDeep.opacity(0.85))

                // 月光の水面反射
                MoonTrail(center: moonCenter, horizon: horizon, size: geo.size)
                    .fill(AnchorTheme.moonGlow.opacity(0.10 + glowPhase * 0.05))
                    .blur(radius: 3)

                // 帆船: 島(目的地)へ向かって出航準備中
                boat(in: geo.size, horizon: horizon)
            }
        }
        .clipped()
    }

    // MARK: - 部品

    private var starPositions: [(x: CGFloat, y: CGFloat, z: CGFloat)] {
        [
            (0.08, 0.18, 0.7), (0.2, 0.34, 0.4), (0.31, 0.12, 0.6),
            (0.44, 0.28, 0.35), (0.55, 0.1, 0.55), (0.63, 0.4, 0.3),
            (0.9, 0.5, 0.45), (0.95, 0.14, 0.6), (0.13, 0.55, 0.3),
        ]
    }

    private func islandPath(in size: CGSize, horizon: CGFloat) -> Path {
        let w = size.width
        return Path { p in
            p.move(to: CGPoint(x: w * 0.62, y: horizon))
            p.addLine(to: CGPoint(x: w * 0.74, y: horizon - size.height * 0.14))
            p.addLine(to: CGPoint(x: w * 0.84, y: horizon - size.height * 0.05))
            p.addLine(to: CGPoint(x: w * 0.95, y: horizon - size.height * 0.18))
            p.addLine(to: CGPoint(x: w * 1.05, y: horizon))
            p.closeSubpath()
        }
    }

    private func islandFrontPath(in size: CGSize, horizon: CGFloat) -> Path {
        let w = size.width
        return Path { p in
            p.move(to: CGPoint(x: w * 0.72, y: horizon))
            p.addLine(to: CGPoint(x: w * 0.82, y: horizon - size.height * 0.09))
            p.addLine(to: CGPoint(x: w * 0.92, y: horizon))
            p.closeSubpath()
        }
    }

    /// なだらかな折れ線(低ポリ)の海面レイヤー
    private func seaLayer(in size: CGSize, top: CGFloat, amp: CGFloat, phase: Double) -> Path {
        let w = size.width
        let h = size.height
        let segments = 6
        return Path { p in
            p.move(to: CGPoint(x: 0, y: top))
            for i in 1...segments {
                let x = w * CGFloat(i) / CGFloat(segments)
                let lift = sin(Double(i) * 1.7 + phase * .pi * 2) * amp
                p.addLine(to: CGPoint(x: x, y: top + lift))
            }
            p.addLine(to: CGPoint(x: w, y: h))
            p.addLine(to: CGPoint(x: 0, y: h))
            p.closeSubpath()
        }
    }

    /// 帆船(船体+二枚の帆)。目的地の島に向かう構図で右向きに置く
    @ViewBuilder
    private func boat(in size: CGSize, horizon: CGFloat) -> some View {
        let w = size.width
        let h = size.height
        let baseX = w * 0.32
        let baseY = horizon + h * 0.16

        ZStack {
            // 船体
            Path { p in
                p.move(to: CGPoint(x: baseX - w * 0.13, y: baseY))
                p.addLine(to: CGPoint(x: baseX + w * 0.15, y: baseY))
                p.addLine(to: CGPoint(x: baseX + w * 0.10, y: baseY + h * 0.07))
                p.addLine(to: CGPoint(x: baseX - w * 0.09, y: baseY + h * 0.07))
                p.closeSubpath()
            }
            .fill(AnchorTheme.hullShadow)

            // マスト
            Path { p in
                p.move(to: CGPoint(x: baseX, y: baseY))
                p.addLine(to: CGPoint(x: baseX, y: baseY - h * 0.3))
            }
            .stroke(AnchorTheme.hullShadow, lineWidth: 2.5)

            // 主帆(進行方向=右へ膨らむ)
            Path { p in
                p.move(to: CGPoint(x: baseX + w * 0.015, y: baseY - h * 0.29))
                p.addLine(to: CGPoint(x: baseX + w * 0.13, y: baseY - h * 0.03))
                p.addLine(to: CGPoint(x: baseX + w * 0.015, y: baseY - h * 0.03))
                p.closeSubpath()
            }
            .fill(AnchorTheme.hullTan)

            // 前帆
            Path { p in
                p.move(to: CGPoint(x: baseX - w * 0.015, y: baseY - h * 0.25))
                p.addLine(to: CGPoint(x: baseX - w * 0.10, y: baseY - h * 0.03))
                p.addLine(to: CGPoint(x: baseX - w * 0.015, y: baseY - h * 0.03))
                p.closeSubpath()
            }
            .fill(AnchorTheme.hullTan.opacity(0.85))
        }
    }
}

/// 月光が水面に落ちる帯
private struct MoonTrail: Shape {
    let center: CGPoint
    let horizon: CGFloat
    let size: CGSize

    func path(in rect: CGRect) -> Path {
        Path { p in
            p.move(to: CGPoint(x: center.x - size.width * 0.03, y: horizon))
            p.addLine(to: CGPoint(x: center.x + size.width * 0.03, y: horizon))
            p.addLine(to: CGPoint(x: center.x + size.width * 0.09, y: size.height))
            p.addLine(to: CGPoint(x: center.x - size.width * 0.09, y: size.height))
            p.closeSubpath()
        }
    }
}

#Preview {
    HeroIllustrationView()
        .frame(height: 220)
}
