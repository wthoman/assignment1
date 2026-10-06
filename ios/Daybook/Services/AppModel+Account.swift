import Foundation
import SwiftData

/// Everything the onboarding flow collects.
struct OnboardingResult {
    var name: String
    var avatar: AvatarConfig
    var interests: [String]
    var personality: PersonalityType?
    var firstHabit: HabitDraft?
    /// nil = keep the whole demo circle.
    var keptFriendNames: Set<String>?
    var remindersOn: Bool
    var soundsOn: Bool
    var hapticsOn: Bool
}

extension AppModel {
    // MARK: Onboarding

    func completeOnboarding(_ result: OnboardingResult) {
        wipeContent(includingProfile: true)
        let cleanName = result.name.cleaned(max: 30)
        let handle = cleanName.lowercased().filter { $0.isLetter || $0.isNumber }
        let profile = UserProfile(name: cleanName.isEmpty ? "Friend" : cleanName, handle: handle.isEmpty ? "me" : handle,
                                  avatar: result.avatar, personality: result.personality, interests: result.interests)
        context.insert(profile)

        var firstHabit: Habit?
        if var draft = result.firstHabit, draft.isValid {
            draft.reminderEnabled = result.remindersOn
            let habit = draft.makeHabit(sortOrder: 0)
            context.insert(habit)
            let schedule = HabitSchedule(rule: draft.rule)
            context.insert(schedule)
            habit.schedule = schedule
            firstHabit = habit
        }
        DemoSeeder.seed(into: context, me: profile, firstHabit: firstHabit, options: .init(keptFriendNames: result.keptFriendNames))

        prefs.soundsEnabled = result.soundsOn
        prefs.hapticsEnabled = result.hapticsOn
        prefs.notifyReminders = result.remindersOn
        prefs.hasCompletedOnboarding = true
        me = profile
        save()
        router.reset()
        if result.remindersOn { requestNotificationPermissionThenReschedule() }
    }

    /// "Explore with demo data" from the welcome screen.
    func startDemo() {
        wipeContent(includingProfile: true)
        let profile = DemoSeeder.makeDemoProfile()
        context.insert(profile)
        DemoSeeder.seed(into: context, me: profile, firstHabit: nil)
        prefs.hasCompletedOnboarding = true
        me = profile
        save()
        router.reset()
    }

    // MARK: Resets

    /// Keeps the profile and settings; regenerates habits, friends and everything social.
    func resetDemoData() {
        guard let profile = me else {
            startDemo()
            return
        }
        wipeContent(includingProfile: false)
        DemoSeeder.seed(into: context, me: profile, firstHabit: nil)
        save()
        router.reset()
        rescheduleReminders()
        showToast("Demo data reset.", symbol: "arrow.counterclockwise.circle.fill", tint: .sage)
    }

    func resetOnboarding() {
        prefs.hasCompletedOnboarding = false
        save()
        router.reset()
    }

    func logOut() {
        wipeContent(includingProfile: true)
        me = nil
        prefs.hasCompletedOnboarding = false
        save()
        router.reset()
        NotificationScheduler.shared.removeAll()
    }

    func deleteAccount() {
        wipeContent(includingProfile: true)
        me = nil
        context.delete(prefs)
        let fresh = AppPreferences()
        context.insert(fresh)
        prefs = fresh
        AppPreferencesSnapshot.firstWeekday = fresh.firstWeekday
        save()
        router.reset()
        NotificationScheduler.shared.removeAll()
    }

    /// Deletes every record except preferences (and optionally the profile).
    func wipeContent(includingProfile: Bool) {
        revealing = nil
        celebratingChallenge = nil
        toast = nil
        func deleteAll<T: PersistentModel>(_ type: T.Type) {
            let items = (try? context.fetch(FetchDescriptor<T>())) ?? []
            items.forEach { context.delete($0) }
        }
        deleteAll(Reaction.self)
        deleteAll(Comment.self)
        deleteAll(ActivityItem.self)
        deleteAll(CheckIn.self)
        deleteAll(HabitSchedule.self)
        deleteAll(Habit.self)
        deleteAll(Challenge.self)
        deleteAll(HabitGroup.self)
        deleteAll(QuizResponse.self)
        deleteAll(Quiz.self)
        deleteAll(Reminder.self)
        deleteAll(Gift.self)
        deleteAll(Collectible.self)
        deleteAll(CosmeticItem.self)
        deleteAll(WeeklyRecap.self)
        deleteAll(NotificationItem.self)
        deleteAll(Friend.self)
        if includingProfile { deleteAll(UserProfile.self) }
        try? context.save()
    }

    // MARK: Profile

    func updateProfile(name: String, handle: String, bio: String, pronouns: String) {
        guard let me else { return }
        let cleanName = name.cleaned(max: 30)
        if !cleanName.isEmpty { me.name = cleanName }
        let cleanHandle = handle.cleaned(max: 20).lowercased().filter { $0.isLetter || $0.isNumber || $0 == "." || $0 == "_" }
        if !cleanHandle.isEmpty { me.handle = cleanHandle }
        me.bio = bio.cleaned(max: 160)
        me.pronouns = pronouns.cleaned(max: 20)
        save()
        showToast("Profile updated.", symbol: "person.crop.circle.badge.checkmark", tint: .sage)
    }

    func updateAvatar(_ avatar: AvatarConfig) {
        me?.avatar = avatar
        save()
        feedback(.complete)
        showToast("Looking good.", symbol: "sparkles", tint: avatar.background)
    }

    // MARK: Export

    /// Writes a JSON export of the user's own data to a temporary file.
    func exportData() -> URL? {
        struct ExportCheckIn: Encodable { let day: Date; let completedAt: Date; let note: String; let hasPhoto: Bool; let comeback: Bool }
        struct ExportHabit: Encodable {
            let name: String; let category: String; let schedule: String; let status: String; let startDate: Date
            let isShared: Bool; let checkIns: [ExportCheckIn]
        }
        struct ExportCollectible: Encodable { let name: String; let rarity: String; let earnedAt: Date?; let earnedFor: String }
        struct Export: Encodable {
            let app: String; let exportedAt: Date; let name: String; let handle: String; let bio: String
            let habits: [ExportHabit]; let collection: [ExportCollectible]
        }
        let habits = allHabits().map { habit in
            ExportHabit(name: habit.name, category: habit.category.label, schedule: habit.scheduleSummary, status: habit.status.rawValue, startDate: habit.startDate,
                        isShared: habit.isShared,
                        checkIns: habit.myCheckIns.sorted { $0.day < $1.day }.map {
                            ExportCheckIn(day: $0.day, completedAt: $0.completedAt, note: $0.note, hasPhoto: $0.hasPhoto, comeback: $0.isComeback)
                        })
        }
        let collection = ((try? context.fetch(FetchDescriptor<Collectible>())) ?? []).filter(\.isUnlocked).map {
            ExportCollectible(name: $0.name, rarity: $0.rarity.label, earnedAt: $0.earnedAt, earnedFor: $0.earnedFor)
        }
        let export = Export(app: Brand.name, exportedAt: Date(), name: me?.name ?? "", handle: me?.handle ?? "", bio: me?.bio ?? "",
                            habits: habits, collection: collection)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(export) else { return nil }
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("\(Brand.name)-export.json")
        do {
            try data.write(to: url, options: .atomic)
            return url
        } catch {
            return nil
        }
    }
}
