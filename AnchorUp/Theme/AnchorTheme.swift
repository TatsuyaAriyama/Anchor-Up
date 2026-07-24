import SwiftUI

// MARK: - Hex initializer

extension Color {
    init(hex: UInt32) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }
}

// MARK: - Anchor Up palette
// くすんだ大人トーンで統一。原色・ネオンは使わない。

enum AnchorTheme {
    /// 画面全体の背景。ほぼ黒に近い暖かみのあるダーク
    static let background = Color(hex: 0x151311)
    /// カードなど一段浮いた面
    static let surface = Color(hex: 0x1E1B18)
    /// さらに一段浮いた面(行アイテムなど)
    static let surfaceRaised = Color(hex: 0x262220)

    /// ヒーローイラスト: 深い夜の海のグラデーション
    static let seaDeep = Color(hex: 0x0D2B28)
    static let seaShallow = Color(hex: 0x1A3D36)

    /// 月・光。暖色寄りのオフホワイト
    static let moonGlow = Color(hex: 0xF2EDE1)

    /// 船体・帆・島のロープリ配色
    static let hullTan = Color(hex: 0xC9B183)
    static let hullShadow = Color(hex: 0xA89468)

    /// アクセント。差し色として最小限に使う
    static let accent = Color(hex: 0xD97A41)

    /// テキスト
    static let textPrimary = Color(hex: 0xF2EDE1)
    static let textSecondary = Color(hex: 0x9C948A)

    /// 機能カテゴリ用タイル配色(彩度低め)
    static let tileIndigo = Color(hex: 0x4A4661)     // くすんだ紺紫
    static let tileTerracotta = Color(hex: 0xB06A55) // テラコッタ/サーモン
    static let tileCharcoal = Color(hex: 0x3A3A3C)   // チャコールグレー
    static let tileMustard = Color(hex: 0xB39146)    // マスタードイエロー

    /// 角丸・レイアウト定数
    static let cornerLarge: CGFloat = 22
    static let cornerMedium: CGFloat = 16
}
