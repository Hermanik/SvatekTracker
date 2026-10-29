/// Everything the calendar says about one day.
public struct DayInfo: Sendable {
    public let day: Day
    public let names: [String]
    public let note: String?
    public let holiday: Holiday?

    public init(_ day: Day) {
        self.day = day
        names = NameDays.names(on: day)
        note = NameDays.note(on: day)
        holiday = Holidays.on(day)
    }

    /// Menu-bar label: the names, else the holiday, else the calendar note.
    /// Every day of the year has one of the three.
    public var title: String {
        if !names.isEmpty { return CzechText.list(names) }
        return holiday?.shortName ?? note ?? ""
    }

    /// The symbol next to the menu bar title.
    public enum Badge: Sendable { case tracked, holiday, calendar }

    /// The menu bar item: the title (unless `showNames` is off) and a badge — a
    /// star when a tracked name celebrates, else a flag on public holidays.
    /// Without the title, a plain calendar keeps the item visible.
    public func menuBarItem(tracked: [String], showNames: Bool) -> (title: String, badge: Badge?) {
        let badge: Badge? =
            if !celebrated(by: tracked).isEmpty {
                .tracked
            } else if holiday != nil {
                .holiday
            } else {
                showNames ? nil : .calendar
            }
        return (showNames ? title : "", badge)
    }

    /// The day's names that are in `tracked`, in calendar order.
    public func celebrated(by tracked: [String]) -> [String] {
        names.filter(tracked.contains)
    }
}
