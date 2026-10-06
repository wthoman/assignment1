import Foundation

/// Expected vs. achieved check-ins for one habit over a window.
struct Tally: Equatable {
    var expected: Int
    var done: Int
    /// Misses forgiven (one per full week in the window).
    var forgiven: Int

    static let zero = Tally(expected: 0, done: 0, forgiven: 0)

    static func + (lhs: Tally, rhs: Tally) -> Tally {
        Tally(expected: lhs.expected + rhs.expected, done: lhs.done + rhs.done, forgiven: lhs.forgiven + rhs.forgiven)
    }

    /// Forgiving consistency: done ÷ (expected − forgiven), capped at 100%. nil when nothing was expected.
    var consistency: Double? {
        guard expected > 0 else { return nil }
        let denominator = max(1, expected - forgiven)
        return min(1, Double(done) / Double(denominator))
    }
}

struct Streak: Equatable {
    var count: Int
    /// "day" for fixed schedules, "week" for n-per-week habits.
    var unit: String

    var label: String { "\(count) \(unit)\(count == 1 ? "" : "s")" }
}

/// Pure, testable habit math. Nothing here touches SwiftData.
enum Stats {
    /// Rolling window used for the headline consistency score.
    static let windowDays = 28

    static func tally(
        rule: ScheduleRule, start: Date, completions: Set<Date>, from: Date, to: Date,
        today: Date = Day.today, calendar: Calendar = Day.calendar
    ) -> Tally {
        let lower = max(Day.start(from, calendar: calendar), Day.start(start, calendar: calendar))
        var upper = Day.start(to, calendar: calendar)
        // Today isn't over: only count it once it's been completed.
        if upper >= Day.start(today, calendar: calendar), !completions.contains(Day.start(today, calendar: calendar)) {
            upper = Day.add(-1, to: Day.start(today, calendar: calendar), calendar: calendar)
        }
        guard lower <= upper else {
            // Window is just "today" and it's done.
            let doneToday = completions.contains(Day.start(today, calendar: calendar)) && lower <= Day.start(today, calendar: calendar)
            return doneToday ? Tally(expected: 1, done: 1, forgiven: 0) : .zero
        }
        let dayCount = Day.between(lower, upper, calendar: calendar) + 1
        let days = (0..<dayCount).map { Day.add($0, to: lower, calendar: calendar) }
        let forgiven = dayCount / 7
        let doneDays = days.filter { completions.contains($0) }

        if rule.isFlexible {
            let expected = Int((Double(rule.timesPerWeek) * Double(dayCount) / 7).rounded(.up))
            return Tally(expected: expected, done: min(doneDays.count, expected), forgiven: forgiven)
        }

        let scheduled = days.filter { rule.isScheduled(on: $0, calendar: calendar) }
        let doneOnSchedule = scheduled.filter { completions.contains($0) }.count
        // Bonus check-ins on unscheduled days can make up for misses, never exceed 100%.
        let bonus = doneDays.count - doneOnSchedule
        let done = min(scheduled.count, doneOnSchedule + bonus)
        return Tally(expected: scheduled.count, done: done, forgiven: forgiven)
    }

    static func consistency(
        rule: ScheduleRule, start: Date, completions: Set<Date>, endingOn end: Date = Day.today,
        days: Int = windowDays, calendar: Calendar = Day.calendar
    ) -> Double? {
        let from = Day.add(-(days - 1), to: end, calendar: calendar)
        return tally(rule: rule, start: start, completions: completions, from: from, to: end, today: Day.today, calendar: calendar).consistency
    }

    /// Consecutive scheduled days completed, ending today. An unfinished today never breaks a streak.
    static func currentStreak(rule: ScheduleRule, start: Date, completions: Set<Date>, today: Date = Day.today, calendar: Calendar = Day.calendar) -> Streak {
        if rule.isFlexible {
            return Streak(count: weekStreak(rule: rule, start: start, completions: completions, today: today, calendar: calendar), unit: "week")
        }
        var count = 0
        var day = Day.start(today, calendar: calendar)
        let first = Day.start(start, calendar: calendar)
        if !completions.contains(day) { day = Day.add(-1, to: day, calendar: calendar) }
        var guardCounter = 0
        while day >= first, guardCounter < 800 {
            guardCounter += 1
            if rule.isScheduled(on: day, calendar: calendar) {
                if completions.contains(day) { count += 1 } else { break }
            } else if completions.contains(day) {
                count += 1
            }
            day = Day.add(-1, to: day, calendar: calendar)
        }
        return Streak(count: count, unit: "day")
    }

