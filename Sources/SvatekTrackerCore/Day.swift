import Foundation

/// A calendar date without a time or time zone. Name days and holidays are
/// whole days, so keeping them as plain year/month/day values sidesteps DST and
/// time-zone traps; only `init(_:in:)` touches the user's local calendar.
public struct Day: Hashable, Comparable, Sendable, CustomStringConvertible {
    public let year: Int
    public let month: Int
    public let day: Int

    /// The caller guarantees the date exists — use `isValid` for computed ones
    /// such as 29 February.
    public init(year: Int, month: Int, day: Int) {
        precondition(Day.isValid(year: year, month: month, day: day), "invalid date \(year)-\(month)-\(day)")
        self.year = year
        self.month = month
        self.day = day
    }

    /// The local calendar day `date` falls on.
    public init(_ date: Date, in calendar: Calendar = .current) {
        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        self.init(year: parts.year!, month: parts.month!, day: parts.day!)
    }

    public static func today(in calendar: Calendar = .current) -> Day { Day(Date(), in: calendar) }

    public static func isValid(year: Int, month: Int, day: Int) -> Bool {
        DateComponents(calendar: utc, year: year, month: month, day: day).isValidDate
    }

    public func adding(days: Int) -> Day {
        Day(Day.utc.date(byAdding: .day, value: days, to: utcDate)!, in: Day.utc)
    }

    /// Whole days from `self` to `other`; negative when `other` is earlier.
    public func days(until other: Day) -> Int {
        Day.utc.dateComponents([.day], from: utcDate, to: other.utcDate).day!
    }

    /// 1 = Sunday … 7 = Saturday (the Foundation convention).
    public var weekday: Int { Day.utc.component(.weekday, from: utcDate) }

    public var isWeekend: Bool { weekday == 1 || weekday == 7 }

    public var description: String { String(format: "%04d-%02d-%02d", year, month, day) }

    public static func < (lhs: Day, rhs: Day) -> Bool {
        (lhs.year, lhs.month, lhs.day) < (rhs.year, rhs.month, rhs.day)
    }

    /// Plain date arithmetic runs in UTC, where every day is exactly 24 hours.
    private static let utc: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }()

    private var utcDate: Date {
        Day.utc.date(from: DateComponents(year: year, month: month, day: day))!
    }
}
