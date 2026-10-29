import Foundation
import SvatekTrackerCore
import UserNotifications

/// Hands a `ReminderPlan` to the system as local notifications. The pending set
/// is rebuilt from scratch on every change — it's at most 64 requests, so that
/// beats diffing against what's already queued.
final class Reminders: NSObject, UNUserNotificationCenterDelegate {
    /// `UNUserNotificationCenter` traps outside an app bundle, so `swift run`
    /// builds run without reminders.
    private let center: UNUserNotificationCenter? =
        Bundle.main.bundleIdentifier == nil ? nil : .current()

    override init() {
        super.init()
        center?.delegate = self
    }

    /// Bumped by every `schedule` call; main thread only.
    private var generation = 0

    /// Replaces all pending reminders with `plan`. Call on the main thread. Asks
    /// for permission the first time there's something to schedule; `completion`
    /// gets whether notifications are allowed (true when there was nothing to
    /// ask for), on the main queue.
    func schedule(_ plan: [Reminder], completion: @escaping (Bool) -> Void) {
        guard let center else { return }
        generation += 1
        let current = generation
        guard !plan.isEmpty else {
            center.removeAllPendingNotificationRequests()
            completion(true)
            return
        }
        center.requestAuthorization(options: [.alert, .sound]) { granted, error in
            if let error {
                Log.reminders.error("authorization failed: \(error.localizedDescription, privacy: .public)")
            }
            DispatchQueue.main.async {
                // A newer plan arrived while this one waited for permission;
                // applying this one now would resurrect reminders it dropped.
                guard current == self.generation else { return }
                center.removeAllPendingNotificationRequests()
                if granted {
                    for reminder in plan { center.add(Self.request(for: reminder)) }
                    Log.reminders.info("scheduled \(plan.count) reminders")
                }
                completion(granted)
            }
        }
    }

    private static func request(for reminder: Reminder) -> UNNotificationRequest {
        let content = UNMutableNotificationContent()
        content.title = reminder.title
        content.body = reminder.body
        content.sound = .default
        let when = DateComponents(
            year: reminder.day.year, month: reminder.day.month, day: reminder.day.day, hour: reminder.time.hour,
            minute: reminder.time.minute)
        return UNNotificationRequest(
            identifier: reminder.id, content: content,
            trigger: UNCalendarNotificationTrigger(dateMatching: when, repeats: false))
    }

    /// Show banners even while the app is "active" — a menubar app always is.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter, willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }
}
