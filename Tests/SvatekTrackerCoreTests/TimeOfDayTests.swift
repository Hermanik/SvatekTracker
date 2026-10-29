import XCTest

@testable import SvatekTrackerCore

final class TimeOfDayTests: XCTestCase {
    func testMinutesRoundTrip() {
        let time = TimeOfDay(hour: 18, minute: 30)
        XCTAssertEqual(time.minutes, 1110)
        XCTAssertEqual(TimeOfDay(minutes: 1110), time)
    }

    func testStoredMinutesWrapIntoADay() {
        XCTAssertEqual(TimeOfDay(minutes: 1440 + 61), TimeOfDay(hour: 1, minute: 1))
        XCTAssertEqual(TimeOfDay(minutes: -1), TimeOfDay(hour: 23, minute: 59))
    }

    func testOrdering() {
        XCTAssertLessThan(TimeOfDay(hour: 8, minute: 59), TimeOfDay(hour: 9))
        XCTAssertLessThan(TimeOfDay(hour: 9), TimeOfDay(hour: 18))
    }

    func testFromDateUsesTheGivenCalendar() {
        var prague = Calendar(identifier: .gregorian)
        prague.timeZone = TimeZone(identifier: "Europe/Prague")!
        // 16:45 UTC is 17:45 in Prague in winter.
        let date = Date(timeIntervalSince1970: 1_798_735_500)
        XCTAssertEqual(TimeOfDay(date, in: prague), TimeOfDay(hour: 17, minute: 45))
    }
}
