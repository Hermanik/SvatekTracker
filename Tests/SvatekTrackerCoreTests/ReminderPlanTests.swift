import XCTest

@testable import SvatekTrackerCore

final class ReminderPlanTests: XCTestCase {
    private let today = Day(year: 2026, month: 10, day: 28)
    private let dayBefore = ReminderPlan.defaultDayBefore
    private let onTheDay = ReminderPlan.defaultOnTheDay
    private let midnight = TimeOfDay(hour: 0)

    func testDayBeforeAndOnTheDay() {
        let plan = ReminderPlan.make(
            trackedNames: ["Silvie"], dayBefore: dayBefore, onTheDay: onTheDay, shopClosures: nil, today: today,
            now: TimeOfDay(hour: 10))
        XCTAssertEqual(plan.map(\.title), ["Zítra má svátek Silvie", "Dnes má svátek Silvie"])
        XCTAssertEqual(plan.map(\.day), [today, Day(year: 2026, month: 10, day: 29)])
        XCTAssertEqual(plan.map(\.time), [TimeOfDay(hour: 18), TimeOfDay(hour: 8)])
    }

    func testRemindersFireAtTheChosenTimes() {
        let plan = ReminderPlan.make(
            trackedNames: ["Silvie"], dayBefore: TimeOfDay(hour: 20, minute: 30),
            onTheDay: TimeOfDay(hour: 6, minute: 45), shopClosures: TimeOfDay(hour: 19, minute: 15), today: today,
            now: midnight)
        XCTAssertEqual(
            plan.prefix(2).map(\.time), [TimeOfDay(hour: 20, minute: 30), TimeOfDay(hour: 6, minute: 45)])
        // 17 November keeps shops open, so the next heads-up is before Christmas Eve.
        let shops = plan.first { $0.id.hasPrefix("shops-") }
        XCTAssertEqual(shops?.day, Day(year: 2026, month: 12, day: 23))
        XCTAssertEqual(shops?.time, TimeOfDay(hour: 19, minute: 15))
    }

    func testEachNameDayReminderCanBeTurnedOff() {
        let morningOnly = ReminderPlan.make(
            trackedNames: ["Silvie"], dayBefore: nil, onTheDay: onTheDay, shopClosures: nil, today: today,
            now: midnight)
        XCTAssertEqual(morningOnly.map(\.title), ["Dnes má svátek Silvie"])
        let eveningOnly = ReminderPlan.make(
            trackedNames: ["Silvie"], dayBefore: dayBefore, onTheDay: nil, shopClosures: nil, today: today,
            now: midnight)
        XCTAssertEqual(eveningOnly.map(\.title), ["Zítra má svátek Silvie"])
    }

    func testPastRemindersAreDropped() {
        // At 18:01 the evening reminder for tomorrow has just gone by.
        let plan = ReminderPlan.make(
            trackedNames: ["Silvie"], dayBefore: dayBefore, onTheDay: onTheDay, shopClosures: nil, today: today,
            now: TimeOfDay(hour: 18, minute: 1))
        XCTAssertEqual(plan.map(\.title), ["Dnes má svátek Silvie"])
    }

    func testNamesSharingADayAreCombined() {
        let plan = ReminderPlan.make(
            trackedNames: ["Zoe", "Šarlota"], dayBefore: dayBefore, onTheDay: onTheDay, shopClosures: nil,
            today: today, now: midnight)
        XCTAssertEqual(plan.first?.title, "Zítra mají svátek Šarlota a Zoe")
        XCTAssertEqual(plan.count, 2)
    }

    func testUnknownNamesAreIgnored() {
        XCTAssertTrue(
            ReminderPlan.make(
                trackedNames: ["Kevin"], dayBefore: dayBefore, onTheDay: onTheDay, shopClosures: nil, today: today,
                now: midnight
            ).isEmpty)
    }

    func testShopClosuresOncePerRun() {
        let plan = ReminderPlan.make(
            trackedNames: [], dayBefore: dayBefore, onTheDay: onTheDay, shopClosures: ReminderPlan.defaultShopClosures,
            today: Day(year: 2026, month: 12, day: 1), now: midnight)
        // 24 December closes at noon and 25–26 stay closed: one heads-up on the
        // 23rd. New Year's Day gets its own on the 31st.
        XCTAssertEqual(
            plan.prefix(2).map(\.day), [Day(year: 2026, month: 12, day: 23), Day(year: 2026, month: 12, day: 31)])
        XCTAssertEqual(plan.first?.title, "Zítra zavírají velké obchody ve 12:00")
        XCTAssertEqual(plan.dropFirst().first?.title, "Zítra mají velké obchody zavřeno")
    }

    func testShopClosuresOff() {
        XCTAssertTrue(
            ReminderPlan.make(
                trackedNames: [], dayBefore: dayBefore, onTheDay: onTheDay, shopClosures: nil, today: today,
                now: midnight
            ).isEmpty)
    }

    func testSoonestFirstAndCapped() {
        let names = Array(Set(NameDays.entries.map(\.name))).sorted().prefix(100).map { $0 }
        let plan = ReminderPlan.make(
            trackedNames: names, dayBefore: dayBefore, onTheDay: onTheDay,
            shopClosures: ReminderPlan.defaultShopClosures, today: today,
            now: midnight)
        XCTAssertEqual(plan.count, ReminderPlan.limit)
        XCTAssertEqual(plan.map(\.day), plan.map(\.day).sorted())
    }
}
