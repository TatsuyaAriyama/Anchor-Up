import SwiftUI

/// 画面下部の舵輪ナビゲーション。
/// 舵輪を指で回すと90°ごとにデテントが効き、タブが切り替わる。
struct HelmControl: View {
    @Binding var selection: AppTab

    /// 舵輪の累積回転角(度)
    @State private var angle: Double = 0
    /// 直前の指の角度(度)。ドラッグ中のみ非nil
    @State private var lastTouchAngle: Double?

    private let tabs = AppTab.allCases
    private let wheelSize: CGFloat = 300

    var body: some View {
        VStack(spacing: 12) {
            // 現在の区画名
            HStack(spacing: 7) {
                Image(systemName: selection.symbolName)
                    .font(.anchorBody(13))
                Text(selection.rawValue)
                    .font(.anchorHeading(15))
                    .tracking(2)
            }
            .foregroundStyle(AnchorTheme.textPrimary)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial.opacity(0.6), in: Capsule())
            .background(AnchorTheme.background.opacity(0.55), in: Capsule())
            .id(selection)
            .transition(.opacity.combined(with: .scale(scale: 0.92)))

            // ジェスチャは回転しない外側に付ける(回転体に付けると座標系が回って角度計算が狂う)
            ZStack {
                HelmWheelView()
                    .rotationEffect(.degrees(angle))
            }
            .frame(width: wheelSize, height: wheelSize)
            .contentShape(Circle())
            .gesture(rotationDrag)
            .shadow(color: .black.opacity(0.45), radius: 18, y: -4)
        }
        .animation(.spring(response: 0.32, dampingFraction: 0.8), value: selection)
    }

    // MARK: - 回転ジェスチャ

    private var rotationDrag: some Gesture {
        DragGesture(minimumDistance: 2)
            .onChanged { value in
                let c = wheelSize / 2
                let touch = angleOf(value.location, center: CGPoint(x: c, y: c))
                if let last = lastTouchAngle {
                    angle += shortestDelta(touch - last)
                    updateSelectionLive()
                }
                lastTouchAngle = touch
            }
            .onEnded { _ in
                lastTouchAngle = nil
                // 最寄りのデテント(90°)へ吸い付く
                withAnimation(.spring(response: 0.35, dampingFraction: 0.72)) {
                    angle = (angle / 90).rounded() * 90
                }
                Haptics.soft()
            }
    }

    private func angleOf(_ p: CGPoint, center: CGPoint) -> Double {
        atan2(p.y - center.y, p.x - center.x) * 180 / .pi
    }

    /// -180〜180 に正規化した最小差分
    private func shortestDelta(_ d: Double) -> Double {
        var d = d.truncatingRemainder(dividingBy: 360)
        if d > 180 { d -= 360 }
        if d < -180 { d += 360 }
        return d
    }

    /// 回転中、最寄りのデテントに対応するタブへライブ切替
    private func updateSelectionLive() {
        let idx = ((Int((angle / 90).rounded()) % tabs.count) + tabs.count) % tabs.count
        let tab = tabs[idx]
        if tab != selection {
            withAnimation(.easeInOut(duration: 0.22)) { selection = tab }
            Haptics.tap()
        }
    }
}

// MARK: - 舵輪の描画

/// 木製の舵輪。8本のスポーク(=4本の貫通バー)、リム、ハブ。
struct HelmWheelView: View {
    var body: some View {
        GeometryReader { geo in
            let s = min(geo.size.width, geo.size.height)
            let R = s / 2
            ZStack {
                // 貫通バー(ハンドル)。リムの外まで突き出た部分が持ち手になる
                ForEach(0..<4, id: \.self) { i in
                    Capsule()
                        .fill(AnchorTheme.hullShadow)
                        .frame(width: R * 0.075, height: s * 0.985)
                        .rotationEffect(.degrees(Double(i) * 45))
                }

                // ハンドルの先端の飾り(ノブ)
                ForEach(0..<8, id: \.self) { i in
                    Circle()
                        .fill(AnchorTheme.hullTan)
                        .frame(width: R * 0.11, height: R * 0.11)
                        .offset(y: -R * 0.945)
                        .rotationEffect(.degrees(Double(i) * 45))
                }

                // リム(外輪)
                Circle()
                    .strokeBorder(AnchorTheme.hullShadow, lineWidth: R * 0.15)
                    .frame(width: R * 1.52, height: R * 1.52)
                // リムの縁のハイライト
                Circle()
                    .strokeBorder(AnchorTheme.moonGlow.opacity(0.14), lineWidth: 1.2)
                    .frame(width: R * 1.52, height: R * 1.52)
                Circle()
                    .strokeBorder(AnchorTheme.background.opacity(0.5), lineWidth: 1)
                    .frame(width: R * 1.22, height: R * 1.22)

                // ハブ(中心)
                Circle()
                    .fill(AnchorTheme.hullTan)
                    .frame(width: R * 0.3, height: R * 0.3)
                Circle()
                    .strokeBorder(AnchorTheme.seaDeep.opacity(0.55), lineWidth: 2)
                    .frame(width: R * 0.18, height: R * 0.18)
            }
            .frame(width: s, height: s)
        }
    }
}

#Preview {
    struct P: View {
        @State var tab: AppTab = .home
        var body: some View {
            ZStack(alignment: .bottom) {
                AnchorTheme.background.ignoresSafeArea()
                HelmControl(selection: $tab)
                    .offset(y: 150)
            }
        }
    }
    return P()
}
