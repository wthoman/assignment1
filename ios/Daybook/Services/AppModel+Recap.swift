import Foundation
import SwiftData

extension AppModel {
    /// Gathers this week's data from SwiftData and runs the recap engine.
    func buildRecap() -> RecapData {
        let habits = allHabits().filter { $0.status != .archived }
        let friends = self.friends()
        let weekStart = Day.add(-6, to: Day.today)
        let reactions = (try? context.fetch(FetchDescriptor<Reaction>())) ?? []
        let comments = (try? context.fetch(FetchDescriptor<Comment>())) ?? []
        let reminders = (try? context.fetch(FetchDescriptor<Reminder>())) ?? []
        let quizzes = (try? context.fetch(FetchDescriptor<Quiz>())) ?? []
        let groups = (try? context.fetch(FetchDescriptor<HabitGroup>())) ?? []
        let collectibles = (try? context.fetch(FetchDescriptor<Collectible>())) ?? []

        let habitInputs = habits.map { habit in
            RecapEngine.HabitInput(
                name: habit.name, symbol: habit.symbol, tint: habit.tint, rule: habit.rule, start: habit.startDate,
                completions: Dictionary(habit.myCheckIns.map { ($0.day, $0.completedAt) }, uniquingKeysWith: { a, _ in a }),
                countsToward: habit.countsTowardConsistency)
        }

        func votes(for id: UUID) -> [String: Int] {
            var result: [String: Int] = [:]
            for quiz in quizzes { result[quiz.tag, default: 0] += quiz.votes(for: id) }
            return result
        }

        let me = RecapPerson(id: meID, name: me?.name ?? "You", avatar: me?.avatar ?? AvatarConfig(), isMe: true,
                             completions: 0, lateNight: 0, weekend: 0, comebacks: 0, remindersSent: 0,
                             consistency: 0, previousConsistency: 0, votes: votes(for: meID))
        let people = friends.map { friend in
            RecapPerson(id: friend.id, name: friend.name, avatar: friend.avatar, isMe: false,
                        completions: friend.weekCompletions, lateNight: friend.lateNightCheckIns, weekend: friend.weekendCheckIns,
                        comebacks: friend.comebackCount, remindersSent: friend.remindersSent,
                        consistency: friend.consistency, previousConsistency: friend.previousConsistency, votes: votes(for: friend.id))
        }

        let myActivityIDs = Set(((try? context.fetch(FetchDescriptor<ActivityItem>())) ?? []).filter { $0.actorID == nil }.map(\.id))
        let goals = groups.filter(\.isMember).flatMap { group in
            group.challenges.filter { $0.kind == .collective && $0.endDate >= weekStart }.map {
                RecapData.GoalLine(group: group.name, title: $0.title, progress: $0.progress, tint: group.tint, total: $0.total, goal: $0.goal)
            }
        }
        let predictions = groups.flatMap(\.challenges).filter { $0.kind == .prediction }.map { challenge -> String in
            if let winner = challenge.winnerID {
                let name = winner == meID ? "You" : (friend(winner)?.firstName ?? "A friend")
                let called = challenge.votes.contains { $0.voterID == meID && $0.choiceID == winner }
                return "\(name) won “\(challenge.title)”. \(called ? "You called it!" : "Better luck next time.")"
            }
            var tally: [UUID: Int] = [:]
            challenge.votes.forEach { tally[$0.choiceID, default: 0] += 1 }
            let favorite = tally.max { $0.value < $1.value }?.key
            let favoriteName = favorite.map { $0 == meID ? "you" : (friend($0)?.firstName ?? "a friend") } ?? "nobody yet"
            return "“\(challenge.title)” — the group's favorite is \(favoriteName)."
        }
        let newest = collectibles.filter { $0.isUnlocked && ($0.earnedAt ?? .distantPast) >= Day.add(-7, to: weekStart) }
            .max { ($0.earnedAt ?? .distantPast) < ($1.earnedAt ?? .distantPast) }

        let input = RecapEngine.Inputs(
            me: me, friends: people, habits: habitInputs,
            reactionsSent: reactions.filter { $0.authorID == nil && $0.createdAt >= weekStart }.count,
            reactionsReceived: reactions.filter { $0.authorID != nil && $0.activity.map { myActivityIDs.contains($0.id) } == true }.count,
            commentsSent: comments.filter { $0.authorID == nil && $0.createdAt >= weekStart }.count,
            remindersSent: reminders.filter { $0.fromID == nil && $0.createdAt >= weekStart }.count,
            goals: goals, newestCollectibleKey: newest?.key, predictions: predictions)
        return RecapEngine.build(input)
    }
}
