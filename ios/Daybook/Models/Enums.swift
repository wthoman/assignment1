import Foundation

// SwiftData stores these as raw strings on the models (predicates and migrations stay simple),
// and each model exposes a typed computed property.

enum HabitCategory: String, Codable, CaseIterable, Identifiable {
    case movement, hydration, mind, sleep, study, nourish, creative, outdoors, home, social

    var id: String { rawValue }

    var label: String {
        switch self {
        case .movement: "Movement"
        case .hydration: "Hydration"
        case .mind: "Mind"
        case .sleep: "Sleep"
        case .study: "Study"
        case .nourish: "Nourish"
        case .creative: "Creative"
        case .outdoors: "Outdoors"
        case .home: "Home"
        case .social: "Social"
        }
    }

    var defaultSymbol: String {
        switch self {
        case .movement: "figure.walk"
        case .hydration: "drop.fill"
        case .mind: "leaf.fill"
        case .sleep: "moon.stars.fill"
        case .study: "book.fill"
        case .nourish: "carrot.fill"
        case .creative: "paintbrush.pointed.fill"
        case .outdoors: "tree.fill"
        case .home: "house.fill"
        case .social: "phone.fill"
        }
    }

    var defaultTint: TintToken {
        switch self {
        case .movement: .orange
        case .hydration: .sky
        case .mind: .rose
        case .sleep: .sky
        case .study: .gold
        case .nourish: .sage
        case .creative: .rose
        case .outdoors: .sage
        case .home: .gold
        case .social: .burgundy
        }
    }

    /// Symbols offered in the habit form for this category (first is the default).
    var symbolChoices: [String] {
        switch self {
        case .movement: ["figure.walk", "figure.run", "dumbbell.fill", "bicycle", "figure.yoga", "figure.pool.swim"]
        case .hydration: ["drop.fill", "waterbottle.fill", "cup.and.saucer.fill", "mug.fill"]
        case .mind: ["leaf.fill", "brain.head.profile", "heart.text.square.fill", "sparkles", "wind"]
        case .sleep: ["moon.stars.fill", "bed.double.fill", "alarm.fill", "powersleep"]
        case .study: ["book.fill", "pencil.and.ruler.fill", "graduationcap.fill", "text.book.closed.fill", "lightbulb.fill"]
        case .nourish: ["carrot.fill", "fork.knife", "takeoutbag.and.cup.and.straw.fill", "frying.pan.fill"]
        case .creative: ["paintbrush.pointed.fill", "music.note", "guitars.fill", "camera.fill", "pencil.line"]
        case .outdoors: ["tree.fill", "sun.max.fill", "mountain.2.fill", "figure.hiking", "cloud.sun.fill"]
        case .home: ["house.fill", "sparkles.rectangle.stack.fill", "washer.fill", "camera.macro", "basket.fill"]
        case .social: ["phone.fill", "envelope.fill", "person.2.fill", "bubble.left.and.bubble.right.fill"]
        }
    }
}

enum Frequency: String, Codable, CaseIterable, Identifiable {
    case daily, weekdays, weekends, custom, timesPerWeek

    var id: String { rawValue }

    var label: String {
        switch self {
        case .daily: "Every day"
        case .weekdays: "Weekdays"
        case .weekends: "Weekends"
        case .custom: "Specific days"
        case .timesPerWeek: "Times per week"
        }
    }
}

enum TimeOfDay: String, Codable, CaseIterable, Identifiable {
    case morning, afternoon, evening, anytime

    var id: String { rawValue }

    var label: String {
        switch self {
        case .morning: "Morning"
        case .afternoon: "Afternoon"
        case .evening: "Evening"
        case .anytime: "Anytime"
        }
    }

    var symbol: String {
        switch self {
        case .morning: "sunrise.fill"
        case .afternoon: "sun.max.fill"
        case .evening: "moon.fill"
        case .anytime: "clock.fill"
        }
    }

    /// Default scheduled time, in minutes after midnight.
    var defaultMinutes: Int {
        switch self {
        case .morning: 7 * 60 + 30
        case .afternoon: 13 * 60
        case .evening: 21 * 60
        case .anytime: 12 * 60
        }
    }
}

enum Visibility: String, Codable, CaseIterable, Identifiable {
    case onlyMe, friends, groups

    var id: String { rawValue }

    var label: String {
        switch self {
        case .onlyMe: "Only me"
        case .friends: "Friends"
        case .groups: "My groups"
        }
    }

    var symbol: String {
        switch self {
        case .onlyMe: "lock.fill"
        case .friends: "person.2.fill"
        case .groups: "person.3.fill"
        }
    }
}

