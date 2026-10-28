import AppKit
import Combine
import SvatekTrackerCore

/// Today's date, the user's tracked names, and the reminder settings. Re-reads
/// the date at midnight, on wake, and on clock or time-zone changes, so the menu
/// bar never shows yesterday's name after the Mac sleeps through midnight.
@MainActor
final class AppModel: ObservableObject {
    @Published private(set) var today = Day.today()
    /// Calendar names the user wants reminders for, in the order added.
    @Published private(set) var trackedNames: [String]
    /// Evening heads-up before a holiday closes large shops.
    @Published var remindShopClosures: Bool {
        didSet {
            defaults.set(remindShopClosures, forKey: Keys.shopClosures)
            scheduleReminders()
        }
    }
    /// The user turned notifications off for the app in System Settings.
    @Published private(set) var notificationsDenied = false

    private let defaults = UserDefaults.standard
    private let reminders = Reminders()
    private var subscriptions = Set<AnyCancellable>()

    private enum Keys {
        static let trackedNames = "trackedNames"
        static let shopClosures = "remindShopClosures"
    }

    init() {
        trackedNames = defaults.stringArray(forKey: Keys.trackedNames) ?? []
        remindShopClosures = defaults.bool(forKey: Keys.shopClosures)

        let center = NotificationCenter.default
        Publishers.MergeMany(
            center.publisher(for: .NSCalendarDayChanged),
            center.publisher(for: .NSSystemClockDidChange),
            center.publisher(for: .NSSystemTimeZoneDidChange),
            NSWorkspace.shared.notificationCenter.publisher(for: NSWorkspace.didWakeNotification)
        )
        .receive(on: RunLoop.main)
        .sink { [weak self] _ in self?.refresh() }
        .store(in: &subscriptions)

        scheduleReminders()
    }

    /// Picks up a new day; cheap enough to call on every popover open too.
    func refresh() {
        let now = Day.today()
        guard now != today else { return }
        today = now
        scheduleReminders()
    }

    func isTracked(_ name: String) -> Bool { trackedNames.contains(name) }

    func toggleTracked(_ name: String) {
        if let index = trackedNames.firstIndex(of: name) {
            trackedNames.remove(at: index)
        } else {
            trackedNames.append(name)
        }
        defaults.set(trackedNames, forKey: Keys.trackedNames)
        scheduleReminders()
    }

    private func scheduleReminders() {
        let hour = Calendar.current.component(.hour, from: Date())
        let plan = ReminderPlan.make(
            trackedNames: trackedNames, shopClosures: remindShopClosures, today: today, hour: hour)
        reminders.schedule(plan) { [weak self] allowed in self?.notificationsDenied = !allowed }
    }
}