    static func bestStreak(rule: ScheduleRule, start: Date, completions: Set<Date>, today: Date = Day.today, calendar: Calendar = Day.calendar) -> Int {
        if rule.isFlexible { return weekStreak(rule: rule, start: start, completions: completions, today: today, calendar: calendar, best: true) }
        let first = Day.start(start, calendar: calendar)
        let last = Day.start(today, calendar: calendar)
        guard first <= last else { return 0 }
        var best = 0
        var run = 0
        var day = first
        while day <= last {
            if completions.contains(day) {
                run += 1
                best = max(best, run)
            } else if rule.isScheduled(on: day, calendar: calendar), day < last {
                run = 0
            }
            day = Day.add(1, to: day, calendar: calendar)
        }
        return best
    }

    private static func weekStreak(rule: ScheduleRule, start: Date, completions: Set<Date>, today: Date, calendar: Calendar, best: Bool = false) -> Int {
        var weekStart = Day.startOfWeek(today, calendar: calendar)
        let first = Day.startOfWeek(start, calendar: calendar)
        var run = 0
        var bestRun = 0
        var isCurrentWeek = true
        var guardCounter = 0
        while weekStart >= first, guardCounter < 200 {
            guardCounter += 1
            let days = (0..<7).map { Day.add($0, to: weekStart, calendar: calendar) }
            let done = days.filter { completions.contains($0) }.count
            if done >= rule.timesPerWeek {
                run += 1
                bestRun = max(bestRun, run)
            } else if !isCurrentWeek {
                if !best { break }
                run = 0
            }
            isCurrentWeek = false
            weekStart = Day.add(-7, to: weekStart, calendar: calendar)
        }
        return best ? bestRun : run
    }

    /// Consecutive scheduled days missed right before `day`.
    static func missedBefore(day: Date, rule: ScheduleRule, start: Date, completions: Set<Date>, calendar: Calendar = Day.calendar) -> (missed: Int, hadPrior: Bool) {
        var cursor = Day.add(-1, to: day, calendar: calendar)
        let first = Day.start(start, calendar: calendar)
        var missed = 0
        var guardCounter = 0
        while cursor >= first, guardCounter < 400 {
            guardCounter += 1
            if completions.contains(cursor) { return (missed, true) }
            if rule.isFlexible || rule.isScheduled(on: cursor, calendar: calendar) { missed += 1 }
            cursor = Day.add(-1, to: cursor, calendar: calendar)
        }
        return (missed, false)
    }

    /// Minimum gap of missed scheduled days that makes a check-in a comeback.
    static func comebackThreshold(for rule: ScheduleRule) -> Int { rule.isFlexible ? 4 : 2 }

    static func isComeback(day: Date, rule: ScheduleRule, start: Date, completions: Set<Date>, calendar: Calendar = Day.calendar) -> Bool {
        let result = missedBefore(day: day, rule: rule, start: start, completions: completions, calendar: calendar)
        return result.hadPrior && result.missed >= comebackThreshold(for: rule)
    }

    /// Number of comebacks among completions inside [from, to].
    static func comebacks(rule: ScheduleRule, start: Date, completions: Set<Date>, from: Date, to: Date, calendar: Calendar = Day.calendar) -> Int {
        completions
            .filter { $0 >= Day.start(from, calendar: calendar) && $0 <= Day.start(to, calendar: calendar) }
            .filter { isComeback(day: $0, rule: rule, start: start, completions: completions, calendar: calendar) }
            .count
    }

    /// Completions per weekday, indexed 1 (Sunday) … 7 (Saturday); index 0 unused.
    static func weekdayTotals(_ days: [Date], calendar: Calendar = Day.calendar) -> [Int] {
        var totals = Array(repeating: 0, count: 8)
        for day in days { totals[Day.weekday(day, calendar: calendar)] += 1 }
        return totals
    }
}

/// Convenience wrappers on the model.
extension Habit {
    func tally(from: Date, to: Date) -> Tally {
        Stats.tally(rule: rule, start: startDate, completions: myCompletionDays, from: from, to: to)
    }

    var rollingConsistency: Double? {
        Stats.consistency(rule: rule, start: startDate, completions: myCompletionDays)
    }

    var currentStreak: Streak {
        Stats.currentStreak(rule: rule, start: startDate, completions: myCompletionDays)
    }

    var bestStreak: Int {
        Stats.bestStreak(rule: rule, start: startDate, completions: myCompletionDays)
    }

    var comebackCount: Int {
        Stats.comebacks(rule: rule, start: startDate, completions: myCompletionDays, from: startDate, to: Day.today)
    }

    /// Whether the habit counts toward the headline score.
    var countsTowardConsistency: Bool { status == .active && !isOptional }
}

extension Array where Element == Habit {
    /// Combined forgiving consistency across habits that count.
    func overallConsistency(endingOn end: Date = Day.today, days: Int = Stats.windowDays) -> Double? {
        let from = Day.add(-(days - 1), to: end)
        return filter(\.countsTowardConsistency)
            .map { $0.tally(from: from, to: end) }
            .reduce(Tally.zero, +)
            .consistency
    }
}
