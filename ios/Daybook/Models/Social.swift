import Foundation
import SwiftData

@Model
final class CheckIn {
    var id: UUID
    var habit: Habit?
    /// nil for the current user, otherwise the friend who checked in on a shared habit.
    var friendID: UUID?
    /// Start of the local day this check-in counts for.
    var day: Date
    var completedAt: Date
    var note: String
    @Attribute(.externalStorage) var photoData: Data?
    var isComeback: Bool

    init(id: UUID = UUID(), habit: Habit?, friendID: UUID? = nil, day: Date, completedAt: Date = Date(), note: String = "", isComeback: Bool = false) {
        self.id = id
        self.habit = habit
        self.friendID = friendID
        self.day = Day.start(day)
        self.completedAt = completedAt
        self.note = note
        self.photoData = nil
        self.isComeback = isComeback
    }

    var hasPhoto: Bool { photoData != nil }
    var hasNote: Bool { !note.isEmpty }
}

/// An entry in the social feed. Friends' activity is seeded; the user's own check-ins add entries too.
@Model
final class ActivityItem {
    var id: UUID
    var kindRaw: String
    /// nil when the actor is the current user.
    var actorID: UUID?
    var title: String
    var detail: String
    var symbol: String
    var tintRaw: String
    var habitID: UUID?
    var groupID: UUID?
    var createdAt: Date
    var celebratedByMe: Bool
    var remindedByMe: Bool
    @Relationship(deleteRule: .cascade, inverse: \Reaction.activity)
    var reactions: [Reaction] = []
    @Relationship(deleteRule: .cascade, inverse: \Comment.activity)
    var comments: [Comment] = []

    init(
        id: UUID = UUID(), kind: ActivityKind, actorID: UUID?, title: String, detail: String = "",
        symbol: String? = nil, tint: TintToken = .burgundy, habitID: UUID? = nil, groupID: UUID? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.kindRaw = kind.rawValue
        self.actorID = actorID
        self.title = title
        self.detail = detail
        self.symbol = symbol ?? kind.symbol
        self.tintRaw = tint.rawValue
        self.habitID = habitID
        self.groupID = groupID
        self.createdAt = createdAt
        self.celebratedByMe = false
        self.remindedByMe = false
    }

    var kind: ActivityKind { ActivityKind(rawValue: kindRaw) ?? .checkIn }
    var tint: TintToken { TintToken(rawValue: tintRaw) ?? .burgundy }

    func myReaction() -> Reaction? { reactions.first { $0.authorID == nil } }
}

@Model
final class Reaction {
    var id: UUID
    var kindRaw: String
    /// nil when sent by the current user.
    var authorID: UUID?
    var createdAt: Date
    var activity: ActivityItem?

    init(id: UUID = UUID(), kind: ReactionKind, authorID: UUID?, createdAt: Date = Date()) {
        self.id = id
        self.kindRaw = kind.rawValue
        self.authorID = authorID
        self.createdAt = createdAt
    }

    var kind: ReactionKind { ReactionKind(rawValue: kindRaw) ?? .cheer }
}

@Model
final class Comment {
    var id: UUID
    var authorID: UUID?
    var text: String
    var createdAt: Date
    var activity: ActivityItem?

    init(id: UUID = UUID(), authorID: UUID?, text: String, createdAt: Date = Date()) {
        self.id = id
        self.authorID = authorID
        self.text = text
        self.createdAt = createdAt
    }
}

/// A supportive nudge between people. nil ids mean the current user.
@Model
final class Reminder {
    var id: UUID
    var fromID: UUID?
    var toID: UUID?
    var habitName: String
    var message: String
    var createdAt: Date

    init(id: UUID = UUID(), fromID: UUID?, toID: UUID?, habitName: String, message: String, createdAt: Date = Date()) {
        self.id = id
        self.fromID = fromID
        self.toID = toID
        self.habitName = habitName
        self.message = message
        self.createdAt = createdAt
    }
}

/// A free, non-purchasable gift between friends.
@Model
final class Gift {
    var id: UUID
    var kindRaw: String
    var fromID: UUID?
    var toID: UUID?
    /// Cosmetic or collectible key for item gifts.
    var itemKey: String?
    var message: String
    var createdAt: Date
    var opened: Bool

    init(id: UUID = UUID(), kind: GiftKind, fromID: UUID?, toID: UUID?, itemKey: String? = nil, message: String, createdAt: Date = Date(), opened: Bool = false) {
        self.id = id
        self.kindRaw = kind.rawValue
        self.fromID = fromID
        self.toID = toID
        self.itemKey = itemKey
        self.message = message
        self.createdAt = createdAt
        self.opened = opened
    }

    var kind: GiftKind { GiftKind(rawValue: kindRaw) ?? .sticker }
}
