/// A local notification to schedule, decided without touching the system.
public struct Reminder: Sendable {
    /// Stable per day and kind, so rescheduling replaces rather than duplicates.
    public let id: String
    public let day: Day
    public let time: TimeOfDay
    public let title: String
    public let body: String
}

public enum ReminderPlan {
    /// Out-of-the-box times; the user can move each reminder in the settings.
    public static let defaultDayBefore = TimeOfDay(hour: 18)
    public static let defaultOnTheDay = TimeOfDay(hour: 8)
    public static let defaultShopClosures = TimeOfDay(hour: 18)
    /// macOS keeps at most 64 pending notifications per app and silently drops
    /// the rest, so the plan keeps the soonest ones.
    public static let limit = 64

    /// Reminders for the next name day of each tracked name — the day before
    /// and/or on the day, names sharing a day combined — plus a heads-up the day
    /// before shops close for a holiday. Each kind fires at the time given and
    /// is off when that's nil. Only reminders later than `now` on `today` are
    /// returned, soonest first.
    public static func make(
        trackedNames: [String], dayBefore: TimeOfDay?, onTheDay: TimeOfDay?, shopClosures: TimeOfDay?,
        today: Day, now: TimeOfDay
    ) -> [Reminder] {
        let days = Set(NameDays.nextDates(of: trackedNames, from: today).map(\.day))

        var reminders: [Reminder] = []
        for day in days {
            // Calendar order, so a shared day reads as it's printed ("Šarlota a Zoe").
            let names = DayInfo(day).celebrated(by: trackedNames)
            let who = "\(CzechText.celebrates(names.count)) \(CzechText.list(names))"
            if let dayBefore {
                reminders.append(
                    Reminder(
                        id: "nameday-eve-\(day)", day: day.adding(days: -1), time: dayBefore,
                        title: "Zítra \(who)", body: "Nezapomeň popřát."))
            }
            if let onTheDay {
                reminders.append(
                    Reminder(
                        id: "nameday-\(day)", day: day, time: onTheDay, title: "Dnes \(who)",
                        body: "Nezapomeň popřát."))
            }
        }

        if let shopClosures {
            for holiday in Holidays.upcoming(from: today, days: 366) where holiday.shops != .open {
                // One heads-up per run of closed days: 25–26 December follow the
                // Christmas Eve noon closing, so only the 24th gets one.
                let eve = holiday.day.adding(days: -1)
                guard (Holidays.on(eve)?.shops ?? .open) == .open else { continue }
                let title =
                    holiday.shops == .closedFromNoon
                    ? "Zítra zavírají velké obchody ve 12:00" : "Zítra mají velké obchody zavřeno"
                reminders.append(
                    Reminder(
                        id: "shops-\(holiday.day)", day: eve, time: shopClosures, title: title,
                        body: "\(holiday.name) — platí pro obchody nad 200 m²."))
            }
        }

        let pending =
            reminders
            .filter { ($0.day, $0.time) > (today, now) }
            .sorted { ($0.day, $0.time, $0.id) < ($1.day, $1.time, $1.id) }
        return Array(pending.prefix(limit))
    }
}
