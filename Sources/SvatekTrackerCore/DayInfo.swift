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

    /// The day's names that are in `tracked`, in calendar order.
    public func celebrated(by tracked: [String]) -> [String] {
        names.filter(tracked.contains)
    }
}
