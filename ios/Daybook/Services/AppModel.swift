import Foundation
import Observation
import SwiftData
import SwiftUI

/// Moments that get coordinated sound + haptic feedback.
enum FeedbackEvent {
    case complete
    case undo
    case selection
    case cardPress
    case send
    case reactionReceived
    case unlock(Rarity)
    case superlativeReveal
    case recapPage
    case groupGoal
    case milestone
    case warning
    case error
}

/// A brief message at the bottom of the screen.
struct Toast: Identifiable, Equatable {
    let id = UUID()
    var message: String
    var symbol: String
    var tint: TintToken
    /// Optional action, e.g. undoing a completion.
    var actionTitle: String?
    var habitID: UUID?
    var day: Date?
}

/// The app's single source of truth for actions. Views read data with `@Query` and call
/// methods here to change it; this keeps persistence swappable for a backend later.
@Observable
@MainActor
final class AppModel {
    let context: ModelContext
    var prefs: AppPreferences
    var me: UserProfile?
    let router = AppRouter()

    // Transient presentation state
    var toast: Toast?
    var revealing: Collectible?
    var celebratingChallenge: Challenge?
    @ObservationIgnored private var revealQueue: [Collectible] = []
    @ObservationIgnored private var toastTask: Task<Void, Never>?

    /// Updated by the root view from the accessibility environment.
    var systemReduceMotion = false

    init(context: ModelContext) {
        self.context = context
        let existing = (try? context.fetch(FetchDescriptor<AppPreferences>())) ?? []
        if let first = existing.first {
            prefs = first
            existing.dropFirst().forEach { context.delete($0) }
        } else {
            let created = AppPreferences()
            context.insert(created)
            prefs = created
        }
        me = (try? context.fetch(FetchDescriptor<UserProfile>()))?.first
        AppPreferencesSnapshot.firstWeekday = prefs.firstWeekday
        save()
    }

    // MARK: Derived

    var motionReduced: Bool {
        switch prefs.motion {
        case .system: systemReduceMotion
        case .reduced: true
        case .full: false
        }
    }

    @ObservationIgnored private let placeholderID = UUID()

    /// The current user's id (used for contributions and quiz options).
    var meID: UUID { me?.id ?? placeholderID }

