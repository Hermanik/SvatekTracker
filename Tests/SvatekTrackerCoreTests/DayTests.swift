import XCTest

@testable import SvatekTrackerCore

final class DayTests: XCTestCase {
    func testAddingCrossesMonthAndYearBoundaries() {
        XCTAssertEqual(Day(year: 2026, month: 12, day: 31).adding(days: 1), Day(year: 2027, month: 1, day: 1))
        XCTAssertEqual(Day(year: 2028, month: 2, day: 28).adding(days: 1), Day(year: 2028, month: 2, day: 29))
        XCTAssertEqual(Day(year: 2026, month: 3, day: 1).adding(days: -1), Day(year: 2026, month: 2, day: 28))
    }

    func testDaysUntilSpansTheDaylightSavingSwitch() {
        // 29 March 2026 is 23 hours long in Prague; Day arithmetic must not care.
        let start = Day(year: 2026, month: 3, day: 28)
        XCTAssertEqual(start.days(until: Day(year: 2026, month: 3, day: 30)), 2)
        XCTAssertEqual(start.days(until: Day(year: 2026, month: 3, day: 27)), -1)
    }

    func testValidity() {
        XCTAssertTrue(Day.isValid(year: 2028, month: 2, day: 29))
        XCTAssertFalse(Day.isValid(year: 2026, month: 2, day: 29))
        XCTAssertFalse(Day.isValid(year: 2026, month: 4, day: 31))
    }

    func testWeekday() {
        let wednesday = Day(year: 2026, month: 10, day: 28)
        XCTAssertEqual(wednesday.weekday, 4)
        XCTAssertFalse(wednesday.isWeekend)
        XCTAssertTrue(Day(year: 2026, month: 10, day: 31).isWeekend)
    }

    func testLocalDayUsesTheGivenTimeZone() {
        var prague = Calendar(identifier: .gregorian)
        prague.timeZone = TimeZone(identifier: "Europe/Prague")!
        // 23:30 UTC on 27 October is already the 28th in Prague.
        let date = ISO8601DateFormatter().date(from: "2026-10-27T23:30:00Z")!
        XCTAssertEqual(Day(date, in: prague), Day(year: 2026, month: 10, day: 28))
    }

    func testOrdering() {
        XCTAssertLessThan(Day(year: 2026, month: 12, day: 31), Day(year: 2027, month: 1, day: 1))
        XCTAssertLessThan(Day(year: 2026, month: 2, day: 9), Day(year: 2026, month: 2, day: 10))
    }
}
