import Foundation
import SwiftData

extension AppModel {
    // MARK: Check-ins

    /// Completes or un-completes a habit for a day. Data updates immediately; animations follow.
    @discardableResult
    func toggleCompletion(_ habit: Habit, on day: Date = Day.today) -> Bool {
        let day = Day.start(day)
        if let existing = habit.myCheckIn(on: day) {
            undoCompletion(habit, checkIn: existing, day: day)
            return false
        }
        _ = complete(habit, on: day)
        return true
    }

    /// Creates the current user's check-in. Returns it (or the existing one).
    @discardableResult
    func complete(_ habit: Habit, on day: Date = Day.today, quiet: Bool = false) -> CheckIn? {
        let day = Day.start(day)
        if let existing = habit.myCheckIn(on: day) { return existing }
        guard day <= Day.today else {
            feedback(.error)
            showToast("That day hasn't happened yet.", symbol: "calendar.badge.exclamationmark", tint: .orange)
            return nil
        }
        let completionsBefore = habit.myCompletionDays
        let missed = Stats.missedBefore(day: day, rule: habit.rule, start: habit.startDate, completions: completionsBefore)
        let isComeback = missed.hadPrior && missed.missed >= Stats.comebackThreshold(for: habit.rule)
        let completedAt = day == Day.today ? Date() : Day.date(day, atMinutes: habit.scheduledMinutes)

        let checkIn = CheckIn(habit: nil, day: day, completedAt: completedAt, isComeback: isComeback)
        context.insert(checkIn)
        habit.checkIns.append(checkIn)

        if !quiet { feedback(.complete) }

        // Social feed entry
        var activity: ActivityItem?
        if prefs.activityInFeed, habit.privacy != .onlyMe, day == Day.today {
            let item = ActivityItem(kind: isComeback ? .comeback : (habit.isShared ? .sharedHabit : .checkIn), actorID: nil, title: habit.name,
                                    detail: isComeback ? "Back after \(missed.missed) days off." : "", symbol: habit.symbol, tint: habit.tint, habitID: habit.id)
            context.insert(item)
            activity = item
        }

        // Group challenge contribution
        if let groupID = habit.groupID, day == Day.today, let group = group(groupID), group.isMember {
            if let challenge = group.activeChallenges.first(where: { $0.kind == .collective }) {
                logContribution(challenge, amount: 1, silent: true)
            }
        }

        if !quiet {
            let style = prefs.encouragement
            let message = isComeback ? Encouragement.comebackMessage(style: style) : Encouragement.checkInMessage(style: style, seed: habit.checkIns.count)
            showToast(message, symbol: isComeback ? "arrow.uturn.up.circle.fill" : "checkmark.seal.fill", tint: habit.tint, actionTitle: "Undo", habitID: habit.id, day: day)
        }

        save()
        evaluateCheckInAwards(habit: habit, checkIn: checkIn, missedBefore: missed.missed)

        if let activity { maybeSimulateIncomingReaction(on: activity, habitName: habit.name) }
        return checkIn
    }

    func undoCompletion(_ habit: Habit, checkIn: CheckIn, day: Date) {
        if let groupID = habit.groupID, day == Day.today, let group = group(groupID),
           let challenge = group.activeChallenges.first(where: { $0.kind == .collective }), challenge.completedAt == nil {
            challenge.add(-1, for: meID)
        }
        // Remove the matching feed entry from today.
        let habitID = habit.id
        if let items = try? context.fetch(FetchDescriptor<ActivityItem>()) {
            // Check-in entries carry the habit name as their title ("Started …" entries don't).
            for item in items where item.habitID == habitID && item.actorID == nil && item.title == habit.name && Day.start(item.createdAt) == day {
                context.delete(item)
            }
        }
        context.delete(checkIn)
        feedback(.undo)
        showToast("Unstamped \(habit.name).", symbol: "arrow.uturn.backward.circle.fill", tint: .cream)
        save()
    }

    /// Undo from a toast action.
    func undoFromToast(_ toast: Toast) {
        guard let habit = habit(toast.habitID), let day = toast.day, let checkIn = habit.myCheckIn(on: day) else { return }
        undoCompletion(habit, checkIn: checkIn, day: day)
    }

    func saveNote(_ text: String, for habit: Habit, on day: Date) {
        let cleaned = text.cleaned(max: 140)
        guard let checkIn = habit.myCheckIn(on: day) ?? complete(habit, on: day, quiet: true) else { return }
        checkIn.note = cleaned
        save()
        feedback(.send)
        showToast(cleaned.isEmpty ? "Note removed." : "Note saved.", symbol: "pencil.line", tint: habit.tint)
        if !cleaned.isEmpty { unlock("margin-notes", reason: "Noted on \(habit.name)") }
    }

