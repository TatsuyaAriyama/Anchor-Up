import SwiftUI

/// 乗船証をつくる画面。上のカードが選択に合わせて即座に変わる。
struct ProfileEditView: View {
    @ObservedObject var social: SocialService
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var colorIndex = 0
    @State private var symbol: ProfileSymbol = .anchor
    @State private var motto = ""
    @FocusState private var nameFocused: Bool

    private let symbolColumns = [GridItem(.adaptive(minimum: 56), spacing: 10)]

    var body: some View {
        NavigationStack {
            ZStack {
                AnchorTheme.background.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 26) {
                        // 選択が即座に反映される乗船証
                        ProfileCardView(
                            name: name, colorIndex: colorIndex, symbol: symbol,
                            motto: motto, code: social.myCode
                        )
                        .animation(.easeInOut(duration: 0.25), value: colorIndex)
                        .animation(.easeInOut(duration: 0.25), value: symbol)

                        field(title: "航海者の名前") {
                            TextField("例: ハルカ", text: $name)
                                .font(.anchorBody(17))
                                .foregroundStyle(AnchorTheme.textPrimary)
                                .focused($nameFocused)
                                .submitLabel(.done)
                                .padding(14)
                                .background(AnchorTheme.surface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }

                        field(title: "配色") { colorPicker }
                        field(title: "掲げるシンボル") { symbolPicker }

                        field(title: "掲げる言葉") {
                            VStack(alignment: .leading, spacing: 6) {
                                TextField("例: 忘れ物なき航海を。", text: $motto, axis: .vertical)
                                    .font(.anchorBody(16))
                                    .foregroundStyle(AnchorTheme.textPrimary)
                                    .lineLimit(1...2)
                                    .padding(14)
                                    .background(AnchorTheme.surface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                                Text("仲間の乗組員一覧に、この乗船証で表示されます。")
                                    .font(.anchorBody(11))
                                    .foregroundStyle(AnchorTheme.textSecondary)
                            }
                        }

                        Spacer(minLength: 10)
                    }
                    .padding(20)
                }
                .scrollIndicators(.hidden)
            }
            .navigationTitle("乗船証")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }
                        .foregroundStyle(AnchorTheme.textSecondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        Task {
                            await social.updateProfile(
                                name: name, colorIndex: colorIndex,
                                symbol: symbol, motto: motto
                            )
                        }
                        Haptics.success()
                        dismiss()
                    }
                    .fontWeight(.bold)
                    .foregroundStyle(canSave ? AnchorTheme.accent : AnchorTheme.textSecondary)
                    .disabled(!canSave)
                }
            }
        }
        .onAppear {
            name = social.myName
            colorIndex = social.myColorIndex
            symbol = social.mySymbol
            motto = social.myMotto
        }
    }

    private var canSave: Bool { !name.trimmingCharacters(in: .whitespaces).isEmpty }

    // MARK: - 部品

    private func field<C: View>(title: String, @ViewBuilder content: () -> C) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.anchorHeading(13))
                .foregroundStyle(AnchorTheme.textSecondary)
                .tracking(1)
            content()
        }
    }

    private var colorPicker: some View {
        HStack(spacing: 12) {
            ForEach(Array(CrewPalette.all.enumerated()), id: \.offset) { index, color in
                Circle()
                    .fill(color)
                    .frame(width: 40, height: 40)
                    .overlay {
                        if index == colorIndex {
                            Circle()
                                .strokeBorder(AnchorTheme.accent, lineWidth: 2.5)
                                .padding(-4)
                        }
                    }
                    .onTapGesture {
                        withAnimation(.easeOut(duration: 0.18)) { colorIndex = index }
                        Haptics.tap()
                    }
            }
            Spacer(minLength: 0)
        }
    }

    private var symbolPicker: some View {
        LazyVGrid(columns: symbolColumns, spacing: 10) {
            ForEach(ProfileSymbol.allCases) { s in
                ProfileSymbolView(
                    symbol: s, size: 24,
                    color: s == symbol ? CrewPalette.foreground(at: colorIndex) : AnchorTheme.textPrimary
                )
                .frame(width: 56, height: 56)
                .background {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(s == symbol ? CrewPalette.color(at: colorIndex) : AnchorTheme.surface)
                }
                .overlay {
                    if s == symbol {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(AnchorTheme.accent, lineWidth: 2)
                    }
                }
                .onTapGesture {
                    withAnimation(.easeOut(duration: 0.18)) { symbol = s }
                    Haptics.tap()
                }
            }
        }
    }
}

#Preview {
    ProfileEditView(social: SocialService())
        .preferredColorScheme(.dark)
}
