import UIKit

/// 触覚フィードバックの薄いラッパー。操作に手応えを添える。
enum Haptics {
    static func tap() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    static func soft() {
        UIImpactFeedbackGenerator(style: .soft).impactOccurred(intensity: 0.7)
    }

    /// 舵輪のデテント(カチッという節度感)
    static func detent() {
        UISelectionFeedbackGenerator().selectionChanged()
    }
}
