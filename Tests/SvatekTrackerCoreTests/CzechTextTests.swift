import XCTest

@testable import SvatekTrackerCore

final class CzechTextTests: XCTestCase {
    func testDates() {
        let day = Day(year: 2026, month: 10, day: 28)
        XCTAssertEqual(CzechText.longDate(day), "středa 28. října 2026")
        XCTAssertEqual(CzechText.shortDate(day), "st 28. 10.")
        XCTAssertEqual(CzechText.longDate(Day(year: 2027, month: 1, day: 3)), "neděle 3. ledna 2027")
    }

    func testRelative() {
        XCTAssertEqual(CzechText.relative(days: 0), "dnes")
        XCTAssertEqual(CzechText.relative(days: 1), "zítra")
        XCTAssertEqual(CzechText.relative(days: 2), "pozítří")
        XCTAssertEqual(CzechText.relative(days: 3), "za 3 dny")
        XCTAssertEqual(CzechText.relative(days: 5), "za 5 dní")
        XCTAssertEqual(CzechText.relative(days: 22), "za 22 dní")
    }

    func testList() {
        XCTAssertEqual(CzechText.list([]), "")
        XCTAssertEqual(CzechText.list(["Jana"]), "Jana")
        XCTAssertEqual(CzechText.list(["Petr", "Pavel"]), "Petr a Pavel")
        XCTAssertEqual(CzechText.list(["Jan", "Jana", "Petr"]), "Jan, Jana a Petr")
    }

    func testDayTitle() {
        XCTAssertEqual(DayInfo(Day(year: 2026, month: 10, day: 27)).title, "Šarlota a Zoe")
        XCTAssertEqual(DayInfo(Day(year: 2026, month: 10, day: 28)).title, "Vznik Československa")
        XCTAssertEqual(DayInfo(Day(year: 2026, month: 11, day: 2)).title, "Památka zesnulých")
        XCTAssertEqual(DayInfo(Day(year: 2026, month: 11, day: 17)).title, "Mahulena")
    }
}
