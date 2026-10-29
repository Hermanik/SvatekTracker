import Foundation

/// A wall-clock time without a date, to the minute — when a reminder fires.
public struct TimeOfDay: Hashable, Comparable, Sendable {
    public let hour: Int
    public let minute: Int

    public init(hour: Int, minute: Int = 0) {
        precondition((0..<24).contains(hour) && (0..<60).contains(minute), "invalid time \(hour):\(minute)")
        self.hour = hour
        self.minute = minute
    }

    /// Minutes since midnight, wrapped into a single day so a stray stored
    /// value can't trap.
    public init(minutes: Int) {
        let wrapped = (minutes % 1440 + 1440) % 1440
        self.init(hour: wrapped / 60, minute: wrapped % 60)
    }

    /// The local wall-clock time of `date`.
    public init(_ date: Date, in calendar: Calendar = .current) {
        let parts = calendar.dateComponents([.hour, .minute], from: date)
        self.init(hour: parts.hour!, minute: parts.minute!)
    }

    /// Minutes since midnight — the form the settings store it in.
    public var minutes: Int { hour * 60 + minute }

    public static func < (lhs: TimeOfDay, rhs: TimeOfDay) -> Bool { lhs.minutes < rhs.minutes }
}
