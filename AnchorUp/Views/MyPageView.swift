import SwiftUI

/// マイページ。設定やホームのカスタマイズへの導線と、ブランドの署名を置く。
struct MyPageView: View {
    @ObservedObject var store: AnchorStore
    @ObservedObject var notifications: NotificationManager

    @State private var showingSettings = false
    @State private var showingCustomize = false

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                row(icon: "slider.horizontal.3", title: "ホームのカスタマイズ",
                    detail: "盤面の並び・大きさ・表示") {
                    showingCustomize = true
                }
                row(icon: "bell.badge", title: "通知と設定",
                    detail: "毎朝リマインド・背景") {
                    showingSettings = true
                }

                Spacer(minLength: 60)

                // ブランドの署名
                VStack(spacing: 10) {
                    AnchorLogo(size: 30)
                    Text("Anchor Up")
                        .font(.anchorDisplay(18, weight: .bold))
                        .foregroundStyle(AnchorTheme.textPrimary)
                    Text("ver \(appVersion)")
                        .font(.anchorBody(11))
                        .foregroundStyle(AnchorTheme.textSecondary)
                }
                .padding(.bottom, 30)
            }
            .padding(.horizontal, 20)
            .padding(.top, 24)
            .padding(.bottom, 170) // 舵輪ぶんの余白
        }
        .scrollIndicators(.hidden)
        .sheet(isPresented: $showingSettings) {
            SettingsView(store: store, notifications: notifications)
        }
        .sheet(isPresented: $showingCustomize) {
            HomeCustomizeView(store: store)
        }
    }

    private func row(icon: String, title: String, detail: String, action: @escaping () -> Void) -> some View {
        Button {
            Haptics.tap()
            action()
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(AnchorTheme.hullTan.opacity(0.16))
                    Image(systemName: icon)
                        .font(.anchorBody(16))
                        .foregroundStyle(AnchorTheme.hullTan)
                }
                .frame(width: 44, height: 44)

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.anchorHeading(15))
                        .foregroundStyle(AnchorTheme.textPrimary)
                    Text(detail)
                        .font(.anchorBody(12))
                        .foregroundStyle(AnchorTheme.textSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.anchorHeading(12))
                    .foregroundStyle(AnchorTheme.textSecondary)
            }
            .padding(14)
            .background(AnchorTheme.surface, in: RoundedRectangle(cornerRadius: AnchorTheme.cornerMedium, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "-"
    }
}

#Preview {
    ZStack {
        AnchorTheme.background.ignoresSafeArea()
        MyPageView(store: AnchorStore(), notifications: NotificationManager())
    }
    .preferredColorScheme(.dark)
}