enum ProofMode: String, Codable, CaseIterable, Identifiable {
    case off, optional, encouraged

    var id: String { rawValue }

    var label: String {
        switch self {
        case .off: "Off"
        case .optional: "Optional"
        case .encouraged: "Encouraged"
        }
    }
}

enum HabitStatus: String, Codable, CaseIterable {
    case active, paused, archived
}

enum ReactionKind: String, Codable, CaseIterable, Identifiable {
    case cheer, fire, clap, heart, wow

    var id: String { rawValue }

    var symbol: String {
        switch self {
        case .cheer: "hands.sparkles.fill"
        case .fire: "flame.fill"
        case .clap: "hands.clap.fill"
        case .heart: "heart.fill"
        case .wow: "star.fill"
        }
    }

    var label: String {
        switch self {
        case .cheer: "Cheer"
        case .fire: "On fire"
        case .clap: "Applause"
        case .heart: "Love"
        case .wow: "Gold star"
        }
    }

    var tint: TintToken {
        switch self {
        case .cheer: .gold
        case .fire: .orange
        case .clap: .sage
        case .heart: .rose
        case .wow: .burgundy
        }
    }
}

enum ActivityKind: String, Codable, CaseIterable {
    case checkIn, comeback, sharedHabit, groupMilestone, prediction, ranking, reminder, gift, collectible, joinedGroup

    var symbol: String {
        switch self {
        case .checkIn: "checkmark.seal.fill"
        case .comeback: "arrow.uturn.up.circle.fill"
        case .sharedHabit: "person.2.fill"
        case .groupMilestone: "flag.checkered"
        case .prediction: "wand.and.stars"
        case .ranking: "list.number"
        case .reminder: "bell.fill"
        case .gift: "gift.fill"
        case .collectible: "seal.fill"
        case .joinedGroup: "person.3.fill"
        }
    }
}

enum FriendStatus: String, Codable, CaseIterable {
    /// Mutual friend.
    case friend
    /// They asked to be your friend.
    case incoming
    /// You asked them.
    case requested
    /// A contact who uses the app but is not connected.
    case suggested
    case blocked
}

enum GroupNotifyLevel: String, Codable, CaseIterable, Identifiable {
    case all, milestones, off

    var id: String { rawValue }

    var label: String {
        switch self {
        case .all: "Everything"
        case .milestones: "Milestones only"
        case .off: "Off"
        }
    }
}

enum ChallengeKind: String, Codable, CaseIterable, Identifiable {
    /// Everyone adds to a shared total.
    case collective
    /// Friends predict who will finish first.
    case prediction

    var id: String { rawValue }

    var label: String {
        switch self {
        case .collective: "Collective goal"
        case .prediction: "Prediction"
        }
    }
}

enum CollectibleForm: String, Codable, CaseIterable {
    case sticker, stamp, badge
}

enum CollectibleCategory: String, Codable, CaseIterable, Identifiable {
    case firsts, consistency, streak, comeback, social, group, superlative, gifted

    var id: String { rawValue }

    var label: String {
        switch self {
        case .firsts: "First steps"
        case .consistency: "Consistency awards"
        case .streak: "Streak awards"
        case .comeback: "Comeback awards"
        case .social: "Social awards"
        case .group: "Group awards"
        case .superlative: "Weekly superlatives"
        case .gifted: "Gifts from friends"
        }
    }

    var shortLabel: String {
        switch self {
        case .firsts: "Firsts"
        case .consistency: "Steady"
        case .streak: "Streaks"
        case .comeback: "Comebacks"
        case .social: "Social"
        case .group: "Groups"
        case .superlative: "Awards"
        case .gifted: "Gifts"
        }
    }

    var annotation: String {
        switch self {
        case .firsts: "where it all started"
        case .consistency: "slow & steady"
        case .streak: "no skipping!"
        case .comeback: "back again :)"
        case .social: "for the cheerleaders"
        case .group: "team effort"
        case .superlative: "and the award goes to…"
        case .gifted: "from friends, with love"
        }
    }
}

enum Rarity: String, Codable, CaseIterable, Comparable {
    case common, uncommon, rare, legendary

    var label: String { rawValue.capitalized }

    var rank: Int {
        switch self {
        case .common: 0
        case .uncommon: 1
        case .rare: 2
        case .legendary: 3
        }
    }

    var dots: Int { rank + 1 }

    static func < (lhs: Rarity, rhs: Rarity) -> Bool { lhs.rank < rhs.rank }
}

