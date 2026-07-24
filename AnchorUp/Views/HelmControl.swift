import SwiftUI

/// 画面下部の舵輪ナビゲーション。
/// 回すと90°ごとにデテントが効いてタブが切り替わる。
/// 弾く(フリック)と慣性でスピンし、最寄りのデテントへ収まる。
struct HelmControl: View {
    @Binding var selection: AppTab
    /// 画面遷移の方向(+1: 順方向 / -1: 逆方向)。トランジションに使う
    @Binding var direction: Double
    /// 視差を減らす設定。慣性スピンを抑える
    var reduceMotion: Bool = false
    /// 初回の使い方ヒントを舵輪ラベルの上に出す
    var showHint: Bool = false

    /// 舵輪の累積回転角(度)
    @State private var angle: Double = 0
    /// 直前の指の角度(度)。ドラッグ中のみ非nil
    @State private var lastTouchAngle: Double?
    /// 角速度(度/秒)。フリックの慣性に使う
    @State private var angularVelocity: Double = 0
    @State private var lastMoveTime: Date?

    private let tabs = AppTab.allCases
    private let wheelSize: CGFloat = 300

    var body: some View {
        VStack(spacing: 10) {
            // 初回ヒント(舵輪ラベルの真上)
            if showHint {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.trianglehead.clockwise")
                        .font(.anchorBody(12))
                    Text("舵を回して切り替え")
                        .font(.anchorHeading(12))
                }
                .foregroundStyle(AnchorTheme.seaDeep)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(AnchorTheme.moonGlow, in: Capsule())
                .shadow(color: .black.opacity(0.35), radius: 8, y: 3)
                .transition(.scale(scale: 0.8).combined(with: .opacity))
            }

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
            // タップでも次の画面へ(回転できない人・素早い切替の両対応)
            .simultaneousGesture(TapGesture().onEnded { advance(by: 1) })
            .shadow(color: .black.opacity(0.45), radius: 18, y: -4)
            // ラバーライン(方位指標)。回転せず常に真上を指す
            .overlay(alignment: .top) {
                LubberLine()
                    .fill(AnchorTheme.accent)
                    .frame(width: 14, height: 9)
                    .offset(y: -13)
                    .shadow(color: .black.opacity(0.4), radius: 2, y: 1)
            }
            // VoiceOver: 上下スワイプで画面を送れる調整操作に
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("画面を切り替える舵輪")
            .accessibilityValue(selection.rawValue)
            .accessibilityHint("上下にスワイプ、またはタップで画面を切り替えます")
            .accessibilityAdjustableAction { dir in
                advance(by: dir == .increment ? 1 : -1)
            }
        }
        .animation(.spring(response: 0.32, dampingFraction: 0.8), value: selection)
    }

    /// タップ/アクセシビリティ操作で1コマ送る
    private func advance(by steps: Int) {
        let target = (((angle / 90).rounded()) + Double(steps)) * 90
        settle(to: target)
    }

    // MARK: - 回転ジェスチャ

    private var rotationDrag: some Gesture {
        DragGesture(minimumDistance: 2)
            .onChanged { value in
                let c = wheelSize / 2
                let touch = angleOf(value.location, center: CGPoint(x: c, y: c))
                let now = Date()
                if let last = lastTouchAngle {
                    let delta = shortestDelta(touch - last)
                    angle += delta
                    // 角速度を平滑化しながら追跡(フリック判定用)
                    if let t = lastMoveTime {
                        let dt = now.timeIntervalSince(t)
                        if dt > 0.001 {
                            angularVelocity = 0.75 * (delta / dt) + 0.25 * angularVelocity
                        }
                    }
                    updateSelectionLive()
                }
                lastTouchAngle = touch
                lastMoveTime = now
            }
            .onEnded { _ in
                lastTouchAngle = nil
                lastMoveTime = nil

                // フリックの勢いを投影し(最大3コマ)、最寄りのデテントへ。
                // 視差減の時は勢いを使わず最寄りへ収める
                let projectedSpin = reduceMotion ? 0 : max(-270, min(270, angularVelocity * 0.12))
                let target = ((angle + projectedSpin) / 90).rounded() * 90
                settle(to: target)
                angularVelocity = 0
            }
    }

    /// 目標デテントへスプリングで収める。必要ならタブも確定する
    private func settle(to target: Double) {
        let idx = wrappedIndex(for: target)
        if tabs[idx] != selection {
            applySelection(tabs[idx])
        }
        withAnimation(.spring(response: 0.5, dampingFraction: 0.74)) {
            angle = target
        }
        Haptics.soft()
    }

    /// 回転中、最寄りのデテントに対応するタブへライブ切替
    private func updateSelectionLive() {
        let tab = tabs[wrappedIndex(for: angle)]
        if tab != selection {
            applySelection(tab)
            Haptics.detent()
        }
    }

    /// 進行方向を決めてから選択を切り替える(トランジションの向きに使う)
    private func applySelection(_ tab: AppTab) {
        let old = tabs.firstIndex(of: selection) ?? 0
        let new = tabs.firstIndex(of: tab) ?? 0
        let diff = ((new - old) % tabs.count + tabs.count) % tabs.count
        direction = (diff == 1) ? 1 : (diff == tabs.count - 1 ? -1 : (angularVelocity >= 0 ? 1 : -1))
        withAnimation(.spring(response: 0.38, dampingFraction: 0.86)) {
            selection = tab
        }
    }

    private func wrappedIndex(for angle: Double) -> Int {
        ((Int((angle / 90).rounded()) % tabs.count) + tabs.count) % tabs.count
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
}

