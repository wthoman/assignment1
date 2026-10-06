import Foundation
import SwiftData

extension AppModel {
    func createGroup(name: String, detail: String, symbol: String, tint: TintToken, memberIDs: Set<UUID>) -> HabitGroup {
        let group = HabitGroup(name: name.cleaned(max: 40), detail: detail.cleaned(max: 140), symbol: symbol, tint: tint, memberIDs: Array(memberIDs))
        context.insert(group)
        if prefs.activityInFeed {
            context.insert(ActivityItem(kind: .joinedGroup, actorID: nil, title: "Started \(group.name)", detail: group.detail, symbol: symbol, tint: tint, groupID: group.id))
        }
        save()
        feedback(.send)
        showToast("\(group.name) is ready.", symbol: "person.3.fill", tint: tint)
        unlock("housewarming", reason: "Started \(group.name)")
        return group
    }

    func updateGroup(_ group: HabitGroup, name: String, detail: String, symbol: String, tint: TintToken, memberIDs: Set<UUID>) {
        group.name = name.cleaned(max: 40)
        group.detail = detail.cleaned(max: 140)
        group.symbol = symbol
        group.tint = tint
        group.memberIDs = Array(memberIDs)
        save()
        showToast("Saved \(group.name).", symbol: "checkmark.circle.fill", tint: tint)
    }

    func join(_ group: HabitGroup) {
        group.isMember = true
        group.isInvited = false
        resolveNotifications(refID: group.id, resolution: "accepted")
        save()
        feedback(.send)
        showToast("Welcome to \(group.name)!", symbol: "person.3.fill", tint: group.tint)
        unlock("housewarming", reason: "Joined \(group.name)")
    }

    func declineInvite(_ group: HabitGroup) {
        group.isInvited = false
        resolveNotifications(refID: group.id, resolution: "declined")
        save()
        feedback(.selection)
    }

    func leave(_ group: HabitGroup) {
        group.isMember = false
        for habit in allHabits() where habit.groupID == group.id { habit.groupID = nil }
        save()
        showToast("You left \(group.name).", symbol: "rectangle.portrait.and.arrow.right", tint: .cream)
    }

    func invite(_ friendIDs: Set<UUID>, to group: HabitGroup) {
        let newIDs = friendIDs.subtracting(group.memberIDs)
        guard !newIDs.isEmpty else { return }
        group.memberIDs.append(contentsOf: newIDs)
        save()
        feedback(.send)
        let names = newIDs.compactMap { friend($0)?.firstName }
        showToast("Invited \(ListFormatter.localizedString(byJoining: names)).", symbol: "paperplane.fill", tint: group.tint)
    }

    func setNotify(_ level: GroupNotifyLevel, for group: HabitGroup) {
        group.notify = level
        save()
        feedback(.selection)
    }

    func linkHabit(_ habit: Habit?, to group: HabitGroup) {
        for other in allHabits() where other.groupID == group.id { other.groupID = nil }
        habit?.groupID = group.id
        save()
    }

    // MARK: Challenges

    func createChallenge(in group: HabitGroup, title: String, detail: String, symbol: String, unit: String, goal: Int, days: Int, kind: ChallengeKind) {
        let start = Day.today
        let challenge = Challenge(title: title.cleaned(max: 60), detail: detail.cleaned(max: 140), symbol: symbol, unit: unit.cleaned(max: 24),
                                  goal: kind == .prediction ? 1 : max(1, goal), startDate: start, endDate: Day.add(max(1, days) - 1, to: start), kind: kind)
        group.challenges.append(challenge)
        if kind == .collective {
            // Friends get a head start so the bar isn't empty.
            for id in group.memberIDs.prefix(3) { challenge.add(Int.random(in: 0...2), for: id) }
        }
        save()
        feedback(.send)
        showToast("Challenge started in \(group.name).", symbol: "flag.fill", tint: group.tint)
    }

