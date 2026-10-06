import Foundation
import SwiftData

@Model
final class Habit {
    var id: UUID
    var name: String
    var categoryRaw: String
    var symbol: String
    var tintRaw: String
    @Relationship(deleteRule: .cascade, inverse: \HabitSchedule.habit)
    var schedule: HabitSchedule?
    var timeOfDayRaw: String
    /// Scheduled time, minutes after midnight.
    var scheduledMinutes: Int
    var reminderEnabled: Bool
    var reminderMinutes: Int
    var isShared: Bool
    /// Friend ids taking part in a shared habit (the current user is implied).
    var participantIDs: [UUID]
    var notes: String
    var proofRaw: String
    var privacyRaw: String
    var startDate: Date
    var targetDate: Date?
    var showStreak: Bool
    var isOptional: Bool
    var statusRaw: String
    var createdAt: Date
    var groupID: UUID?
    var sortOrder: Int
    @Relationship(deleteRule: .cascade, inverse: \CheckIn.habit)
    var checkIns: [CheckIn] = []

    init(
        id: UUID = UUID(), name: String, category: HabitCategory, symbol: String? = nil, tint: TintToken? = nil,
        schedule: HabitSchedule? = nil, timeOfDay: TimeOfDay = .anytime, scheduledMinutes: Int? = nil,
        reminderEnabled: Bool = false, reminderMinutes: Int? = nil, isShared: Bool = false,
        participantIDs: [UUID] = [], notes: String = "", proof: ProofMode = .optional,
        privacy: Visibility = .friends, startDate: Date = Day.today, targetDate: Date? = nil,
        showStreak: Bool = true, isOptional: Bool = false, status: HabitStatus = .active,
        createdAt: Date = Date(), sortOrder: Int = 0
    ) {
        self.id = id
        self.name = name
        self.categoryRaw = category.rawValue
        self.symbol = symbol ?? category.defaultSymbol
        self.tintRaw = (tint ?? category.defaultTint).rawValue
        self.schedule = schedule
        self.timeOfDayRaw = timeOfDay.rawValue
        self.scheduledMinutes = scheduledMinutes ?? timeOfDay.defaultMinutes
        self.reminderEnabled = reminderEnabled
        self.reminderMinutes = reminderMinutes ?? (scheduledMinutes ?? timeOfDay.defaultMinutes)
        self.isShared = isShared
        self.participantIDs = participantIDs
        self.notes = notes
        self.proofRaw = proof.rawValue
        self.privacyRaw = privacy.rawValue
        self.startDate = startDate
        self.targetDate = targetDate
        self.showStreak = showStreak
        self.isOptional = isOptional
        self.statusRaw = status.rawValue
        self.createdAt = createdAt
        self.sortOrder = sortOrder
    }

    var category: HabitCategory {
        get { HabitCategory(rawValue: categoryRaw) ?? .mind }
        set { categoryRaw = newValue.rawValue }
    }

    var tint: TintToken {
        get { TintToken(rawValue: tintRaw) ?? .burgundy }
        set { tintRaw = newValue.rawValue }
    }

    var timeOfDay: TimeOfDay {
        get { TimeOfDay(rawValue: timeOfDayRaw) ?? .anytime }
        set { timeOfDayRaw = newValue.rawValue }
    }

    var proof: ProofMode {
        get { ProofMode(rawValue: proofRaw) ?? .optional }
        set { proofRaw = newValue.rawValue }
    }

    var privacy: Visibility {
        get { Visibility(rawValue: privacyRaw) ?? .friends }
        set { privacyRaw = newValue.rawValue }
    }

    var status: HabitStatus {
        get { HabitStatus(rawValue: statusRaw) ?? .active }
        set { statusRaw = newValue.rawValue }
    }

    var rule: ScheduleRule { schedule?.rule ?? ScheduleRule(frequency: .daily) }

    /// The current user's check-ins (friends' check-ins on shared habits are excluded).
    var myCheckIns: [CheckIn] { checkIns.filter { $0.friendID == nil } }

    var myCompletionDays: Set<Date> { Set(myCheckIns.map(\.day)) }

    func myCheckIn(on day: Date) -> CheckIn? {
        let d = Day.start(day)
        return checkIns.first { $0.friendID == nil && $0.day == d }
    }

    func isCompleted(on day: Date) -> Bool { myCheckIn(on: day) != nil }

    func friendCompleted(_ friendID: UUID, on day: Date) -> Bool {
        let d = Day.start(day)
        return checkIns.contains { $0.friendID == friendID && $0.day == d }
    }

    func isScheduled(on day: Date) -> Bool {
        guard Day.start(day) >= Day.start(startDate) else { return false }
        return rule.isScheduled(on: day)
    }

    var scheduleSummary: String { rule.summary }
}

/// How often a habit repeats. Kept as its own model so a backend can sync schedules independently.
@Model
final class HabitSchedule {
    var frequencyRaw: String
    /// Weekdays 1 (Sunday) … 7 (Saturday) used by `.custom` (and derived for presets).
    var weekdays: [Int]
    var timesPerWeek: Int
    var habit: Habit?

    init(frequency: Frequency, weekdays: [Int] = [], timesPerWeek: Int = 3) {
        self.frequencyRaw = frequency.rawValue
        self.weekdays = weekdays
        self.timesPerWeek = timesPerWeek
    }

    convenience init(rule: ScheduleRule) {
        self.init(frequency: rule.frequency, weekdays: rule.weekdays, timesPerWeek: rule.timesPerWeek)
    }

    var frequency: Frequency {
        get { Frequency(rawValue: frequencyRaw) ?? .daily }
        set { frequencyRaw = newValue.rawValue }
    }

    var rule: ScheduleRule {
        get { ScheduleRule(frequency: frequency, weekdays: weekdays, timesPerWeek: timesPerWeek) }
        set {
            frequency = newValue.frequency
            weekdays = newValue.weekdays
            timesPerWeek = newValue.timesPerWeek
        }
    }
}

/// Pure value describing a schedule; used by stats so they can be unit tested without SwiftData.
struct ScheduleRule: Hashable, Codable {
    var frequency: Frequency
    var weekdays: [Int] = []
    var timesPerWeek: Int = 3

    /// The weekdays a fixed schedule falls on.
    var activeWeekdays: Set<Int> {
        switch frequency {
        case .daily, .timesPerWeek: Set(1...7)
        case .weekdays: [2, 3, 4, 5, 6]
        case .weekends: [1, 7]
        case .custom: Set(weekdays)
        }
    }

    /// Flexible schedules (n per week) don't fix days; every day is an opportunity.
    var isFlexible: Bool { frequency == .timesPerWeek }

    func isScheduled(on day: Date, calendar: Calendar = Day.calendar) -> Bool {
        activeWeekdays.contains(Day.weekday(day, calendar: calendar))
    }

    var summary: String {
        switch frequency {
        case .daily: return "Every day"
        case .weekdays: return "Weekdays"
        case .weekends: return "Weekends"
        case .timesPerWeek: return "\(timesPerWeek)× a week"
        case .custom:
            let ordered = Day.orderedWeekdays().filter { weekdays.contains($0) }
            if ordered.isEmpty { return "No days chosen" }
            return ordered.map { Day.shortName(forWeekday: $0) }.joined(separator: " · ")
        }
    }
}
