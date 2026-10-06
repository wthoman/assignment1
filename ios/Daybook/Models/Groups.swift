import Foundation
import SwiftData

/// A circle of friends working on challenges together.
/// (Named `HabitGroup` so it never shadows SwiftUI's `Group` view.)
@Model
final class HabitGroup {
    var id: UUID
    var name: String
    var detail: String
    var symbol: String
    var tintRaw: String
    /// Friend ids in the group (the current user is tracked by `isMember`).
    var memberIDs: [UUID]
    var isMember: Bool
    var isInvited: Bool
    var invitedByID: UUID?
    var createdAt: Date
    var notifyRaw: String
    @Relationship(deleteRule: .cascade, inverse: \Challenge.group)
    var challenges: [Challenge] = []

    init(
        id: UUID = UUID(), name: String, detail: String, symbol: String, tint: TintToken,
        memberIDs: [UUID], isMember: Bool = true, isInvited: Bool = false, createdAt: Date = Date(),
        notify: GroupNotifyLevel = .all
    ) {
        self.id = id
        self.name = name
        self.detail = detail
        self.symbol = symbol
        self.tintRaw = tint.rawValue
        self.memberIDs = memberIDs
        self.isMember = isMember
        self.isInvited = isInvited
        self.createdAt = createdAt
        self.notifyRaw = notify.rawValue
    }

    var tint: TintToken {
        get { TintToken(rawValue: tintRaw) ?? .sage }
        set { tintRaw = newValue.rawValue }
    }

    var notify: GroupNotifyLevel {
        get { GroupNotifyLevel(rawValue: notifyRaw) ?? .all }
        set { notifyRaw = newValue.rawValue }
    }

    var activeChallenges: [Challenge] {
        challenges.filter { !$0.isFinished }.sorted { $0.endDate < $1.endDate }
    }

    var memberCount: Int { memberIDs.count + (isMember ? 1 : 0) }
}

struct Contribution: Codable, Hashable {
    var memberID: UUID
    var count: Int
}

struct PredictionVote: Codable, Hashable {
    var voterID: UUID
    var choiceID: UUID
}

@Model
final class Challenge {
    var id: UUID
    var group: HabitGroup?
    var title: String
    var detail: String
    var symbol: String
    var unit: String
    var goal: Int
    var startDate: Date
    var endDate: Date
    var kindRaw: String
    /// Per-member totals. The current user's entry uses `UserProfile.id`.
    var contributions: [Contribution]
    /// Milestone percentages (25/50/75/100) the current user has reacted to.
    var reactedMilestones: [Int]
    var votes: [PredictionVote]
    var winnerID: UUID?
    var completedAt: Date?
    var celebrated: Bool

    init(
        id: UUID = UUID(), title: String, detail: String, symbol: String, unit: String, goal: Int,
        startDate: Date, endDate: Date, kind: ChallengeKind = .collective, contributions: [Contribution] = []
    ) {
        self.id = id
        self.title = title
        self.detail = detail
        self.symbol = symbol
        self.unit = unit
        self.goal = max(1, goal)
        self.startDate = startDate
        self.endDate = endDate
        self.kindRaw = kind.rawValue
        self.contributions = contributions
        self.reactedMilestones = []
        self.votes = []
        self.celebrated = false
    }

    var kind: ChallengeKind { ChallengeKind(rawValue: kindRaw) ?? .collective }

    var total: Int { contributions.reduce(0) { $0 + $1.count } }

    var progress: Double { min(1, Double(total) / Double(max(goal, 1))) }

    var isComplete: Bool { total >= goal || completedAt != nil }

    /// Past its end date (or a prediction that has been decided).
    var isFinished: Bool {
        if kind == .prediction, winnerID != nil { return true }
        return Day.today > Day.start(endDate)
    }

    var reachedMilestones: [Int] { [25, 50, 75, 100].filter { Double($0) / 100 <= progress + 0.0001 } }

    func count(for memberID: UUID) -> Int {
        contributions.first { $0.memberID == memberID }?.count ?? 0
    }

    func add(_ amount: Int, for memberID: UUID) {
        var list = contributions
        if let index = list.firstIndex(where: { $0.memberID == memberID }) {
            list[index].count = max(0, list[index].count + amount)
        } else {
            list.append(Contribution(memberID: memberID, count: max(0, amount)))
        }
        contributions = list
    }

    var daysLeft: Int { max(0, Day.between(Day.today, endDate)) }
}
