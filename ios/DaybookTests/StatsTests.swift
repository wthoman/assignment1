import XCTest
@testable import Daybook

final class StatsTests: XCTestCase {
    private var calendar: Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = .current
        cal.firstWeekday = 2
        return cal
    }

    private func day(_ offset: Int, from base: Date) -> Date {
        Day.add(offset, to: base, calendar: calendar)
    }

    func testPerfectDailyHabitIsFullyConsistent() {
        let today = Day.start(Date(), calendar: calendar)
        let start = day(-27, from: today)
        let completions = Set((0..<28).map { day(-$0, from: today) })
        let tally = Stats.tally(rule: ScheduleRule(frequency: .daily), start: start, completions: completions, from: start, to: today, today: today, calendar: calendar)
        XCTAssertEqual(tally.expected, 28)
        XCTAssertEqual(tally.done, 28)
        XCTAssertEqual(tally.consistency, 1)
    }

    func testOneMissPerWeekIsForgiven() {
        let today = Day.start(Date(), calendar: calendar)
        let start = day(-13, from: today)
        // Two weeks, two misses (one per week) → still 100%.
        var completions = Set((0..<14).map { day(-$0, from: today) })
        completions.remove(day(-3, from: today))
        completions.remove(day(-10, from: today))
        let tally = Stats.tally(rule: ScheduleRule(frequency: .daily), start: start, completions: completions, from: start, to: today, today: today, calendar: calendar)
        XCTAssertEqual(tally.forgiven, 2)
        XCTAssertEqual(tally.consistency, 1)
    }

    func testUnfinishedTodayDoesNotCountAgainst() {
        let today = Day.start(Date(), calendar: calendar)
        let start = day(-6, from: today)
        let completions = Set((1..<7).map { day(-$0, from: today) })
        let tally = Stats.tally(rule: ScheduleRule(frequency: .daily), start: start, completions: completions, from: start, to: today, today: today, calendar: calendar)
        XCTAssertEqual(tally.expected, 6, "Today isn't over, so it shouldn't be expected yet")
        XCTAssertEqual(tally.consistency, 1)
    }

    func testOptionalAndFlexibleTallies() {
        let today = Day.start(Date(), calendar: calendar)
        let start = day(-13, from: today)
        let completions: Set<Date> = [day(-1, from: today), day(-3, from: today), day(-8, from: today)]
        let rule = ScheduleRule(frequency: .timesPerWeek, timesPerWeek: 3)
        let tally = Stats.tally(rule: rule, start: start, completions: completions, from: start, to: today, today: today, calendar: calendar)
        XCTAssertEqual(tally.done, 3)
        XCTAssertGreaterThan(tally.expected, 3)
    }

    func testComebackDetection() {
        let today = Day.start(Date(), calendar: calendar)
        let start = day(-10, from: today)
        let completions: Set<Date> = [day(-10, from: today), day(-9, from: today), day(-5, from: today)]
        let rule = ScheduleRule(frequency: .daily)
        XCTAssertTrue(Stats.isComeback(day: day(-5, from: today), rule: rule, start: start, completions: completions, calendar: calendar))
        XCTAssertFalse(Stats.isComeback(day: day(-9, from: today), rule: rule, start: start, completions: completions, calendar: calendar))
        XCTAssertEqual(Stats.comebacks(rule: rule, start: start, completions: completions, from: start, to: today, calendar: calendar), 1)
    }

    func testStreakIgnoresUnfinishedToday() {
        let today = Day.start(Date(), calendar: calendar)
        let start = day(-20, from: today)
        let completions = Set((1...5).map { day(-$0, from: today) })
        let streak = Stats.currentStreak(rule: ScheduleRule(frequency: .daily), start: start, completions: completions, today: today, calendar: calendar)
        XCTAssertEqual(streak.count, 5)
        XCTAssertEqual(Stats.bestStreak(rule: ScheduleRule(frequency: .daily), start: start, completions: completions, today: today, calendar: calendar), 5)
    }

    func testWeekdayScheduleSkipsWeekends() {
        let rule = ScheduleRule(frequency: .weekdays)
        XCTAssertEqual(rule.activeWeekdays, [2, 3, 4, 5, 6])
        XCTAssertEqual(ScheduleRule(frequency: .custom, weekdays: [1, 4]).activeWeekdays, [1, 4])
    }

    func testPersonalityScoring() {
        XCTAssertEqual(Catalog.scorePersonality([.socialMotivator, .socialMotivator, .varietySeeker]), .socialMotivator)
        XCTAssertEqual(Catalog.scorePersonality([]), .gentleBuilder, "Ties fall back to the first personality")
    }

    func testDraftValidation() {
        var draft = HabitDraft()
        XCTAssertFalse(draft.isValid)
        draft.name = "Walk"
        XCTAssertTrue(draft.isValid)
        draft.frequency = .custom
        draft.weekdays = []
        XCTAssertNotNil(draft.scheduleError)
        draft.weekdays = [2]
        draft.isShared = true
        XCTAssertNotNil(draft.sharingError)
    }

    func testQuietHoursWrapMidnight() {
        XCTAssertTrue(NotificationScheduler.isQuiet(23 * 60, start: 22 * 60, end: 7 * 60))
        XCTAssertTrue(NotificationScheduler.isQuiet(6 * 60, start: 22 * 60, end: 7 * 60))
        XCTAssertFalse(NotificationScheduler.isQuiet(12 * 60, start: 22 * 60, end: 7 * 60))
    }

    func testVotedAwardsOnlyGoToPeopleWithVotes() {
        func person(_ name: String, late: Int = 0, votes: [String: Int] = [:]) -> RecapPerson {
            RecapPerson(id: UUID(), name: name, avatar: AvatarConfig(), isMe: false, completions: 5, lateNight: late, weekend: 0,
                        comebacks: 0, remindersSent: 0, consistency: 0.5, previousConsistency: 0.5, votes: votes)
        }
        let sam = person("Sam", late: 6, votes: ["last-minute": 3])
        let priya = person("Priya", late: 1)
        let awards = RecapEngine.assignSuperlatives([sam, priya])
        XCTAssertEqual(awards.first { $0.title.contains("11:59") }?.winnerID, sam.id, "Friends' pick wins the voted award")
        XCTAssertFalse(awards.contains { $0.source == .votes && $0.winnerID == priya.id }, "Nobody wins a voted award with zero votes")
        XCTAssertEqual(awards.first { $0.title == "Last-Minute Legend" }?.winnerID, priya.id, "One award per person")
    }

    func testCleanedText() {
        XCTAssertEqual("  hello\u{0007} ".cleaned(), "hello")
        XCTAssertEqual(String(repeating: "a", count: 300).cleaned(max: 10).count, 10)
    }
}
