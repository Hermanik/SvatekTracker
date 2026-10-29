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
    /// Name-day reminders for tracked names: the evening before, the morning of.
    @Published var remindEveningBefore: Bool { didSet { save(remindEveningBefore, as: Keys.eveningBefore) } }
    @Published var remindMorningOf: Bool { didSet { save(remindMorningOf, as: Keys.morningOf) } }
    /// Evening heads-up before a holiday closes large shops.
    @Published var remindShopClosures: Bool { didSet { save(remindShopClosures, as: Keys.shopClosures) } }
    /// Today's names next to the menu bar icon; off leaves just the icon.
    @Published var showNamesInMenuBar: Bool {
        didSet { defaults.set(showNamesInMenuBar, forKey: Keys.showNames) }
    }
    /// The user turned notifications off for the app in System Settings.
    @Published private(set) var notificationsDenied = false

    private let defaults = UserDefaults.standard
    private let reminders = Reminders()
    private var subscriptions = Set<AnyCancellable>()

    private enum Keys {
        static let trackedNames = "trackedNames"
        static let eveningBefore = "remindEveningBefore"
        static let morningOf = "remindMorningOf"
        static let shopClosures = "remindShopClosures"
        static let showNames = "showNamesInMenuBar"
    }

    init() {
        defaults.register(defaults: [Keys.eveningBefore: true, Keys.morningOf: true, Keys.showNames: true])
        trackedNames = defaults.stringArray(forKey: Keys.trackedNames) ?? []
        remindEveningBefore = defaults.bool(forKey: Keys.eveningBefore)
        remindMorningOf = defaults.bool(forKey: Keys.morningOf)
        remindShopClosures = defaults.bool(forKey: Keys.shopClosures)
        showNamesInMenuBar = defaults.bool(forKey: Keys.showNames)

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

    /// Persists a reminder setting and reschedules with it.
    private func save(_ value: Bool, as key: String) {
        defaults.set(value, forKey: key)
        scheduleReminders()
    }

    private func scheduleReminders() {
        let hour = Calendar.current.component(.hour, from: Date())
        let plan = ReminderPlan.make(
            trackedNames: trackedNames, eveningBefore: remindEveningBefore, morningOf: remindMorningOf,
            shopClosures: remindShopClosures, today: today, hour: hour)
        reminders.schedule(plan) { [weak self] allowed in self?.notificationsDenied = !allowed }
    }
}
