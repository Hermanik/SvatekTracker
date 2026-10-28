import XCTest

@testable import SvatekTrackerCore

final class HolidaysTests: XCTestCase {
    func testEasterSunday() {
        let known: [(Int, Int, Int)] = [
            (2019, 4, 21), (2024, 3, 31), (2025, 4, 20), (2026, 4, 5), (2027, 3, 28), (2038, 4, 25),
        ]
        for (year, month, day) in known {
            XCTAssertEqual(Holidays.easterSunday(year), Day(year: year, month: month, day: day), "\(year)")
        }
    }

    func testThirteenHolidaysOnDistinctDaysInDateOrder() {
        for year in 2000...2100 {
            let days = Holidays.all(in: year).map(\.day)
            XCTAssertEqual(days.count, 13)
            XCTAssertEqual(days, days.sorted(), "\(year)")
            XCTAssertEqual(Set(days).count, 13, "\(year): two holidays share a day")
        }
    }

    func testEasterHolidays2026() {
        let names = Dictionary(uniqueKeysWithValues: Holidays.all(in: 2026).map { ($0.name, $0.day) })
        XCTAssertEqual(names["Velký pátek"], Day(year: 2026, month: 4, day: 3))
        XCTAssertEqual(names["Velikonoční pondělí"], Day(year: 2026, month: 4, day: 6))
    }

    func testShopClosures() {
        let closed = Holidays.all(in: 2026).filter { $0.shops == .closed }.map { "\($0.day.day). \($0.day.month)." }
        XCTAssertEqual(closed, ["1. 1.", "6. 4.", "8. 5.", "28. 9.", "28. 10.", "25. 12.", "26. 12."])
        XCTAssertEqual(Holidays.on(Day(year: 2026, month: 12, day: 24))?.shops, .closedFromNoon)
        XCTAssertEqual(Holidays.on(Day(year: 2026, month: 5, day: 1))?.shops, .open)
    }

    func testOnDay() {
        XCTAssertEqual(
            Holidays.on(Day(year: 2026, month: 10, day: 28))?.name, "Den vzniku samostatného československého státu")
        XCTAssertNil(Holidays.on(Day(year: 2026, month: 10, day: 29)))
    }

    func testUpcomingWindowIsHalfOpenAndCrossesYears() {
        let today = Day(year: 2026, month: 10, day: 28)
        let year = Holidays.upcoming(from: today, days: 365)
        XCTAssertEqual(year.first?.day, today)
        XCTAssertEqual(year.count, 13)  // 28 October 2027 falls just outside
        XCTAssertEqual(
            Holidays.upcoming(from: today, days: 30).map(\.shortName), ["Vznik Československa", "17. listopad"])
    }
}
