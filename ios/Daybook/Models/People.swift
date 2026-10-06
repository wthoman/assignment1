import Foundation
import SwiftData

/// The local account holder. There is exactly one.
@Model
final class UserProfile {
    var id: UUID
    var name: String
    var handle: String
    var bio: String
    var pronouns: String
    var email: String
    var avatar: AvatarConfig
    var personalityRaw: String?
    var interests: [String]
    var joinedAt: Date
    var isDemo: Bool
    /// Collectible keys pinned to the profile showcase, in order.
    var showcaseKeys: [String]
    // Power-ups received from friends.
    var reminderPasses: Int
    var comebackBoosts: Int
    var doubleReactionTokens: Int

    init(
        id: UUID = UUID(), name: String, handle: String, bio: String = "", pronouns: String = "",
        email: String = "", avatar: AvatarConfig = AvatarConfig(), personality: PersonalityType? = nil,
        interests: [String] = [], joinedAt: Date = Date(), isDemo: Bool = false
    ) {
        self.id = id
        self.name = name
        self.handle = handle
        self.bio = bio
        self.pronouns = pronouns
        self.email = email
        self.avatar = avatar
        self.personalityRaw = personality?.rawValue
        self.interests = interests
        self.joinedAt = joinedAt
        self.isDemo = isDemo
        self.showcaseKeys = []
        self.reminderPasses = 0
        self.comebackBoosts = 0
        self.doubleReactionTokens = 0
    }

    var personality: PersonalityType? {
        get { personalityRaw.flatMap(PersonalityType.init(rawValue:)) }
        set { personalityRaw = newValue?.rawValue }
    }
}

/// Another person in the user's circle. Friends are mock, seeded locally.
@Model
final class Friend {
    var id: UUID
    var name: String
    var handle: String
    var bio: String
    var pronouns: String
    var avatar: AvatarConfig
    var personalityRaw: String
    var statusRaw: String
    var contactDetail: String
    var mutualFriendCount: Int
    var allowsReminders: Bool
    // Seeded activity stats (a backend would compute these).
    var consistency: Double
    var previousConsistency: Double
    var totalCompletions: Int
    var weekCompletions: Int
    var comebackCount: Int
    var lateNightCheckIns: Int
    var weekendCheckIns: Int
    var remindersSent: Int
    var strongestWeekday: Int
    var favoriteHabits: [String]
    var showcaseKeys: [String]
    var lastActive: Date
    var since: Date

    init(
        id: UUID = UUID(), name: String, handle: String, bio: String, pronouns: String = "",
        avatar: AvatarConfig, personality: PersonalityType, status: FriendStatus,
        contactDetail: String = "", mutualFriendCount: Int = 0
    ) {
        self.id = id
        self.name = name
        self.handle = handle
        self.bio = bio
        self.pronouns = pronouns
        self.avatar = avatar
        self.personalityRaw = personality.rawValue
        self.statusRaw = status.rawValue
        self.contactDetail = contactDetail
        self.mutualFriendCount = mutualFriendCount
        self.allowsReminders = true
        self.consistency = 0.7
        self.previousConsistency = 0.6
        self.totalCompletions = 0
        self.weekCompletions = 0
        self.comebackCount = 0
        self.lateNightCheckIns = 0
        self.weekendCheckIns = 0
        self.remindersSent = 0
        self.strongestWeekday = 2
        self.favoriteHabits = []
        self.showcaseKeys = []
        self.lastActive = Date()
        self.since = Date()
    }

    var status: FriendStatus {
        get { FriendStatus(rawValue: statusRaw) ?? .suggested }
        set { statusRaw = newValue.rawValue }
    }

    var personality: PersonalityType {
        PersonalityType(rawValue: personalityRaw) ?? .gentleBuilder
    }

    var firstName: String { name.firstName }
}
