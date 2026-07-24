import SwiftUI

/// 持ち物の状態を表す信号旗風のインジケータ。タップで状態が進む。
struct StatusIndicator: View {
    let status: PackingStatus
    var size: CGFloat = 26

    var body: some View {
        ZStack {
            switch status {
            case .notStarted:
                Circle()
                    .strokeBorder(status.flagColor.opacity(0.9), lineWidth: 2)
            case .inProgress:
                Circle()
                    .strokeBorder(status.flagColor, lineWidth: 2)
                Circle()
                    .fill(status.flagColor)
                    .frame(width: size * 0.42, height: size * 0.42)
            case .done:
                Circle()
                    .fill(status.flagColor)
                Image(systemName: "checkmark")
                    .font(.system(size: size * 0.5, weight: .bold))
                    .foregroundStyle(AnchorTheme.moonGlow)
            }
        }
        .frame(width: size, height: size)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: status)
    }
}

#Preview {
    HStack(spacing: 16) {
        StatusIndicator(status: .notStarted)
        StatusIndicator(status: .inProgress)
        StatusIndicator(status: .done)
    }
    .padding()
    .background(AnchorTheme.background)
}