    /// Adds to the user's contribution. Crossing a milestone or the goal triggers feedback.
    func logContribution(_ challenge: Challenge, amount: Int = 1, silent: Bool = false) {
        let before = challenge.progress
        challenge.add(amount, for: meID)
        let after = challenge.progress
        save()

        if after >= 1, before < 1, challenge.completedAt == nil {
            challenge.completedAt = Date()
            celebrateGoal(challenge)
            return
        }
        if let crossed = [25, 50, 75].first(where: { Double($0) / 100 > before && Double($0) / 100 <= after }) {
            feedback(.milestone)
            showToast("\(challenge.group?.name ?? "Group") hit \(crossed)%!", symbol: "flag.fill", tint: challenge.group?.tint ?? .sage)
            if let group = challenge.group, group.notify != .off {
                addNotification(.groupMilestone, title: "\(group.name) hit \(crossed)%", body: challenge.title, refID: group.id)
            }
            save()
            return
        }
        if !silent {
            feedback(amount > 0 ? .complete : .undo)
        }
    }

    private func celebrateGoal(_ challenge: Challenge) {
        let group = challenge.group
        if let group, prefs.activityInFeed {
            context.insert(ActivityItem(kind: .groupMilestone, actorID: nil, title: "\(group.name) reached the goal",
                                        detail: "\(challenge.total) \(challenge.unit) together — \(challenge.title).", symbol: "flag.checkered", tint: group.tint, groupID: group.id))
        }
        if let group, group.notify != .off {
            addNotification(.groupMilestone, title: "\(group.name) reached the goal!", body: challenge.title, refID: group.id)
        }
        save()
        feedback(.groupGoal)
        if prefs.celebration == .subtle {
            showToast("Goal reached: \(challenge.title)", symbol: "flag.checkered", tint: group?.tint ?? .sage)
        } else {
            celebratingChallenge = challenge
        }
        unlock("goal-reached", reason: "Helped \(group?.name ?? "your group") finish “\(challenge.title)”", reveal: prefs.celebration != .subtle)
    }

    func finishCelebration() {
        celebratingChallenge?.celebrated = true
        celebratingChallenge = nil
        save()
    }

    func reactToMilestone(_ challenge: Challenge, milestone: Int) {
        guard !challenge.reactedMilestones.contains(milestone) else { return }
        challenge.reactedMilestones.append(milestone)
        save()
        feedback(.send)
        showToast("Cheered the \(milestone)% mark.", symbol: "hands.clap.fill", tint: challenge.group?.tint ?? .gold)
        unlock("halfway-toast", reason: "Toasted \(challenge.group?.name ?? "your group") at \(milestone)%")
    }

    func predict(_ challenge: Challenge, winner choiceID: UUID) {
        var votes = challenge.votes.filter { $0.voterID != meID }
        votes.append(PredictionVote(voterID: meID, choiceID: choiceID))
        challenge.votes = votes
        save()
        feedback(.send)
        showToast("Prediction locked in.", symbol: "wand.and.stars", tint: .ink)
    }

    /// Demo helper: decide a prediction now (most-voted wins).
    func resolvePrediction(_ challenge: Challenge) {
        var counts: [UUID: Int] = [:]
        challenge.votes.forEach { counts[$0.choiceID, default: 0] += 1 }
        guard let winner = counts.max(by: { $0.value < $1.value })?.key else { return }
        challenge.winnerID = winner
        challenge.completedAt = Date()
        let myPick = challenge.votes.first { $0.voterID == meID }?.choiceID
        let winnerName = winner == meID ? "You" : (friend(winner)?.firstName ?? "A friend")
        if prefs.activityInFeed {
            context.insert(ActivityItem(kind: .prediction, actorID: nil, title: "Prediction result",
                                        detail: "\(winnerName) finished first in “\(challenge.title)”.", symbol: "wand.and.stars", tint: .ink, groupID: challenge.group?.id))
        }
        save()
        if myPick == winner {
            feedback(.groupGoal)
            showToast("You called it! \(winnerName) finished first.", symbol: "wand.and.stars", tint: .ink)
            unlock("oracle", reason: "Predicted \(winnerName) in “\(challenge.title)”")
        } else {
            feedback(.milestone)
            showToast("\(winnerName) finished first.", symbol: "wand.and.stars", tint: .ink)
        }
    }
}
