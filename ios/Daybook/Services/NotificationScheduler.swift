import Foundation
import UserNotifications

/// Snapshot of what a habit reminder needs, so scheduling never touches SwiftData off the main actor.
struct ReminderPlan: Sendable {
    let habitID: UUID
    let habitName: String
    let weekdays: [Int]
    let minutes: Int
    let isShared: Bool
}

/// Local habit reminders via UserNotifications.
/// Permission is requested only when the user turns a reminder on (never on first launch).
final class NotificationScheduler: @unchecked Sendable {
    static let shared = NotificationScheduler()

    private let center = UNUserNotificationCenter.current()
    private let prefix = "habit-"

    func authorizationStatus() async -> UNAuthorizationStatus {
        await center.notificationSettings().authorizationStatus
    }

    /// Asks for permission if it hasn't been decided yet. Returns whether alerts are allowed.
    @discardableResult
    func requestAuthorizationIfNeeded() async -> Bool {
        let status = await authorizationStatus()
        switch status {
        case .authorized, .provisional, .ephemeral:
            return true
        case .denied:
            return false
        case .notDetermined:
            return (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
        @unknown default:
            return false
        }
    }

    /// Replaces all habit reminders with `plans`.
    /// Reminders that would land inside quiet hours are moved to the end of quiet hours.
    func reschedule(_ plans: [ReminderPlan], enabled: Bool, quietHours: (start: Int, end: Int)?) async {
        let pending = await center.pendingNotificationRequests()
        let ours = pending.map(\.identifier).filter { $0.hasPrefix(prefix) }
        center.removePendingNotificationRequests(withIdentifiers: ours)
        guard enabled else { return }
        let status = await authorizationStatus()
        guard status == .authorized || status == .provisional || status == .ephemeral else { return }

        for plan in plans {
            var minutes = plan.minutes
            if let quiet = quietHours, Self.isQuiet(minutes, start: quiet.start, end: quiet.end) {
                minutes = quiet.end
            }
            let content = UNMutableNotificationContent()
            content.title = plan.habitName
            content.body = plan.isShared ? "Your friends are on it too. A small check-in still counts." : "A gentle reminder. Even the tiny version counts."
            content.sound = .default
            content.threadIdentifier = "habit-reminders"

            let weekdays = plan.weekdays.isEmpty ? Array(1...7) : plan.weekdays
            for weekday in weekdays {
                var components = DateComponents()
                components.weekday = weekday
                components.hour = minutes / 60
                components.minute = minutes % 60
                let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
                let request = UNNotificationRequest(identifier: "\(prefix)\(plan.habitID.uuidString)-\(weekday)", content: content, trigger: trigger)
                try? await center.add(request)
            }
        }
    }

    func removeAll() {
        center.removeAllPendingNotificationRequests()
    }

    static func isQuiet(_ minutes: Int, start: Int, end: Int) -> Bool {
        if start <= end { return minutes >= start && minutes < end }
        return minutes >= start || minutes < end
    }
}
