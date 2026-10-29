import XCTest

@testable import SvatekTrackerCore

final class NameDaysTests: XCTestCase {
    func testTableHasOneEntryPerDayOfALeapYear() {
        XCTAssertEqual(NameDays.table.map(\.count), [31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31])
    }

    func testEveryDayHasATitle() {
        var day = Day(year: 2028, month: 1, day: 1)
        while day.year == 2028 {
            XCTAssertFalse(DayInfo(day).title.isEmpty, "\(day) has neither a name, a holiday, nor a note")
            day = day.adding(days: 1)
        }
    }

    func testLookup() {
        XCTAssertEqual(NameDays.names(on: Day(year: 2026, month: 10, day: 27)), ["Šarlota", "Zoe"])
        XCTAssertEqual(NameDays.names(on: Day(year: 2026, month: 6, day: 24)), ["Jan"])
        XCTAssertEqual(NameDays.names(on: Day(year: 2026, month: 10, day: 28)), [])
        XCTAssertEqual(NameDays.note(on: Day(year: 2026, month: 1, day: 6)), "Tři králové")
    }

    func testNextDateWrapsIntoNextYear() {
        let today = Day(year: 2026, month: 10, day: 28)
        XCTAssertEqual(NameDays.nextDate(of: "Silvie", from: today), Day(year: 2026, month: 10, day: 29))
        XCTAssertEqual(NameDays.nextDate(of: "Jana", from: today), Day(year: 2027, month: 5, day: 24))
        XCTAssertEqual(NameDays.nextDate(of: "Šarlota", from: today), Day(year: 2027, month: 10, day: 27))
        XCTAssertNil(NameDays.nextDate(of: "Kevin", from: today))
    }

    func testNextDateIncludesStartDay() {
        let day = Day(year: 2026, month: 5, day: 24)
        XCTAssertEqual(NameDays.nextDate(of: "Jana", from: day), day)
    }

    func testNameWithTwoDaysPicksTheSooner() {
        // Petr is both 22 February and 29 June (with Pavel).
        XCTAssertEqual(
            NameDays.nextDate(of: "Petr", from: Day(year: 2026, month: 3, day: 1)), Day(year: 2026, month: 6, day: 29))
        XCTAssertEqual(
            NameDays.nextDate(of: "Petr", from: Day(year: 2026, month: 7, day: 1)), Day(year: 2027, month: 2, day: 22))
    }

    func testLeapDayNameWaitsForALeapYear() {
        XCTAssertEqual(
            NameDays.nextDate(of: "Horymír", from: Day(year: 2026, month: 10, day: 28)),
            Day(year: 2028, month: 2, day: 29))
    }

    func testNextDatesSortsSoonestFirstAndDropsUnknown() {
        let upcoming = NameDays.nextDates(
            of: ["Jana", "Kevin", "Zoe", "Šarlota", "Silvie"], from: Day(year: 2026, month: 10, day: 28))
        XCTAssertEqual(upcoming.map(\.name), ["Silvie", "Jana", "Šarlota", "Zoe"])
        XCTAssertEqual(upcoming.first?.day, Day(year: 2026, month: 10, day: 29))
    }

    func testCelebratedKeepsCalendarOrder() {
        let info = DayInfo(Day(year: 2026, month: 10, day: 27))
        XCTAssertEqual(info.celebrated(by: ["Zoe", "Šarlota"]), ["Šarlota", "Zoe"])
        XCTAssertEqual(info.celebrated(by: ["Jana"]), [])
    }

    func testMenuBarItem() {
        let ordinary = DayInfo(Day(year: 2026, month: 10, day: 27))
        XCTAssertEqual(ordinary.menuBarItem(tracked: [], showNames: true).title, "Šarlota a Zoe")
        XCTAssertNil(ordinary.menuBarItem(tracked: [], showNames: true).badge)
        // Without the names the item still needs something to show.
        XCTAssertEqual(ordinary.menuBarItem(tracked: [], showNames: false).title, "")
        XCTAssertEqual(ordinary.menuBarItem(tracked: [], showNames: false).badge, .calendar)
        // 17 November is both Mahulena's day and a public holiday; the star wins.
        let holiday = DayInfo(Day(year: 2026, month: 11, day: 17))
        XCTAssertEqual(holiday.menuBarItem(tracked: [], showNames: true).badge, .holiday)
        XCTAssertEqual(holiday.menuBarItem(tracked: ["Mahulena"], showNames: false).badge, .tracked)
    }

    func testSearchIgnoresCaseAndDiacritics() {
        XCTAssertEqual(NameDays.search("sarl"), ["Šarlota"])
        XCTAssertEqual(NameDays.search("  ČESTMÍR "), ["Čestmír"])
        XCTAssertEqual(NameDays.search(""), [])
        XCTAssertEqual(NameDays.search("xyz"), [])
    }

    func testSearchIsAlphabeticalWithExactMatchFirst() {
        XCTAssertEqual(NameDays.search("jan"), ["Jan", "Jana"])
        XCTAssertEqual(NameDays.search("iva"), ["Iva", "Ivan", "Ivana"])
        // Czech collation: "Č" after "C", "Ch" after "H".
        XCTAssertEqual(NameDays.search("c").prefix(3), ["Cecílie", "Ctibor", "Ctirad"])
    }

    func testSearchReturnsEachNameOnce() {
        XCTAssertEqual(NameDays.search("petr"), ["Petr", "Petra"])
    }
}
