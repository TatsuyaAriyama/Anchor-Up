import SwiftUI
import UserNotifications

/// 毎朝のリマインド通知を管理する。設定はUserDefaultsに永続化する。
@MainActor
final class NotificationManager: ObservableObject {
    @Published private(set) var isEnabled: Bool
    @Published private(set) var hour: Int
    @Published private(set) var minute: Int
    /// 通知許可の状態
    @Published var authStatus: UNAuthorizationStatus = .notDetermined

    private let enabledKey = "anchorup.reminder.enabled"
    private let hourKey = "anchorup.reminder.hour"
    private let minuteKey = "anchorup.reminder.minute"
    private let requestID = "anchorup.dailyReminder"

    init() {
        let d = UserDefaults.standard
        isEnabled = d.bool(forKey: enabledKey)
        if d.object(forKey: hourKey) == nil {
            hour = 7
            minute = 30
        } else {
            hour = d.integer(forKey: hourKey)
            minute = d.integer(forKey: minuteKey)
        }
    }

    /// DatePicker連携用。今日の日付に時刻だけ載せて返す。
    var reminderDate: Date {
        Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: Date()) ?? Date()
    }

    var timeText: String {
        String(format: "%02d:%02d", hour, minute)
    }

    // MARK: - 状態更新

    func refreshAuthStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            Task { @MainActor in self.authStatus = settings.authorizationStatus }
        }
    }

    /// リマインドのオン/オフ。オンなら許可を要求し、許可されたらスケジュールする。
    func setEnabled(_ on: Bool, itemCount: Int) {
        if on {
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
                Task { @MainActor in
                    self.refreshAuthStatus()
                    if granted {
                        self.persistEnabled(true)
                        self.schedule(itemCount: itemCount)
                    } else {
                        self.persistEnabled(false)
                    }
                }
            }
        } else {
            persistEnabled(false)
            cancel()
        }
    }

    func updateTime(hour: Int, minute: Int, itemCount: Int) {
        self.hour = hour
        self.minute = minute
        UserDefaults.standard.set(hour, forKey: hourKey)
        UserDefaults.standard.set(minute, forKey: minuteKey)
        if isEnabled { schedule(itemCount: itemCount) }
    }

    /// アプリ起動時などに、有効なら最新の内容で組み直す。
    func rescheduleIfEnabled(itemCount: Int) {
        guard isEnabled else { return }
        schedule(itemCount: itemCount)
    }

    // MARK: - スケジュール

    private func schedule(itemCount: Int) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [requestID])

        let content = UNMutableNotificationContent()
        content.title = "持ち物リスト"
        content.body = itemCount > 0
            ? "出発前に持ち物を確認しよう。"
            : "持ち物を準備しよう。"
        content.sound = .default

        var comps = DateComponents()
        comps.hour = hour
        comps.minute = minute
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)

        center.add(UNNotificationRequest(identifier: requestID, content: content, trigger: trigger))
    }

    private func cancel() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [requestID])
    }

    private func persistEnabled(_ value: Bool) {
        isEnabled = value
        UserDefaults.standard.set(value, forKey: enabledKey)
    }
}