    func savePhoto(_ data: Data?, for habit: Habit, on day: Date) {
        guard let checkIn = habit.myCheckIn(on: day) ?? complete(habit, on: day, quiet: true) else { return }
        checkIn.photoData = data
        save()
        if data != nil {
            feedback(.send)
            showToast("Photo proof attached.", symbol: "camera.fill", tint: habit.tint)
            unlock("proof-positive", reason: "Photo proof on \(habit.name)")
            let photoCount = ((try? context.fetch(FetchDescriptor<CheckIn>())) ?? []).filter { $0.friendID == nil && $0.photoData != nil }.count
            if photoCount >= 3 { unlockCosmetic("frame-tape") }
        } else {
            showToast("Photo removed.", symbol: "photo", tint: .cream)
        }
    }

    // MARK: Lifecycle

    func createHabit(from draft: HabitDraft) -> Habit {
        let nextOrder = (allHabits().map(\.sortOrder).max() ?? -1) + 1
        let habit = draft.makeHabit(sortOrder: nextOrder)
        context.insert(habit)
        let schedule = HabitSchedule(rule: draft.rule)
        context.insert(schedule)
        habit.schedule = schedule
        save()
        if habit.isShared {
            unlock("plus-one", reason: "Started \(habit.name) with friends")
            let names = habit.participantIDs.compactMap { friend($0)?.firstName }
            if prefs.activityInFeed, habit.privacy != .onlyMe {
                context.insert(ActivityItem(kind: .sharedHabit, actorID: nil, title: "Started “\(habit.name)”",
                                            detail: "With \(ListFormatter.localizedString(byJoining: names)).", symbol: habit.symbol, tint: habit.tint, habitID: habit.id))
            }
        }
        if habit.reminderEnabled { requestNotificationPermissionThenReschedule() }
        feedback(.send)
        showToast("“\(habit.name)” added to your book.", symbol: "plus.circle.fill", tint: habit.tint)
        save()
        return habit
    }

    func updateHabit(_ habit: Habit, from draft: HabitDraft) {
        let wasShared = habit.isShared
        draft.apply(to: habit)
        if let schedule = habit.schedule {
            schedule.rule = draft.rule
        } else {
            let schedule = HabitSchedule(rule: draft.rule)
            context.insert(schedule)
            habit.schedule = schedule
        }
        save()
        if !wasShared, habit.isShared { unlock("plus-one", reason: "Started \(habit.name) with friends") }
        if habit.reminderEnabled { requestNotificationPermissionThenReschedule() } else { rescheduleReminders() }
        showToast("Saved changes to \(habit.name).", symbol: "checkmark.circle.fill", tint: habit.tint)
    }

    func setStatus(_ status: HabitStatus, for habit: Habit) {
        habit.status = status
        save()
        rescheduleReminders()
        switch status {
        case .active: showToast("\(habit.name) is back on your page.", symbol: "play.circle.fill", tint: habit.tint)
        case .paused: showToast("\(habit.name) paused. It won't count against you.", symbol: "pause.circle.fill", tint: .cream)
        case .archived: showToast("\(habit.name) archived. History is kept.", symbol: "archivebox.fill", tint: .cream)
        }
    }

    func delete(_ habit: Habit) {
        let name = habit.name
        context.delete(habit)
        save()
        rescheduleReminders()
        showToast("Deleted \(name).", symbol: "trash.fill", tint: .cream)
    }

    func setReminder(_ habit: Habit, enabled: Bool, minutes: Int) {
        habit.reminderEnabled = enabled
        habit.reminderMinutes = minutes
        save()
        if enabled {
            requestNotificationPermissionThenReschedule()
            showToast("Reminder set for \(Day.timeText(minutes: minutes)).", symbol: "bell.fill", tint: habit.tint)
        } else {
            rescheduleReminders()
            showToast("Reminder off for \(habit.name).", symbol: "bell.slash.fill", tint: .cream)
        }
    }

    func invite(_ friendIDs: Set<UUID>, to habit: Habit) {
        let newIDs = friendIDs.subtracting(habit.participantIDs)
        guard !newIDs.isEmpty else { return }
        habit.participantIDs.append(contentsOf: newIDs)
        habit.isShared = true
        let names = newIDs.compactMap { friend($0)?.firstName }
        save()
        feedback(.send)
        showToast("Invited \(ListFormatter.localizedString(byJoining: names)) to \(habit.name).", symbol: "paperplane.fill", tint: habit.tint)
        unlock("plus-one", reason: "Started \(habit.name) with friends")
    }

    func moveHabits(_ habits: [Habit]) {
        for (index, habit) in habits.enumerated() { habit.sortOrder = index }
        save()
    }
}
