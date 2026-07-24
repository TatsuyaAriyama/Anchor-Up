import SwiftUI

/// 背景(壁紙)を選ぶ画面。設定からプッシュして使う。
struct WallpaperPickerView: View {
    @ObservedObject var store: AnchorStore

    private let columns = [
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14),
    ]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(Wallpaper.allCases) { wp in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) { store.wallpaper = wp }
                        Haptics.tap()
                    } label: {
                        VStack(spacing: 8) {
                            WallpaperView(wallpaper: wp)
                                .frame(height: 168)
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .strokeBorder(
                                            store.wallpaper == wp ? AnchorTheme.accent : Color.white.opacity(0.06),
                                            lineWidth: store.wallpaper == wp ? 2.5 : 1
                                        )
                                )
                                .overlay(alignment: .topTrailing) {
                                    if store.wallpaper == wp {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.anchorBody(20))
                                            .foregroundStyle(AnchorTheme.accent)
                                            .background(Circle().fill(AnchorTheme.background).padding(2))
                                            .padding(8)
                                    }
                                }

                            Text(wp.name)
                                .font(.anchorHeading(14))
                                .foregroundStyle(store.wallpaper == wp ? AnchorTheme.textPrimary : AnchorTheme.textSecondary)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(20)
        }
        .scrollIndicators(.hidden)
        .background(AnchorTheme.background)
        .navigationTitle("背景")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        WallpaperPickerView(store: AnchorStore())
    }
    .preferredColorScheme(.dark)
}
