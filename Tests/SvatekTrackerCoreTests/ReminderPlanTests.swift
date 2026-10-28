import XCTest

@testable import SvatekTrackerCore

final class ReminderPlanTests: XCTestCase {
    private let today = Day(year: 2026, month: 10, day: 28)

    func testEveningBeforeAndMorningOf() {
        let plan = ReminderPlan.make(trackedNames: ["Silvie"], shopClosures: false, today: today, hour: 10)
        XCTAssertEqual(plan.map(\.title), ["Zítra má svátek Silvie", "Dnes má svátek Silvie"])
        XCTAssertEqual(plan.map(\.day), [today, Day(year: 2026, month: 10, day: 29)])
        XCTAssertEqual(plan.map(\.hour), [18, 8])
    }

    func testPastRemindersAreDropped() {
        // At 19:00 the evening reminder for tomorrow has already gone by.
        let plan = ReminderPlan.make(trackedNames: ["Silvie"], shopClosures: false, today: today, hour: 19)
        XCTAssertEqual(plan.map(\.title), ["Dnes má svátek Silvie"])
    }

    func testNamesSharingADayAreCombined() {
        let plan = ReminderPlan.make(trackedNames: ["Zoe", "Šarlota"], shopClosures: false, today: today, hour: 0)
        XCTAssertEqual(plan.first?.title, "Zítra mají svátek Šarlota a Zoe")
        XCTAssertEqual(plan.count, 2)
    }

    func testUnknownNamesAreIgnored() {
        XCTAssertTrue(ReminderPlan.make(trackedNames: ["Kevin"], shopClosures: false, today: today, hour: 0).isEmpty)
    }

    func testShopClosuresOncePerRun() {
        let plan = ReminderPlan.make(
            trackedNames: [], shopClosures: true, today: Day(year: 2026, month: 12, day: 1), hour: 0)
        // 24 December closes at noon and 25–26 stay closed: one heads-up on the
        // 23rd. New Year's Day gets its own on the 31st.
        XCTAssertEqual(
            plan.prefix(2).map(\.day), [Day(year: 2026, month: 12, day: 23), Day(year: 2026, month: 12, day: 31)])
        XCTAssertEqual(plan.first?.title, "Zítra zavírají velké obchody ve 12:00")
        XCTAssertEqual(plan.dropFirst().first?.title, "Zítra mají velké obchody zavřeno")
    }

    func testShopClosuresOffByDefault() {
        XCTAssertTrue(ReminderPlan.make(trackedNames: [], shopClosures: false, today: today, hour: 0).isEmpty)
    }

    func testSoonestFirstAndCapped() {
        let names = Array(Set(NameDays.entries.map(\.name))).sorted().prefix(100).map { $0 }
        let plan = ReminderPlan.make(trackedNames: names, shopClosures: true, today: today, hour: 0)
        XCTAssertEqual(plan.count, ReminderPlan.limit)
        XCTAssertEqual(plan.map(\.day), plan.map(\.day).sorted())
    }
}
