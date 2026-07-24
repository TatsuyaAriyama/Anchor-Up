import SwiftUI

/// 設定画面。まずは毎朝のリマインド通知を設定できる。
struct SettingsView: View {
    @ObservedObject var store: AnchorStore
    @ObservedObject var notifications: NotificationManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                AnchorTheme.background.ignoresSafeArea()

                List {
                    Section {
                        Toggle(isOn: Binding(
                            get: { notifications.isEnabled },
                            set: { notifications.setEnabled($0, itemCount: store.totalItemCount) }
                        )) {
                            Label("毎朝リマインド", systemImage: "bell.badge")
                                .foregroundStyle(AnchorTheme.textPrimary)
                        }
                        .tint(AnchorTheme.accent)
                        .listRowBackground(AnchorTheme.surface)

                        if notifications.isEnabled {
                            DatePicker(
                                selection: Binding(
                                    get: { notifications.reminderDate },
                                    set: { newDate in
                                        let c = Calendar.current.dateComponents([.hour, .minute], from: newDate)
                                        notifications.updateTime(hour: c.hour ?? 7, minute: c.minute ?? 30, itemCount: store.totalItemCount)
                                    }
                                ),
                                displayedComponents: .hourAndMinute
                            ) {
                                Label("時刻", systemImage: "clock")
                                    .foregroundStyle(AnchorTheme.textPrimary)
                            }
                            .tint(AnchorTheme.accent)
                            .listRowBackground(AnchorTheme.surface)
                        }
                    } header: {
                        Text("通知")
                            .foregroundStyle(AnchorTheme.textSecondary)
                    } footer: {
                        Text(footerText)
                            .foregroundStyle(AnchorTheme.textSecondary)
                    }

                    if notifications.authStatus == .denied {
                        Section {
                            Button {
                                openSystemSettings()
                            } label: {
                                Label("通知を許可する(設定を開く)", systemImage: "gear")
                                    .foregroundStyle(AnchorTheme.accent)
                            }
                            .listRowBackground(AnchorTheme.surface)
                        } footer: {
                            Text("通知が許可されていません。iOSの設定アプリからAnchor Upの通知をオンにしてください。")
                                .foregroundStyle(AnchorTheme.textSecondary)
                        }
                    }

                    Section {
                        NavigationLink {
                            WallpaperPickerView(store: store)
                        } label: {
                            HStack {
                                Label("背景", systemImage: "photo.on.rectangle.angled")
                                    .foregroundStyle(AnchorTheme.textPrimary)
                                Spacer()
                                Text(store.wallpaper.name)
                                    .foregroundStyle(AnchorTheme.textSecondary)
                            }
                        }
                        .listRowBackground(AnchorTheme.surface)
                    } header: {
                        Text("外観").foregroundStyle(AnchorTheme.textSecondary)
                    }

                    Section {
                        HStack {
                            Text("バージョン")
                                .foregroundStyle(AnchorTheme.textPrimary)
                            Spacer()
                            Text(appVersion)
                                .foregroundStyle(AnchorTheme.textSecondary)
                        }
                        .listRowBackground(AnchorTheme.surface)
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("設定")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完了") { dismiss() }
                        .fontWeight(.semibold)
                        .foregroundStyle(AnchorTheme.accent)
                }
            }
        }
        .onAppear { notifications.refreshAuthStatus() }
    }

    private var footerText: String {
        if notifications.isEnabled {
            return "毎日 \(notifications.timeText) に、持ち物リストの確認をお知らせします。"
        }
        return "オンにすると、毎朝きまった時刻に持ち物の確認をお知らせします。"
    }

    private var appVersion: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "-"
        return v
    }

    private func openSystemSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
}

#Preview {
    SettingsView(store: AnchorStore(), notifications: NotificationManager())
        .preferredColorScheme(.dark)
}
