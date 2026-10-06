import Foundation
import SwiftData

/// A sticker, stamp or badge. The full catalog is seeded; `isUnlocked` tracks progress.
@Model
final class Collectible {
    @Attribute(.unique) var key: String
    var name: String
    var formRaw: String
    var categoryRaw: String
    var rarityRaw: String
    var shapeRaw: String
    var symbol: String
    var tintRaw: String
    var blurb: String
    var howToEarn: String
    var isUnlocked: Bool
    var earnedAt: Date?
    var earnedFor: String
    var isFavorite: Bool
    var isSeen: Bool
    var giftedByID: UUID?
    var sortIndex: Int

    init(
        key: String, name: String, form: CollectibleForm, category: CollectibleCategory, rarity: Rarity,
        shape: StickerShape, symbol: String, tint: TintToken, blurb: String, howToEarn: String, sortIndex: Int
    ) {
        self.key = key
        self.name = name
        self.formRaw = form.rawValue
        self.categoryRaw = category.rawValue
        self.rarityRaw = rarity.rawValue
        self.shapeRaw = shape.rawValue
        self.symbol = symbol
        self.tintRaw = tint.rawValue
        self.blurb = blurb
        self.howToEarn = howToEarn
        self.isUnlocked = false
        self.earnedFor = ""
        self.isFavorite = false
        self.isSeen = true
        self.sortIndex = sortIndex
    }

    var form: CollectibleForm { CollectibleForm(rawValue: formRaw) ?? .sticker }
    var category: CollectibleCategory { CollectibleCategory(rawValue: categoryRaw) ?? .firsts }
    var rarity: Rarity { Rarity(rawValue: rarityRaw) ?? .common }
    var shape: StickerShape { StickerShape(rawValue: shapeRaw) ?? .circle }
    var tint: TintToken { TintToken(rawValue: tintRaw) ?? .burgundy }
}

/// An avatar cosmetic. Starter items are unlocked; others unlock through play or gifts.
@Model
final class CosmeticItem {
    @Attribute(.unique) var key: String
    var slotRaw: String
    /// Raw value of the matching `AvatarConfig` option.
    var value: String
    var name: String
    var unlockHint: String
    var isUnlocked: Bool
    var giftedByID: UUID?

    init(key: String, slot: CosmeticSlot, value: String, name: String, unlockHint: String, isUnlocked: Bool) {
        self.key = key
        self.slotRaw = slot.rawValue
        self.value = value
        self.name = name
        self.unlockHint = unlockHint
        self.isUnlocked = isUnlocked
    }

    var slot: CosmeticSlot { CosmeticSlot(rawValue: slotRaw) ?? .accessory }
}

/// A friend quiz ("Who is most likely to…"). Votes are `QuizResponse`s.
@Model
final class Quiz {
    var id: UUID
    var prompt: String
    /// Connects votes to a weekly superlative.
    var tag: String
    /// People you can vote for: friend ids plus the current user's id.
    var optionIDs: [UUID]
    var createdByID: UUID?
    var createdAt: Date
    @Relationship(deleteRule: .cascade, inverse: \QuizResponse.quiz)
    var responses: [QuizResponse] = []

    init(id: UUID = UUID(), prompt: String, tag: String, optionIDs: [UUID], createdByID: UUID?, createdAt: Date = Date()) {
        self.id = id
        self.prompt = prompt
        self.tag = tag
        self.optionIDs = optionIDs
        self.createdByID = createdByID
        self.createdAt = createdAt
    }

    var myResponse: QuizResponse? { responses.first { $0.voterID == nil } }

    func votes(for id: UUID) -> Int { responses.filter { $0.choiceID == id }.count }

    var leaderID: UUID? {
        optionIDs.max { votes(for: $0) < votes(for: $1) }
    }
}

@Model
final class QuizResponse {
    var id: UUID
    /// nil = the current user.
    var voterID: UUID?
    var choiceID: UUID
    var createdAt: Date
    var quiz: Quiz?

    init(id: UUID = UUID(), voterID: UUID?, choiceID: UUID, createdAt: Date = Date()) {
        self.id = id
        self.voterID = voterID
        self.choiceID = choiceID
        self.createdAt = createdAt
    }
}

/// A finished week, kept for the profile history and the Recap tab archive.
@Model
final class WeeklyRecap {
    var id: UUID
    var weekStart: Date
    var completions: Int
    var consistency: Double
    var strongestWeekday: Int
    var headline: String
    var superlativeTitle: String
    var topHabitName: String

    init(id: UUID = UUID(), weekStart: Date, completions: Int, consistency: Double, strongestWeekday: Int, headline: String, superlativeTitle: String, topHabitName: String) {
        self.id = id
        self.weekStart = weekStart
        self.completions = completions
        self.consistency = consistency
        self.strongestWeekday = strongestWeekday
        self.headline = headline
        self.superlativeTitle = superlativeTitle
        self.topHabitName = topHabitName
    }
}

@Model
final class NotificationItem {
    var id: UUID
    var kindRaw: String
    var actorID: UUID?
    var title: String
    var body: String
    var createdAt: Date
    var isRead: Bool
    /// Habit, group or friend this item refers to (used by invitations).
    var refID: UUID?
    /// "accepted" / "declined" once an invitation has been answered.
    var resolution: String?

    init(id: UUID = UUID(), kind: NotificationKind, actorID: UUID? = nil, title: String, body: String, createdAt: Date = Date(), isRead: Bool = false, refID: UUID? = nil) {
        self.id = id
        self.kindRaw = kind.rawValue
        self.actorID = actorID
        self.title = title
        self.body = body
        self.createdAt = createdAt
        self.isRead = isRead
        self.refID = refID
    }

    var kind: NotificationKind { NotificationKind(rawValue: kindRaw) ?? .reminder }
}
