import UserNotifications

enum NotificationService {
    static let center = UNUserNotificationCenter.current()
    static let dailyStreakId = "daily_streak_reminder"

    static let quotes: [String] = [
        "Small daily wins build big change.",
        "Don’t break the chain.",
        "Consistency beats intensity.",
        "One step today beats none.",
        "Habits compound. Keep going."
    ]

    static func requestAuthorization() async -> UNAuthorizationStatus {
        let settings = await center.notificationSettings()
        switch settings.authorizationStatus {
            case .notDetermined:
            do {
                let granted = try await center.requestAuthorization(options: [.alert, .badge, .sound])
                return granted ? .authorized : .denied
            } catch {
                return .denied
            }
        default:
            return settings.authorizationStatus
        }
    }

    static func scheduleDailyStreak(hour: Int, minute: Int, enabled: Bool) async {
        await cancelDailyStreak()

        guard enabled else { return }

        let content = UNMutableNotificationContent()
        content.title = "Keep your streak 🔥"
        content.body  = quotes.randomElement() ?? "Keep going!"
        content.sound = .default

        var dateComponent = DateComponents()
        dateComponent.hour = hour
        dateComponent.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponent, repeats: true)
        let req = UNNotificationRequest(identifier: dailyStreakId, content: content, trigger: trigger)
        do {
            try await center.add(req)
        } catch { }
    }

    static func cancelDailyStreak() async {
        center.removePendingNotificationRequests(withIdentifiers: [dailyStreakId])
    }

    static func fireTest() async {
        let content = UNMutableNotificationContent()
        content.title = "Test Notification"
        content.body = quotes.randomElement() ?? "Keep going!"
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        do {
            try await center.add(request)
        } catch { }
    }
}