enum StickerShape: String, Codable, CaseIterable {
    case circle, scallop, star, ticket, stamp, ribbon, heart, badge
}

enum NotificationKind: String, Codable, CaseIterable {
    case friendRequest, groupInvite, habitInvite, reminder, reaction, comment, award, recap, quiz, groupMilestone, gift

    var symbol: String {
        switch self {
        case .friendRequest: "person.badge.plus"
        case .groupInvite: "person.3.fill"
        case .habitInvite: "person.2.badge.gearshape.fill"
        case .reminder: "bell.fill"
        case .reaction: "hands.clap.fill"
        case .comment: "text.bubble.fill"
        case .award: "seal.fill"
        case .recap: "film.stack.fill"
        case .quiz: "questionmark.bubble.fill"
        case .groupMilestone: "flag.checkered"
        case .gift: "gift.fill"
        }
    }

    var tint: TintToken {
        switch self {
        case .friendRequest, .habitInvite: .sky
        case .groupInvite, .groupMilestone: .sage
        case .reminder: .gold
        case .reaction, .comment: .rose
        case .award, .recap: .burgundy
        case .quiz: .orange
        case .gift: .gold
        }
    }

    var isInvitation: Bool {
        self == .friendRequest || self == .groupInvite || self == .habitInvite
    }
}

enum CosmeticSlot: String, Codable, CaseIterable, Identifiable {
    case hair, outfit, accessory, background, frame, companion

    var id: String { rawValue }

    var label: String {
        switch self {
        case .hair: "Hair"
        case .outfit: "Outfit"
        case .accessory: "Accessory"
        case .background: "Background"
        case .frame: "Frame"
        case .companion: "Companion"
        }
    }
}

enum GiftKind: String, Codable, CaseIterable, Identifiable {
    case reminderPass, comebackBoost, doubleReaction, cosmetic, sticker

    var id: String { rawValue }

    var label: String {
        switch self {
        case .reminderPass: "Reminder pass"
        case .comebackBoost: "Comeback boost"
        case .doubleReaction: "Double-reaction token"
        case .cosmetic: "Cosmetic item"
        case .sticker: "Decorative sticker"
        }
    }

    var detail: String {
        switch self {
        case .reminderPass: "Skip one reminder without it counting as a miss on your weekly sheet."
        case .comebackBoost: "Their next comeback check-in earns a bonus stamp."
        case .doubleReaction: "Their next reaction lands twice as loud."
        case .cosmetic: "Share an avatar item you've unlocked."
        case .sticker: "Send a decorative sticker for their book."
        }
    }

    var symbol: String {
        switch self {
        case .reminderPass: "ticket.fill"
        case .comebackBoost: "arrow.uturn.up.circle.fill"
        case .doubleReaction: "hands.clap.fill"
        case .cosmetic: "tshirt.fill"
        case .sticker: "seal.fill"
        }
    }

    var tint: TintToken {
        switch self {
        case .reminderPass: .sky
        case .comebackBoost: .orange
        case .doubleReaction: .rose
        case .cosmetic: .sage
        case .sticker: .gold
        }
    }
}

enum PersonalityType: String, Codable, CaseIterable, Identifiable {
    case gentleBuilder, deadlineSprinter, socialMotivator, quietPerfectionist, varietySeeker

    var id: String { rawValue }
}

// MARK: - Preferences enums

enum AppearanceMode: String, Codable, CaseIterable, Identifiable {
    case light, dark, system

    var id: String { rawValue }

    var label: String {
        switch self {
        case .light: "Light"
        case .dark: "Dark"
        case .system: "Match system"
        }
    }
}

enum CardDensity: String, Codable, CaseIterable, Identifiable {
    case compact, comfortable

    var id: String { rawValue }
    var label: String { rawValue.capitalized }
}

enum EncouragementStyle: String, Codable, CaseIterable, Identifiable {
    case gentle, cheeky, coach

    var id: String { rawValue }
    var label: String { rawValue.capitalized }
}

enum CelebrationIntensity: String, Codable, CaseIterable, Identifiable {
    case subtle, standard, big

    var id: String { rawValue }

    var label: String {
        switch self {
        case .subtle: "Subtle"
        case .standard: "Standard"
        case .big: "Big moments"
        }
    }
}

enum MotionPreference: String, Codable, CaseIterable, Identifiable {
    case system, reduced, full

    var id: String { rawValue }

    var label: String {
        switch self {
        case .system: "Match system"
        case .reduced: "Reduced"
        case .full: "Full"
        }
    }
}

enum ServiceStatus: String, Codable, CaseIterable {
    case connected, disconnected
}
