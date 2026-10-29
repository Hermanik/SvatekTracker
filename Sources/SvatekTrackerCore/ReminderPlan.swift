/// A local notification to schedule, decided without touching the system.
public struct Reminder: Sendable {
    /// Stable per day and kind, so rescheduling replaces rather than duplicates.
    public let id: String
    public let day: Day
    public let hour: Int
    public let title: String
    public let body: String
}

public enum ReminderPlan {
    public static let eveningHour = 18
    public static let morningHour = 8
    /// macOS keeps at most 64 pending notifications per app and silently drops
    /// the rest, so the plan keeps the soonest ones.
    public static let limit = 64

    /// Reminders for the next name day of each tracked name — the evening
    /// before and/or the morning of, names sharing a day combined — plus, when
    /// `shopClosures` is on, an evening heads-up before shops close for a
    /// holiday. Only reminders later than `hour` on `today` are returned,
    /// soonest first.
    public static func make(
        trackedNames: [String], eveningBefore: Bool, morningOf: Bool, shopClosures: Bool,
        today: Day, hour: Int
    ) -> [Reminder] {
        let days = Set(NameDays.nextDates(of: trackedNames, from: today).map(\.day))

        var reminders: [Reminder] = []
        for day in days {
            // Calendar order, so a shared day reads as it's printed ("Šarlota a Zoe").
            let names = DayInfo(day).celebrated(by: trackedNames)
            let who = "\(CzechText.celebrates(names.count)) \(CzechText.list(names))"
            if eveningBefore {
                reminders.append(
                    Reminder(
                        id: "nameday-eve-\(day)", day: day.adding(days: -1), hour: eveningHour,
                        title: "Zítra \(who)", body: "Nezapomeň popřát."))
            }
            if morningOf {
                reminders.append(
                    Reminder(
                        id: "nameday-\(day)", day: day, hour: morningHour, title: "Dnes \(who)",
                        body: "Nezapomeň popřát."))
            }
        }

        if shopClosures {
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
                        id: "shops-\(holiday.day)", day: eve, hour: eveningHour, title: title,
                        body: "\(holiday.name) — platí pro obchody nad 200 m²."))
            }
        }

        let pending =
            reminders
            .filter { ($0.day, $0.hour) > (today, hour) }
            .sorted { ($0.day, $0.hour, $0.id) < ($1.day, $1.hour, $1.id) }
        return Array(pending.prefix(limit))
    }
}
