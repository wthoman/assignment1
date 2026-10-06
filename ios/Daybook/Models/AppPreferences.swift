import Foundation
import SwiftData

/// Singleton settings record. Created on first launch and kept across demo resets.
@Model
final class AppPreferences {
    // Session
    var hasCompletedOnboarding: Bool
    var lastSeenRecapWeek: Date?

    // Appearance
    var appearanceRaw: String
    var accentRaw: String
    var densityRaw: String
    var firstWeekday: Int
    var encouragementRaw: String
    var showStreaks: Bool
    var celebrationRaw: String
    var motionRaw: String
    var strongerBorders: Bool

    // Privacy
    var recapVisibilityRaw: String
    var profileVisibilityRaw: String
    var allowFriendReminders: Bool
    var activityInFeed: Bool
    var shareHidesPrivateDetails: Bool
    var showConsistencyOnProfile: Bool

    // Sound
    var soundsEnabled: Bool
    var completionSounds: Bool
    var recapSounds: Bool
    var soundVolume: Double

    // Haptics
    var hapticsEnabled: Bool
    var reducedHaptics: Bool
    var celebrationHaptics: Bool

    // Notifications
    var notificationsEnabled: Bool
    var notifyReminders: Bool
    var notifyFriends: Bool
    var notifyReactions: Bool
    var notifyGroups: Bool
    var notifyAwards: Bool
    var notifyRecap: Bool
    var notifyQuizzes: Bool
    var quietHoursEnabled: Bool
    var quietStartMinutes: Int
    var quietEndMinutes: Int

    // Connected services (mock)
    var connectedServices: [String]

    init() {
        hasCompletedOnboarding = false
        appearanceRaw = AppearanceMode.light.rawValue
        accentRaw = AccentChoice.burgundy.rawValue
        densityRaw = CardDensity.comfortable.rawValue
        firstWeekday = 2
        encouragementRaw = EncouragementStyle.gentle.rawValue
        showStreaks = true
        celebrationRaw = CelebrationIntensity.standard.rawValue
        motionRaw = MotionPreference.system.rawValue
        strongerBorders = false
        recapVisibilityRaw = Visibility.friends.rawValue
        profileVisibilityRaw = Visibility.friends.rawValue
        allowFriendReminders = true
        activityInFeed = true
        shareHidesPrivateDetails = true
        showConsistencyOnProfile = true
        soundsEnabled = true
        completionSounds = true
        recapSounds = true
        soundVolume = 0.6
        hapticsEnabled = true
        reducedHaptics = false
        celebrationHaptics = true
        notificationsEnabled = true
        notifyReminders = true
        notifyFriends = true
        notifyReactions = true
        notifyGroups = true
        notifyAwards = true
        notifyRecap = true
        notifyQuizzes = true
        quietHoursEnabled = true
        quietStartMinutes = 22 * 60 + 30
        quietEndMinutes = 7 * 60
        connectedServices = []
    }

    var appearance: AppearanceMode {
        get { AppearanceMode(rawValue: appearanceRaw) ?? .light }
        set { appearanceRaw = newValue.rawValue }
    }

    var accent: AccentChoice {
        get { AccentChoice(rawValue: accentRaw) ?? .burgundy }
        set { accentRaw = newValue.rawValue }
    }

    var density: CardDensity {
        get { CardDensity(rawValue: densityRaw) ?? .comfortable }
        set { densityRaw = newValue.rawValue }
    }

    var encouragement: EncouragementStyle {
        get { EncouragementStyle(rawValue: encouragementRaw) ?? .gentle }
        set { encouragementRaw = newValue.rawValue }
    }

    var celebration: CelebrationIntensity {
        get { CelebrationIntensity(rawValue: celebrationRaw) ?? .standard }
        set { celebrationRaw = newValue.rawValue }
    }

    var motion: MotionPreference {
        get { MotionPreference(rawValue: motionRaw) ?? .system }
        set { motionRaw = newValue.rawValue }
    }

    var recapVisibility: Visibility {
        get { Visibility(rawValue: recapVisibilityRaw) ?? .friends }
        set { recapVisibilityRaw = newValue.rawValue }
    }

    var profileVisibility: Visibility {
        get { Visibility(rawValue: profileVisibilityRaw) ?? .friends }
        set { profileVisibilityRaw = newValue.rawValue }
    }

    func isQuiet(atMinutes minutes: Int) -> Bool {
        guard quietHoursEnabled else { return false }
        if quietStartMinutes <= quietEndMinutes {
            return minutes >= quietStartMinutes && minutes < quietEndMinutes
        }
        return minutes >= quietStartMinutes || minutes < quietEndMinutes
    }
}

enum ModelSchema {
    static let models: [any PersistentModel.Type] = [
        UserProfile.self, Friend.self, Habit.self, HabitSchedule.self, CheckIn.self,
        ActivityItem.self, Reaction.self, Comment.self, Reminder.self, Gift.self,
        HabitGroup.self, Challenge.self, Collectible.self, CosmeticItem.self,
        Quiz.self, QuizResponse.self, WeeklyRecap.self, NotificationItem.self, AppPreferences.self,
    ]
}