/// 方位指標(下向きの小さな三角)
private struct LubberLine: Shape {
    func path(in rect: CGRect) -> Path {
        Path { p in
            p.move(to: CGPoint(x: rect.minX, y: rect.minY))
            p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
            p.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
            p.closeSubpath()
        }
    }
}

// MARK: - 舵輪の描画

/// 木製の舵輪。木目の陰影・リムのリベット・真鍮風ハブに錨の刻印。
struct HelmWheelView: View {
    // 木の色味
    private let woodLight = Color(hex: 0xD8C49A)
    private let wood = AnchorTheme.hullTan
    private let woodDark = AnchorTheme.hullShadow
    private let brass = Color(hex: 0xCBB37B)

    var body: some View {
        GeometryReader { geo in
            let s = min(geo.size.width, geo.size.height)
            let R = s / 2
            ZStack {
                // 貫通バー(ハンドル)。上面に光が当たる木の丸棒
                ForEach(0..<4, id: \.self) { i in
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [woodLight.opacity(0.9), wood, woodDark],
                                startPoint: .leading, endPoint: .trailing
                            )
                        )
                        .frame(width: R * 0.078, height: s * 0.985)
                        .rotationEffect(.degrees(Double(i) * 45))
                }

                // ハンドル先端のノブ(立体感のある玉)
                ForEach(0..<8, id: \.self) { i in
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [woodLight, wood, woodDark],
                                center: UnitPoint(x: 0.35, y: 0.3),
                                startRadius: 0, endRadius: R * 0.09
                            )
                        )
                        .frame(width: R * 0.125, height: R * 0.125)
                        .offset(y: -R * 0.94)
                        .rotationEffect(.degrees(Double(i) * 45))
                }

                // リム(外輪)。上から光が回る木の輪
                Circle()
                    .strokeBorder(
                        LinearGradient(
                            colors: [wood, woodDark],
                            startPoint: .top, endPoint: .bottom
                        ),
                        lineWidth: R * 0.155
                    )
                    .frame(width: R * 1.52, height: R * 1.52)

                // リムの縁の光と影の細線
                Circle()
                    .strokeBorder(AnchorTheme.moonGlow.opacity(0.2), lineWidth: 1.2)
                    .frame(width: R * 1.52, height: R * 1.52)
                Circle()
                    .strokeBorder(AnchorTheme.background.opacity(0.55), lineWidth: 1)
                    .frame(width: R * 1.215, height: R * 1.215)
                // リム中央の飾り溝
                Circle()
                    .strokeBorder(woodDark.opacity(0.55), lineWidth: 1)
                    .frame(width: R * 1.37, height: R * 1.37)

                // リムのリベット(スポークの間・8箇所)
                ForEach(0..<8, id: \.self) { i in
                    Circle()
                        .fill(woodDark)
                        .overlay(Circle().strokeBorder(woodLight.opacity(0.35), lineWidth: 0.8))
                        .frame(width: R * 0.045, height: R * 0.045)
                        .offset(y: -R * 0.685)
                        .rotationEffect(.degrees(Double(i) * 45 + 22.5))
                }

                // ハブ(真鍮風の中心)
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [brass, wood, woodDark],
                            center: UnitPoint(x: 0.38, y: 0.32),
                            startRadius: 0, endRadius: R * 0.22
                        )
                    )
                    .frame(width: R * 0.34, height: R * 0.34)
                Circle()
                    .strokeBorder(woodDark.opacity(0.7), lineWidth: 1.5)
                    .frame(width: R * 0.34, height: R * 0.34)

                // ハブの錨の刻印(舵と一緒に回る)
                AnchorMark()
                    .stroke(
                        AnchorTheme.seaDeep.opacity(0.75),
                        style: StrokeStyle(lineWidth: R * 0.016, lineCap: .round)
                    )
                    .frame(width: R * 0.19, height: R * 0.19)
            }
            .frame(width: s, height: s)
        }
    }
}

#Preview {
    struct P: View {
        @State var tab: AppTab = .home
        @State var dir: Double = 1
        var body: some View {
            ZStack(alignment: .bottom) {
                AnchorTheme.background.ignoresSafeArea()
                HelmControl(selection: $tab, direction: $dir)
                    .offset(y: 150)
            }
        }
    }
    return P()
}
