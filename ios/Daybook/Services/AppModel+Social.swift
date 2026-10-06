import Foundation
import SwiftData

extension AppModel {
    // MARK: Reactions & comments

    func react(_ kind: ReactionKind, to item: ActivityItem) {
        if let mine = item.myReaction() {
            if mine.kind == kind {
                context.delete(mine)
                save()
                feedback(.selection)
                return
            }
            context.delete(mine)
        }
        let reaction = Reaction(kind: kind, authorID: nil)
        context.insert(reaction)
        item.reactions.append(reaction)
        save()
        feedback(.send)
        let sent = ((try? context.fetch(FetchDescriptor<Reaction>())) ?? []).filter { $0.authorID == nil }.count
        if sent >= 10 { unlock("cheerleader", reason: "\(sent) reactions sent to friends") }
    }

    func comment(_ text: String, on item: ActivityItem) {
        let cleaned = text.cleaned(max: 140)
        guard !cleaned.isEmpty else {
            feedback(.error)
            return
        }
        let comment = Comment(authorID: nil, text: cleaned)
        context.insert(comment)
        item.comments.append(comment)
        save()
        feedback(.send)
    }

    // MARK: Reminders

    func sendReminder(to friend: Friend, habitName: String, message: String, from item: ActivityItem? = nil) {
        guard friend.allowsReminders else {
            feedback(.error)
            showToast("\(friend.firstName) has reminders turned off.", symbol: "bell.slash.fill", tint: .orange)
            return
        }
        context.insert(Reminder(fromID: nil, toID: friend.id, habitName: habitName.cleaned(max: 60), message: message.cleaned(max: 120)))
        item?.remindedByMe = true
        save()
        feedback(.send)
        showToast("Sent \(friend.firstName) a friendly nudge.", symbol: "bell.fill", tint: .gold)
        unlock("gentle-nudge", reason: "Nudged \(friend.firstName) about \(habitName)")
    }

    func celebrateComeback(_ item: ActivityItem) {
        guard !item.celebratedByMe else { return }
        item.celebratedByMe = true
        if item.myReaction() == nil {
            let reaction = Reaction(kind: .cheer, authorID: nil)
            context.insert(reaction)
            item.reactions.append(reaction)
        }
        save()
        feedback(.send)
        let name = friend(item.actorID)?.firstName ?? "your friend"
        showToast("You welcomed \(name) back.", symbol: "party.popper.fill", tint: .gold)
        unlock("welcome-committee", reason: "Celebrated \(name)'s comeback on \(item.title)")
    }