    func friend(_ id: UUID?) -> Friend? {
        guard let id else { return nil }
        var descriptor = FetchDescriptor<Friend>(predicate: #Predicate { $0.id == id })
        descriptor.fetchLimit = 1
        return try? context.fetch(descriptor).first
    }

    func friends(status: FriendStatus = .friend) -> [Friend] {
        let raw = status.rawValue
        let descriptor = FetchDescriptor<Friend>(predicate: #Predicate { $0.statusRaw == raw }, sortBy: [SortDescriptor(\.name)])
        return (try? context.fetch(descriptor)) ?? []
    }

    func displayName(for id: UUID?) -> String {
        guard let id else { return "You" }
        if id == me?.id { return "You" }
        return friend(id)?.name ?? "A friend"
    }

    func habit(_ id: UUID?) -> Habit? {
        guard let id else { return nil }
        var descriptor = FetchDescriptor<Habit>(predicate: #Predicate { $0.id == id })
        descriptor.fetchLimit = 1
        return try? context.fetch(descriptor).first
    }

    func group(_ id: UUID?) -> HabitGroup? {
        guard let id else { return nil }
        var descriptor = FetchDescriptor<HabitGroup>(predicate: #Predicate { $0.id == id })
        descriptor.fetchLimit = 1
        return try? context.fetch(descriptor).first
    }

    func collectible(_ key: String) -> Collectible? {
        var descriptor = FetchDescriptor<Collectible>(predicate: #Predicate { $0.key == key })
        descriptor.fetchLimit = 1
        return try? context.fetch(descriptor).first
    }

    func allHabits() -> [Habit] {
        (try? context.fetch(FetchDescriptor<Habit>(sortBy: [SortDescriptor(\.sortOrder)]))) ?? []
    }

    // MARK: Persistence

    func save() {
        do {
            try context.save()
        } catch {
            showToast("Couldn't save that change. Try again?", symbol: "exclamationmark.triangle.fill", tint: .orange)
        }
    }

    func reloadProfile() {
        me = (try? context.fetch(FetchDescriptor<UserProfile>()))?.first
    }

    func preferencesChanged() {
        AppPreferencesSnapshot.firstWeekday = prefs.firstWeekday
        save()
    }

    // MARK: Feedback

    func feedback(_ event: FeedbackEvent) {
        let p = prefs
        let volume = p.soundVolume
        let sounds = p.soundsEnabled
        func sound(_ effect: SoundEffect, _ allowed: Bool = true) {
            if sounds, allowed { SoundManager.shared.play(effect, volume: volume) }
        }
        func haptic(_ event: HapticEvent) {
            if p.hapticsEnabled { HapticManager.shared.play(event, reduced: p.reducedHaptics, celebrations: p.celebrationHaptics) }
        }
        switch event {
        case .complete:
            sound(.complete, p.completionSounds)
            haptic(.success)
        case .undo:
            sound(.undo, p.completionSounds)
            haptic(.undo)
        case .selection:
            haptic(.selection)
        case .cardPress:
            haptic(.cardPress)
        case .send:
            sound(.send)
            haptic(.cardPress)
        case .reactionReceived:
            sound(.reaction)
            haptic(.reactionReceived)
        case .unlock(let rarity):
            sound(rarity >= .rare ? .unlockRare : .unlock)
            haptic(.unlock(rarity))
        case .superlativeReveal:
            sound(.reveal, p.recapSounds)
            haptic(.awardReveal)
        case .recapPage:
            sound(.pageTurn, p.recapSounds)
            haptic(.selection)
        case .groupGoal:
            sound(.groupGoal)
            haptic(.groupCelebration)
        case .milestone:
            sound(.unlock)
            haptic(.success)
        case .warning:
            haptic(.warning)
        case .error:
            sound(.error)
            haptic(.error)
        }
    }

    // MARK: Toasts & reveals

    func showToast(_ message: String, symbol: String = "checkmark.seal.fill", tint: TintToken = .burgundy, actionTitle: String? = nil, habitID: UUID? = nil, day: Date? = nil) {
        toastTask?.cancel()
        let toast = Toast(message: message, symbol: symbol, tint: tint, actionTitle: actionTitle, habitID: habitID, day: day)
        withAnimation(motionReduced ? .none : .spring(response: 0.35, dampingFraction: 0.8)) { self.toast = toast }
        UIAccessibility.post(notification: .announcement, argument: message)
        toastTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(actionTitle == nil ? 2.4 : 3.6))
            guard !Task.isCancelled else { return }
            await MainActor.run {
                guard let self, self.toast?.id == toast.id else { return }
                withAnimation(.easeOut(duration: 0.25)) { self.toast = nil }
            }
        }
    }

    func dismissToast() {
        toastTask?.cancel()
        withAnimation(.easeOut(duration: 0.2)) { toast = nil }
    }

    /// Queue a collectible reveal. Subtle celebration mode shows a toast instead.
    func queueReveal(_ collectible: Collectible) {
        if prefs.celebration == .subtle {
            feedback(.unlock(collectible.rarity))
            showToast("New sticker: \(collectible.name)", symbol: "seal.fill", tint: collectible.tint)
            return
        }
        if revealing == nil {
            revealing = collectible
        } else {
            revealQueue.append(collectible)
        }
    }

    func finishReveal() {
        revealing?.isSeen = true
        save()
        revealing = nil
        if !revealQueue.isEmpty {
            let next = revealQueue.removeFirst()
            Task { [weak self] in
                try? await Task.sleep(for: .milliseconds(450))
                await MainActor.run { self?.revealing = next }
            }
        }
    }

    // MARK: Notifications (in-app)

    func addNotification(_ kind: NotificationKind, actorID: UUID? = nil, title: String, body: String, refID: UUID? = nil) {
        guard prefs.notificationsEnabled else { return }
        let allowed: Bool
        switch kind {
        case .reaction, .comment: allowed = prefs.notifyReactions
        case .friendRequest, .reminder, .gift, .habitInvite: allowed = prefs.notifyFriends
        case .groupInvite, .groupMilestone: allowed = prefs.notifyGroups
        case .award: allowed = prefs.notifyAwards
        case .recap: allowed = prefs.notifyRecap
        case .quiz: allowed = prefs.notifyQuizzes
        }
        guard allowed else { return }
        context.insert(NotificationItem(kind: kind, actorID: actorID, title: title, body: body, refID: refID))
    }

    // MARK: Reminders

    func rescheduleReminders() {
        let plans = allHabits()
            .filter { $0.status == .active && $0.reminderEnabled }
            .map { habit in
                ReminderPlan(habitID: habit.id, habitName: habit.name,
                             weekdays: habit.rule.isFlexible ? [] : habit.rule.activeWeekdays.sorted(),
                             minutes: habit.reminderMinutes, isShared: habit.isShared)
            }
        let enabled = prefs.notificationsEnabled && prefs.notifyReminders
        let quiet = prefs.quietHoursEnabled ? (prefs.quietStartMinutes, prefs.quietEndMinutes) : nil
        Task {
            await NotificationScheduler.shared.reschedule(plans, enabled: enabled, quietHours: quiet)
        }
    }

    /// Called when the user turns on a reminder: the contextually appropriate moment to ask.
    func requestNotificationPermissionThenReschedule() {
        Task { [weak self] in
            let granted = await NotificationScheduler.shared.requestAuthorizationIfNeeded()
            await MainActor.run {
                guard let self else { return }
                if !granted {
                    self.showToast("Reminders are saved, but notifications are off in iOS Settings.", symbol: "bell.slash.fill", tint: .orange)
                }
                self.rescheduleReminders()
            }
        }
    }

    // MARK: Lifecycle

    func handleScenePhase(_ phase: ScenePhase) {
        switch phase {
        case .background:
            SoundManager.shared.suspend()
            save()
        case .active:
            HapticManager.shared.prepare()
        default:
            break
        }
    }
}
