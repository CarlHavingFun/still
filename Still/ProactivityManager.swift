import Foundation
import UserNotifications

final class ProactivityManager: NSObject {
    static let notificationID = "still_daily"
    private let center = UNUserNotificationCenter.current()

    override init() {
        super.init()
        center.delegate = self
    }

    func requestAuthorizationIfNeeded(completion: @escaping (Bool) -> Void) {
        center.getNotificationSettings { settings in
            if settings.authorizationStatus == .authorized {
                completion(true)
                return
            }
            self.center.requestAuthorization(options: [.alert]) { granted, _ in
                completion(granted)
            }
        }
    }

    func updateSchedule(for state: ProactivityState) {
        center.removePendingNotificationRequests(withIdentifiers: [Self.notificationID])
        guard state.enabled else { return }

        if let silenceUntil = state.silenceUntil, silenceUntil > Date() {
            return
        }

        let minutes = Self.notificationMinutes(quietStart: state.quietStartMinutes, quietEnd: state.quietEndMinutes)
        scheduleDailyNotification(atMinutes: minutes)
    }

    private func scheduleDailyNotification(atMinutes minutes: Int) {
        var components = DateComponents()
        components.hour = minutes / 60
        components.minute = minutes % 60

        let content = UNMutableNotificationContent()
        content.body = notificationBody()
        content.sound = nil

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: Self.notificationID, content: content, trigger: trigger)
        center.add(request)
    }

    private func notificationBody() -> String {
        let rawLanguage = UserDefaults.standard.string(forKey: "still.language") ?? AppLanguage.defaultRawValue
        return AppLanguage.resolve(rawLanguage) == .chinese ? "仍在这里。" : "Still here."
    }

    static func notificationMinutes(quietStart: Int, quietEnd: Int) -> Int {
        let defaultMinutes = 10 * 60
        if !isWithinQuietHours(minutes: defaultMinutes, quietStart: quietStart, quietEnd: quietEnd) {
            return defaultMinutes
        }
        let shifted = (quietEnd + 60) % (24 * 60)
        return shifted
    }

    static func isWithinQuietHours(minutes: Int, quietStart: Int, quietEnd: Int) -> Bool {
        if quietStart == quietEnd {
            return false
        }
        if quietStart < quietEnd {
            return minutes >= quietStart && minutes < quietEnd
        }
        return minutes >= quietStart || minutes < quietEnd
    }

    static func lastScheduledDate(now: Date, quietStart: Int, quietEnd: Int) -> Date {
        let minutes = notificationMinutes(quietStart: quietStart, quietEnd: quietEnd)
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: now)
        let scheduledToday = calendar.date(byAdding: .minute, value: minutes, to: today) ?? today
        if now >= scheduledToday {
            return scheduledToday
        }
        return calendar.date(byAdding: .day, value: -1, to: scheduledToday) ?? scheduledToday
    }
}

extension ProactivityManager: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([])
    }
}