    /// Simulates a friend reacting to the user's new check-in a few seconds later.
    func maybeSimulateIncomingReaction(on item: ActivityItem, habitName: String) {
        guard Double.random(in: 0..<1) < 0.4 else { return }
        let candidates = friends()
        guard let friend = candidates.randomElement() else { return }
        let kind = ReactionKind.allCases.randomElement() ?? .cheer
        let itemID = item.id
        Task { [weak self] in
            try? await Task.sleep(for: .seconds(Double.random(in: 3.5...6)))
            await MainActor.run {
                guard let self else { return }
                let descriptor = FetchDescriptor<ActivityItem>(predicate: #Predicate { $0.id == itemID })
                guard let target = try? self.context.fetch(descriptor).first else { return }
                let reaction = Reaction(kind: kind, authorID: friend.id)
                self.context.insert(reaction)
                target.reactions.append(reaction)
                self.addNotification(.reaction, actorID: friend.id, title: "\(friend.firstName) sent \(kind.label.lowercased())", body: "On your \(habitName) check-in.")
                self.save()
                if self.prefs.notifyReactions, self.prefs.notificationsEnabled {
                    self.feedback(.reactionReceived)
                    self.showToast("\(friend.firstName) reacted to \(habitName).", symbol: kind.symbol, tint: kind.tint)
                }
            }
        }
    }

    /// Pull-to-refresh: pretend the server sent something new.
    func refreshFeed() async {
        try? await Task.sleep(for: .milliseconds(700))
        let circle = friends()
        guard let friend = circle.randomElement() else { return }
        let samples: [(String, String, String, TintToken)] = [
            ("Evening stretch", "Ten minutes, floor time counts.", "figure.yoga", .rose),
            ("Six glasses of water", "Big bottle, twice. Hydrated and smug.", "waterbottle.fill", .sky),
            ("Read 20 pages", "Plot twist. Can't stop now.", "book.fill", .gold),
            ("Walk outside", "Took the long way home.", "figure.walk", .orange),
            ("Journal", "Three lines, one good thing.", "pencil.line", .rose),
        ]
        let pick = samples.randomElement() ?? samples[0]
        context.insert(ActivityItem(kind: .checkIn, actorID: friend.id, title: pick.0, detail: pick.1, symbol: pick.2, tint: pick.3))
        friend.lastActive = Date()
        save()
    }

    // MARK: Friends

    func acceptFriend(_ friend: Friend) {
        friend.status = .friend
        friend.since = Date()
        resolveNotifications(refID: friend.id, resolution: "accepted")
        save()
        feedback(.send)
        showToast("You and \(friend.firstName) are now friends.", symbol: "person.2.fill", tint: .sage)
    }

    func declineFriend(_ friend: Friend) {
        friend.status = .suggested
        resolveNotifications(refID: friend.id, resolution: "declined")
        save()
        feedback(.selection)
    }

    /// Sends a request; mock friends accept a moment later.
    func requestFriend(_ friend: Friend) {
        friend.status = .requested
        save()
        feedback(.send)
        showToast("Request sent to \(friend.firstName).", symbol: "paperplane.fill", tint: .sky)
        let friendID = friend.id
        Task { [weak self] in
            try? await Task.sleep(for: .seconds(2.5))
            await MainActor.run {
                guard let self, let friend = self.friend(friendID), friend.status == .requested else { return }
                friend.status = .friend
                friend.since = Date()
                self.addNotification(.friendRequest, actorID: friend.id, title: "\(friend.firstName) accepted your request", body: "Say hi with a reaction.", refID: friend.id)
                if let note = (try? self.context.fetch(FetchDescriptor<NotificationItem>()))?.first(where: { $0.refID == friendID && $0.title.contains("accepted") }) {
                    note.resolution = "accepted"
                }
                self.save()
                self.feedback(.reactionReceived)
            }
        }
    }

    func removeFriend(_ friend: Friend) {
        friend.status = .suggested
        detachFriendFromHabits(friend.id)
        save()
        showToast("Removed \(friend.firstName).", symbol: "person.badge.minus", tint: .cream)
    }

    func block(_ friend: Friend) {
        friend.status = .blocked
        detachFriendFromHabits(friend.id)
        save()
        feedback(.warning)
        showToast("Blocked \(friend.firstName). They can't see your activity.", symbol: "hand.raised.fill", tint: .cream)
    }

    func unblock(_ friend: Friend) {
        friend.status = .suggested
        save()
        showToast("Unblocked \(friend.firstName).", symbol: "hand.raised.slash.fill", tint: .cream)
    }

    private func detachFriendFromHabits(_ id: UUID) {
        for habit in allHabits() where habit.participantIDs.contains(id) {
            habit.participantIDs.removeAll { $0 == id }
            if habit.participantIDs.isEmpty { habit.isShared = false }
        }
    }

    // MARK: Quizzes

    func vote(_ quiz: Quiz, for choiceID: UUID) {
        if let existing = quiz.myResponse { context.delete(existing) }
        let response = QuizResponse(voterID: nil, choiceID: choiceID)
        context.insert(response)
        quiz.responses.append(response)
        save()
        feedback(.send)
    }

    func createQuiz(prompt: String, tag: String) {
        let circle = friends()
        var options = Array(circle.shuffled().prefix(4).map(\.id))
        options.append(meID)
        let quiz = Quiz(prompt: prompt.cleaned(max: 90), tag: tag, optionIDs: options, createdByID: nil)
        context.insert(quiz)
        // A couple of friends answer right away so results aren't empty.
        for voter in circle.shuffled().prefix(3) {
            guard let choice = options.filter({ $0 != voter.id }).randomElement() else { continue }
            let response = QuizResponse(voterID: voter.id, choiceID: choice)
            context.insert(response)
            quiz.responses.append(response)
        }
        save()
        feedback(.send)
        showToast("Quiz sent to your circle.", symbol: "questionmark.bubble.fill", tint: .orange)
    }

    // MARK: In-app notifications

    func markRead(_ item: NotificationItem, _ read: Bool = true) {
        item.isRead = read
        save()
    }

    func markAllRead() {
        let items = (try? context.fetch(FetchDescriptor<NotificationItem>())) ?? []
        items.forEach { $0.isRead = true }
        save()
        feedback(.selection)
    }

    func dismiss(_ item: NotificationItem) {
        context.delete(item)
        save()
    }

    func resolveNotifications(refID: UUID, resolution: String) {
        let items = (try? context.fetch(FetchDescriptor<NotificationItem>())) ?? []
        for item in items where item.refID == refID && item.kind.isInvitation && item.resolution == nil {
            item.resolution = resolution
            item.isRead = true
        }
    }

    /// Accept or decline an invitation directly from the notification center.
    func respond(to item: NotificationItem, accept: Bool) {
        item.isRead = true
        switch item.kind {
        case .friendRequest:
            if let friend = friend(item.refID) {
                accept ? acceptFriend(friend) : declineFriend(friend)
            }
            item.resolution = accept ? "accepted" : "declined"
        case .groupInvite:
            if let group = group(item.refID) {
                accept ? join(group) : declineInvite(group)
            }
            item.resolution = accept ? "accepted" : "declined"
        case .habitInvite:
            item.resolution = accept ? "accepted" : "declined"
            if accept {
                let inviter = friend(item.actorID)
                var draft = HabitDraft(name: "Sunrise stretch", category: .mind, timeOfDay: .morning, frequency: .daily)
                draft.symbol = "figure.yoga"
                draft.tint = .gold
                if let inviter {
                    draft.isShared = true
                    draft.participantIDs = [inviter.id]
                }
                _ = createHabit(from: draft)
            }
        default:
            break
        }
        save()
    }
}
