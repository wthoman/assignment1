import Foundation

/// Editable form state for creating or editing a habit. Validated before it touches SwiftData.
struct HabitDraft: Equatable {
    var name = ""
    var category: HabitCategory = .movement
    var symbol = HabitCategory.movement.defaultSymbol
    var tint: TintToken = HabitCategory.movement.defaultTint
    var frequency: Frequency = .daily
    var weekdays: Set<Int> = [2, 3, 4, 5, 6]
    var timesPerWeek = 3
    var timeOfDay: TimeOfDay = .morning
    var scheduledTime = Day.date(Day.today, atMinutes: TimeOfDay.morning.defaultMinutes)
    var reminderEnabled = false
    var reminderTime = Day.date(Day.today, atMinutes: TimeOfDay.morning.defaultMinutes)
    var isShared = false
    var participantIDs: Set<UUID> = []
    var notes = ""
    var proof: ProofMode = .optional
    var privacy: Visibility = .friends
    var startDate = Day.today
    var hasTargetDate = false
    var targetDate = Day.add(30, to: Day.today)
    var showStreak = true
    var isOptional = false

    static let maxNameLength = 40

    init() {}

    init(habit: Habit) {
        name = habit.name
        category = habit.category
        symbol = habit.symbol
        tint = habit.tint
        let rule = habit.rule
        frequency = rule.frequency
        weekdays = rule.frequency == .custom ? Set(rule.weekdays) : rule.activeWeekdays
        timesPerWeek = rule.timesPerWeek
        timeOfDay = habit.timeOfDay
        scheduledTime = Day.date(Day.today, atMinutes: habit.scheduledMinutes)
        reminderEnabled = habit.reminderEnabled
        reminderTime = Day.date(Day.today, atMinutes: habit.reminderMinutes)
        isShared = habit.isShared
        participantIDs = Set(habit.participantIDs)
        notes = habit.notes
        proof = habit.proof
        privacy = habit.privacy
        startDate = habit.startDate
        hasTargetDate = habit.targetDate != nil
        targetDate = habit.targetDate ?? Day.add(30, to: Day.today)
        showStreak = habit.showStreak
        isOptional = habit.isOptional
    }

    /// Prefills a draft from a suggestion (onboarding, personality result).
    init(name: String, category: HabitCategory, timeOfDay: TimeOfDay, frequency: Frequency) {
        self.name = name
        self.category = category
        self.symbol = category.defaultSymbol
        self.tint = category.defaultTint
        self.timeOfDay = timeOfDay
        self.frequency = frequency
        self.scheduledTime = Day.date(Day.today, atMinutes: timeOfDay.defaultMinutes)
        self.reminderTime = scheduledTime
    }

    var trimmedName: String { name.cleaned(max: Self.maxNameLength) }

    var rule: ScheduleRule {
        ScheduleRule(frequency: frequency, weekdays: frequency == .custom ? weekdays.sorted() : [], timesPerWeek: timesPerWeek)
    }

    // MARK: Validation

    var nameError: String? {
        if trimmedName.isEmpty { return "Give your habit a name." }
        if name.trimmingCharacters(in: .whitespacesAndNewlines).count > Self.maxNameLength { return "Keep it under \(Self.maxNameLength) characters." }
        return nil
    }

    var scheduleError: String? {
        if frequency == .custom, weekdays.isEmpty { return "Pick at least one day." }
        if frequency == .timesPerWeek, !(1...7).contains(timesPerWeek) { return "Choose between 1 and 7 times a week." }
        return nil
    }

    var sharingError: String? {
        isShared && participantIDs.isEmpty ? "Choose at least one friend, or switch to solo." : nil
    }

    var dateError: String? {
        hasTargetDate && Day.start(targetDate) <= Day.start(startDate) ? "The target date should be after the start date." : nil
    }

    var isValid: Bool {
        nameError == nil && scheduleError == nil && sharingError == nil && dateError == nil
    }

    // MARK: Apply

    func makeHabit(sortOrder: Int) -> Habit {
        let habit = Habit(name: trimmedName, category: category, symbol: symbol, tint: tint, schedule: nil, timeOfDay: timeOfDay,
                          sortOrder: sortOrder)
        apply(to: habit)
        habit.createdAt = Date()
        return habit
    }

    /// Copies everything except the schedule relationship (the caller attaches that once inserted).
    func apply(to habit: Habit) {
        habit.name = trimmedName
        habit.category = category
        habit.symbol = symbol
        habit.tint = tint
        habit.timeOfDay = timeOfDay
        habit.scheduledMinutes = Day.minutesOfDay(scheduledTime)
        habit.reminderEnabled = reminderEnabled
        habit.reminderMinutes = Day.minutesOfDay(reminderTime)
        habit.isShared = isShared && !participantIDs.isEmpty
        habit.participantIDs = habit.isShared ? Array(participantIDs) : []
        habit.notes = notes.cleaned(max: 280)
        habit.proof = proof
        habit.privacy = privacy
        habit.startDate = Day.start(startDate)
        habit.targetDate = hasTargetDate ? Day.start(targetDate) : nil
        habit.showStreak = showStreak
        habit.isOptional = isOptional
    }
}
