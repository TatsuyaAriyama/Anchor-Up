import SwiftUI

/// 友達とつながる画面。自分の招待コードを渡し、友達のコードで連携する。
struct ConnectView: View {
    @ObservedObject var social: SocialService
    @Environment(\.dismiss) private var dismiss

    @State private var codeInput = ""
    @State private var showingProfile = false
    @State private var message: (text: String, ok: Bool)?
    @State private var working = false
    @FocusState private var codeFocused: Bool

    var body: some View {
        NavigationStack {
            ZStack {
                AnchorTheme.background.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        myCardSection
                        myCodeCard
                        joinCard
                    }
                    .padding(20)
                }
                .scrollIndicators(.hidden)
            }
            .navigationTitle("友達とつながる")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完了") { dismiss() }
                        .fontWeight(.semibold)
                        .foregroundStyle(AnchorTheme.accent)
                }
            }
        }
        .sheet(isPresented: $showingProfile) {
            ProfileEditView(social: social)
        }
    }

    // MARK: - 自分の乗船証

    private var myCardSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("あなたの乗船証")
                .font(.anchorHeading(13))
                .foregroundStyle(AnchorTheme.textSecondary)

            Button {
                Haptics.tap()
                showingProfile = true
            } label: {
                ProfileCardView(
                    name: social.myName, colorIndex: social.myColorIndex,
                    symbol: social.mySymbol, motto: social.myMotto, code: nil
                )
            }
            .buttonStyle(.plain)

            Text("タップして名前・配色・シンボルを整えられます。この姿で友達に表示されます。")
                .font(.anchorBody(11))
                .foregroundStyle(AnchorTheme.textSecondary)
        }
    }

    // MARK: - 自分のコード

    private var myCodeCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("あなたの招待コード")
                .font(.anchorHeading(13))
                .foregroundStyle(AnchorTheme.textSecondary)

            HStack {
                Text(social.myCode.isEmpty ? "······" : spacedCode(social.myCode))
                    .font(.anchorDisplay(30, weight: .bold))
                    .foregroundStyle(AnchorTheme.textPrimary)
                    .tracking(4)
                Spacer()
                ShareLink(item: shareText) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.anchorHeading(18))
                        .foregroundStyle(AnchorTheme.accent)
                        .frame(width: 44, height: 44)
                }
                Button {
                    UIPasteboard.general.string = social.myCode
                    Haptics.tap()
                    show("コピーしました", ok: true)
                } label: {
                    Image(systemName: "doc.on.doc")
                        .font(.anchorHeading(17))
                        .foregroundStyle(AnchorTheme.accent)
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.plain)
            }
            .padding(16)
            .background(AnchorTheme.surface, in: RoundedRectangle(cornerRadius: AnchorTheme.cornerMedium, style: .continuous))

            Text("このコードを友達に渡すと、お互いの航海図に予定が並ぶようになります。")
                .font(.anchorBody(11))
                .foregroundStyle(AnchorTheme.textSecondary)
        }
    }

    // MARK: - 友達のコードで参加

    private var joinCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("友達のコードを入力")
                .font(.anchorHeading(13))
                .foregroundStyle(AnchorTheme.textSecondary)

            HStack(spacing: 10) {
                TextField("6文字のコード", text: $codeInput)
                    .font(.anchorDisplay(20, weight: .semibold))
                    .foregroundStyle(AnchorTheme.textPrimary)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
                    .focused($codeFocused)
                    .tracking(3)
                    .padding(14)
                    .background(AnchorTheme.surface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .onChange(of: codeInput) { _, v in
                        codeInput = String(v.uppercased().prefix(6))
                    }

                Button(action: connect) {
                    if working {
                        ProgressView().tint(AnchorTheme.seaDeep)
                            .frame(width: 64, height: 50)
                    } else {
                        Text("連携")
                            .font(.anchorHeading(15))
                            .foregroundStyle(AnchorTheme.seaDeep)
                            .frame(width: 64, height: 50)
                    }
                }
                .background(codeInput.count == 6 ? AnchorTheme.accent : AnchorTheme.surfaceRaised,
                            in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .buttonStyle(.plain)
                .disabled(codeInput.count != 6 || working)
            }

            if let message {
                Label(message.text, systemImage: message.ok ? "checkmark.circle" : "exclamationmark.circle")
                    .font(.anchorBody(12))
                    .foregroundStyle(message.ok ? AnchorTheme.seaShallow : AnchorTheme.tileTerracotta)
            }

            // 連携済みの仲間
            if !social.friends.isEmpty {
                Text("つながっている仲間")
                    .font(.anchorHeading(13))
                    .foregroundStyle(AnchorTheme.textSecondary)
                    .padding(.top, 8)
                VStack(spacing: 8) {
                    ForEach(social.friends) { friend in
                        HStack(spacing: 12) {
                            ZStack {
                                Circle().fill(friend.color)
                                Text(friend.initial)
                                    .font(.anchorHeading(16))
                                    .foregroundStyle(AnchorTheme.textPrimary)
                            }
                            .frame(width: 40, height: 40)
                            Text(friend.name)
                                .font(.anchorHeading(15))
                                .foregroundStyle(AnchorTheme.textPrimary)
                            Spacer()
                            Image(systemName: "link")
                                .font(.anchorBody(13))
                                .foregroundStyle(AnchorTheme.seaShallow)
                        }
                        .padding(14)
                        .background(AnchorTheme.surface, in: RoundedRectangle(cornerRadius: AnchorTheme.cornerMedium, style: .continuous))
                    }
                }
            }
        }
    }

    // MARK: -

    private var shareText: String {
        "Anchor Up でつながろう！ わたしの招待コードは 「\(social.myCode)」 です。"
    }

    private func spacedCode(_ code: String) -> String {
        code.map(String.init).joined(separator: " ")
    }

    private func show(_ text: String, ok: Bool) {
        withAnimation { message = (text, ok) }
    }

    private func connect() {
        codeFocused = false
        working = true
        Task {
            let error = await social.connect(code: codeInput)
            working = false
            if let error {
                show(error, ok: false)
                Haptics.tap()
            } else {
                show("連携しました", ok: true)
                codeInput = ""
                Haptics.success()
            }
        }
    }
}

#Preview {
    ConnectView(social: SocialService())
        .preferredColorScheme(.dark)
}
