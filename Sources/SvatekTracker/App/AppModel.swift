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
    /// Name-day reminders for tracked names: the day before, on the day.
    @Published var remindDayBefore: Bool { didSet { save(remindDayBefore, as: Keys.dayBefore) } }
    @Published var remindOnTheDay: Bool { didSet { save(remindOnTheDay, as: Keys.onTheDay) } }
    /// Heads-up the day before a holiday closes large shops.
    @Published var remindShopClosures: Bool { didSet { save(remindShopClosures, as: Keys.shopClosures) } }
    /// When each reminder fires; kept while it's off, so switching back on
    /// restores the user's time.
    @Published var dayBeforeTime: TimeOfDay { didSet { save(dayBeforeTime.minutes, as: Keys.dayBeforeTime) } }
    @Published var onTheDayTime: TimeOfDay { didSet { save(onTheDayTime.minutes, as: Keys.onTheDayTime) } }
    @Published var shopClosuresTime: TimeOfDay {
        didSet { save(shopClosuresTime.minutes, as: Keys.shopClosuresTime) }
    }
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
        // Named before the times became adjustable; stored, so they stay.
        static let dayBefore = "remindEveningBefore"
        static let onTheDay = "remindMorningOf"
        static let shopClosures = "remindShopClosures"
        static let dayBeforeTime = "dayBeforeMinutes"
        static let onTheDayTime = "onTheDayMinutes"
        static let shopClosuresTime = "shopClosuresMinutes"
        static let showNames = "showNamesInMenuBar"
    }

    init() {
        defaults.register(defaults: [
            Keys.dayBefore: true, Keys.onTheDay: true, Keys.showNames: true,
            Keys.dayBeforeTime: ReminderPlan.defaultDayBefore.minutes,
            Keys.onTheDayTime: ReminderPlan.defaultOnTheDay.minutes,
            Keys.shopClosuresTime: ReminderPlan.defaultShopClosures.minutes,
        ])
        trackedNames = defaults.stringArray(forKey: Keys.trackedNames) ?? []
        remindDayBefore = defaults.bool(forKey: Keys.dayBefore)
        remindOnTheDay = defaults.bool(forKey: Keys.onTheDay)
        remindShopClosures = defaults.bool(forKey: Keys.shopClosures)
        dayBeforeTime = TimeOfDay(minutes: defaults.integer(forKey: Keys.dayBeforeTime))
        onTheDayTime = TimeOfDay(minutes: defaults.integer(forKey: Keys.onTheDayTime))
        shopClosuresTime = TimeOfDay(minutes: defaults.integer(forKey: Keys.shopClosuresTime))
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
    private func save(_ value: Any, as key: String) {
        defaults.set(value, forKey: key)
        scheduleReminders()
    }

    private func scheduleReminders() {
        let plan = ReminderPlan.make(
            trackedNames: trackedNames,
            dayBefore: remindDayBefore ? dayBeforeTime : nil,
            onTheDay: remindOnTheDay ? onTheDayTime : nil,
            shopClosures: remindShopClosures ? shopClosuresTime : nil,
            today: today, now: TimeOfDay(Date()))
        reminders.schedule(plan) { [weak self] allowed in self?.notificationsDenied = !allowed }
    }
}
