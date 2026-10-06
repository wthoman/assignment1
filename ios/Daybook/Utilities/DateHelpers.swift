import Foundation

/// Calendar helpers. All "day" values in the app are normalized to the start of a local day.
enum Day {
    static var calendar: Calendar {
        var cal = Calendar.current
        cal.firstWeekday = AppPreferencesSnapshot.firstWeekday
        return cal
    }

    static func start(_ date: Date, calendar: Calendar = Day.calendar) -> Date {
        calendar.startOfDay(for: date)
    }

    static var today: Date { start(Date()) }

    static func add(_ days: Int, to date: Date, calendar: Calendar = Day.calendar) -> Date {
        calendar.date(byAdding: .day, value: days, to: start(date, calendar: calendar)) ?? date
    }

    static func between(_ a: Date, _ b: Date, calendar: Calendar = Day.calendar) -> Int {
        calendar.dateComponents([.day], from: start(a, calendar: calendar), to: start(b, calendar: calendar)).day ?? 0
    }

    /// 1 = Sunday … 7 = Saturday (Foundation convention).
    static func weekday(_ date: Date, calendar: Calendar = Day.calendar) -> Int {
        calendar.component(.weekday, from: date)
    }

    static func isWeekend(_ date: Date, calendar: Calendar = Day.calendar) -> Bool {
        let wd = weekday(date, calendar: calendar)
        return wd == 1 || wd == 7
    }

    static func startOfWeek(_ date: Date, calendar: Calendar = Day.calendar) -> Date {
        let day = start(date, calendar: calendar)
        let wd = weekday(day, calendar: calendar)
        let offset = (wd - calendar.firstWeekday + 7) % 7
        return add(-offset, to: day, calendar: calendar)
    }

    static func week(containing date: Date, calendar: Calendar = Day.calendar) -> [Date] {
        let first = startOfWeek(date, calendar: calendar)
        return (0..<7).map { add($0, to: first, calendar: calendar) }
    }

    /// The last `count` days ending on (and including) `end`.
    static func lastDays(_ count: Int, endingOn end: Date, calendar: Calendar = Day.calendar) -> [Date] {
        (0..<count).reversed().map { add(-$0, to: end, calendar: calendar) }
    }

    static func startOfMonth(_ date: Date, calendar: Calendar = Day.calendar) -> Date {
        calendar.date(from: calendar.dateComponents([.year, .month], from: date)) ?? start(date, calendar: calendar)
    }

    /// Weekday symbols ordered by the calendar's first weekday, e.g. ["M","T",…].
    static func orderedVeryShortSymbols(calendar: Calendar = Day.calendar) -> [String] {
        let symbols = calendar.veryShortWeekdaySymbols
        return (0..<7).map { symbols[(calendar.firstWeekday - 1 + $0) % 7] }
    }

    /// Weekday numbers (1…7) ordered by the calendar's first weekday.
    static func orderedWeekdays(calendar: Calendar = Day.calendar) -> [Int] {
        (0..<7).map { ((calendar.firstWeekday - 1 + $0) % 7) + 1 }
    }

    static func shortName(forWeekday wd: Int, calendar: Calendar = Day.calendar) -> String {
        calendar.shortWeekdaySymbols[safe: wd - 1] ?? ""
    }

    static func longName(forWeekday wd: Int, calendar: Calendar = Day.calendar) -> String {
        calendar.weekdaySymbols[safe: wd - 1] ?? ""
    }

    static func minutesOfDay(_ date: Date, calendar: Calendar = Day.calendar) -> Int {
        let c = calendar.dateComponents([.hour, .minute], from: date)
        return (c.hour ?? 0) * 60 + (c.minute ?? 0)
    }

    static func date(_ day: Date, atMinutes minutes: Int, calendar: Calendar = Day.calendar) -> Date {
        calendar.date(byAdding: .minute, value: minutes, to: start(day, calendar: calendar)) ?? day
    }

    static func timeText(minutes: Int) -> String {
        date(Date(), atMinutes: minutes).formatted(date: .omitted, time: .shortened)
    }

    static func relative(_ date: Date, now: Date = Date()) -> String {
        let seconds = now.timeIntervalSince(date)
        if seconds < 60 { return "just now" }
        if seconds < 3600 { return "\(Int(seconds / 60))m ago" }
        if seconds < 86_400 { return "\(Int(seconds / 3600))h ago" }
        let days = Int(seconds / 86_400)
        if days == 1 { return "yesterday" }
        if days < 7 { return "\(days)d ago" }
        return date.formatted(.dateTime.month(.abbreviated).day())
    }
}

/// The first weekday is a user preference, but `Day.calendar` is used from many non-view
/// contexts. The app keeps this snapshot in sync with `AppPreferences.firstWeekday`.
enum AppPreferencesSnapshot {
    nonisolated(unsafe) static var firstWeekday: Int = Calendar.current.firstWeekday
}
